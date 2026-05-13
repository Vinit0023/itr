import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'storage_service.dart';

// ── Data models ───────────────────────────────────────────────────

class EraseRegion {
  final double xPercent;
  final double yPercent;
  final double wPercent;
  final double hPercent;

  EraseRegion({
    required this.xPercent,
    required this.yPercent,
    required this.wPercent,
    required this.hPercent,
  });
}

class ErasePath {
  final List<Point<double>> points; // normalized 0..1
  final double brushSizePercent;

  ErasePath({
    required this.points,
    required this.brushSizePercent,
  });
}

// ── Processor ─────────────────────────────────────────────────────

class ImageProcessor {
  static final ImageProcessor _instance = ImageProcessor._internal();
  factory ImageProcessor() => _instance;
  ImageProcessor._internal();

  final _storageService = StorageService();

  /// Batch erase — same regions/paths applied to ALL images.
  /// Works on web (bytes) and mobile (file path via bytes).
  Future<List<ImageRef>> batchErase(
    List<ImageRef> images, {
    List<EraseRegion> regions = const [],
    List<ErasePath> paths = const [],
    Function(double)? onProgress,
  }) async {
    final List<ImageRef> results = [];

    for (int i = 0; i < images.length; i++) {
      onProgress?.call(i / images.length);

      try {
        // Read bytes from the ref
        final srcBytes = images[i].bytes ??
            await _storageService.readBytes(images[i]);

        if (srcBytes == null) {
          results.add(images[i]);
          continue;
        }

        // 1. Traditional Inpaint (Texture Fill) in Isolate
        final isolateResult = await compute(
          _processImageInIsolate,
          _ProcessParams(
            imageBytes: srcBytes,
            regions: regions,
            paths: paths,
          ),
        );

        Uint8List? processedBytes = isolateResult != null 
            ? Uint8List.fromList(isolateResult) 
            : null;

        // 2. LaMa API Integration (Optional Replacement/Fallback)
        // If regions exist, we can try high-quality API inpaint
        if (regions.isNotEmpty) {
          final lamaResult = await _lamaEraseWithApi(srcBytes, regions);
          if (lamaResult != null) {
            processedBytes = lamaResult;
          }
        }

        if (processedBytes != null) {
          final ref = await _storageService.createProcessedRef(images[i].name);
          await _storageService.writeBytes(ref, processedBytes);
          results.add(ref);
        } else {
          results.add(images[i]);
        }
      } catch (e) {
        debugPrint('ImageProcessor error: $e');
        results.add(images[i]);
      }
    }

    onProgress?.call(1.0);
    return results;
  }

  /// Implementation for LaMa API Inpainting
  Future<Uint8List?> _lamaEraseWithApi(Uint8List imageBytes, List<EraseRegion> regions) async {
    try {
      // 1. Get dimensions
      final srcImage = img.decodeImage(imageBytes);
      if (srcImage == null) return null;
      
      final w = srcImage.width;
      final h = srcImage.height;

      // 2. Generate mask image from regions
      final maskBytes = await _generateMask(w, h, regions);
      
      // TODO: 3. Call LaMa API (e.g., Replicate or custom endpoint)
      // For now, this is a placeholder as requested.
      // return await someApiCall(imageBytes, maskBytes);
      
      debugPrint('LaMa Mask generated: ${maskBytes.length} bytes for ${w}x${h} image');
      return null; 
    } catch (e) {
      debugPrint('LaMa API Error: $e');
      return null;
    }
  }

  Future<Uint8List> _generateMask(int width, int height, List<EraseRegion> regions) async {
    // Create black mask
    final maskImage = img.Image(width: width, height: height);
    img.fill(maskImage, color: img.ColorRgb8(0, 0, 0));

    for (final region in regions) {
      final x1 = (region.xPercent * width).round().clamp(0, width - 1);
      final y1 = (region.yPercent * height).round().clamp(0, height - 1);
      final x2 = ((region.xPercent + region.wPercent) * width).round().clamp(0, width - 1);
      final y2 = ((region.yPercent + region.hPercent) * height).round().clamp(0, height - 1);

      if (x2 > x1 && y2 > y1) {
        // Draw white rectangle for text region
        img.fillRect(
          maskImage,
          x1: x1,
          y1: y1,
          x2: x2,
          y2: y2,
          color: img.ColorRgb8(255, 255, 255),
        );
      }
    }
    // PNG is best for masks (lossless)
    return Uint8List.fromList(img.encodePng(maskImage));
  }

  void dispose() {}
}

// ── Isolate params ────────────────────────────────────────────────

class _ProcessParams {
  final Uint8List imageBytes;
  final List<EraseRegion> regions;
  final List<ErasePath> paths;

  _ProcessParams({
    required this.imageBytes,
    required this.regions,
    required this.paths,
  });
}

// ── Isolate function ──────────────────────────────────────────────

List<int>? _processImageInIsolate(_ProcessParams params) {
  try {
    final srcImage = img.decodeImage(params.imageBytes);
    if (srcImage == null) return null;

    final w = srcImage.width;
    final h = srcImage.height;

    // Rectangular regions (from Auto Search / ML Kit)
    for (final region in params.regions) {
      final x1 = (region.xPercent * w).round().clamp(0, w - 1);
      final y1 = (region.yPercent * h).round().clamp(0, h - 1);
      final x2 = ((region.xPercent + region.wPercent) * w).round().clamp(0, w - 1);
      final y2 = ((region.yPercent + region.hPercent) * h).round().clamp(0, h - 1);

      if (x2 > x1 && y2 > y1) {
        final expandX = ((x2 - x1) * 0.1).round();
        final expandY = ((y2 - y1) * 0.1).round();
        _textureFillInpaint(
          srcImage,
          (x1 - expandX).clamp(0, w - 1),
          (y1 - expandY).clamp(0, h - 1),
          (x2 + expandX).clamp(0, w - 1),
          (y2 + expandY).clamp(0, h - 1),
          null,
        );
      }
    }

    // Freehand paths (from draw screen)
    for (final path in params.paths) {
      if (path.points.isEmpty) continue;
      final brushSize = path.brushSizePercent;

      double minX = 1.0, minY = 1.0, maxX = 0.0, maxY = 0.0;
      for (final p in path.points) {
        minX = min(minX, p.x - brushSize);
        minY = min(minY, p.y - brushSize);
        maxX = max(maxX, p.x + brushSize);
        maxY = max(maxY, p.y + brushSize);
      }

      final x1 = (minX * w).round().clamp(0, w - 1);
      final y1 = (minY * h).round().clamp(0, h - 1);
      final x2 = (maxX * w).round().clamp(0, w - 1);
      final y2 = (maxY * h).round().clamp(0, h - 1);

      bool inMask(int px, int py) {
        final fx = px / w;
        final fy = py / h;
        for (int i = 0; i < path.points.length - 1; i++) {
          if (_distToSegment(
                Point(fx, fy),
                path.points[i],
                path.points[i + 1],
              ) <=
              brushSize) {
            return true;
          }
        }
        if (path.points.length == 1) {
          return _dist(Point(fx, fy), path.points.first) <= brushSize;
        }
        return false;
      }

      if (x2 > x1 && y2 > y1) {
        _textureFillInpaint(srcImage, x1, y1, x2, y2, inMask);
      }
    }

    return img.encodeJpg(srcImage, quality: 95);
  } catch (_) {
    return null;
  }
}

// ── Math helpers ──────────────────────────────────────────────────

double _dist(Point<double> a, Point<double> b) {
  final dx = a.x - b.x;
  final dy = a.y - b.y;
  return sqrt(dx * dx + dy * dy);
}

double _distToSegment(Point<double> p, Point<double> v, Point<double> w) {
  final l2 = _dist(v, w) * _dist(v, w);
  if (l2 == 0) return _dist(p, v);
  var t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2;
  t = t.clamp(0.0, 1.0);
  return _dist(p, Point(v.x + t * (w.x - v.x), v.y + t * (w.y - v.y)));
}

// ── Inpainting ────────────────────────────────────────────────────

void _textureFillInpaint(
  img.Image image,
  int x1,
  int y1,
  int x2,
  int y2,
  bool Function(int, int)? mask,
) {
  final regionW = x2 - x1;
  final regionH = y2 - y1;
  if (regionW <= 0 || regionH <= 0) return;

  final rng = Random(42);
  final sampleDepth = max(4, min(regionW, regionH) ~/ 4);

  // Horizontal blend buffers
  final bufR = List.generate(regionH, (_) => List.filled(regionW, 0));
  final bufG = List.generate(regionH, (_) => List.filled(regionW, 0));
  final bufB = List.generate(regionH, (_) => List.filled(regionW, 0));

  for (int y = y1; y < y2; y++) {
    final by = y - y1;
    final leftStrip = <_RGB>[];
    for (int i = 1; i <= sampleDepth; i++) {
      final sx = x1 - i;
      if (sx >= 0) {
        final p = image.getPixel(sx, y);
        leftStrip.add(_RGB(p.r.toInt(), p.g.toInt(), p.b.toInt()));
      }
    }
    final rightStrip = <_RGB>[];
    for (int i = 1; i <= sampleDepth; i++) {
      final sx = x2 + i;
      if (sx < image.width) {
        final p = image.getPixel(sx, y);
        rightStrip.add(_RGB(p.r.toInt(), p.g.toInt(), p.b.toInt()));
      }
    }
    for (int x = x1; x < x2; x++) {
      final bx = x - x1;
      final t = regionW > 1 ? bx / (regionW - 1) : 0.5;
      final lc = leftStrip.isNotEmpty
          ? leftStrip[bx % leftStrip.length]
          : _fromPixel(image.getPixel(x1.clamp(0, image.width - 1), y));
      final rc = rightStrip.isNotEmpty
          ? rightStrip[(regionW - 1 - bx) % rightStrip.length]
          : _fromPixel(image.getPixel(x2.clamp(0, image.width - 1), y));
      final st = t * t * (3 - 2 * t);
      bufR[by][bx] = (lc.r * (1 - st) + rc.r * st).round();
      bufG[by][bx] = (lc.g * (1 - st) + rc.g * st).round();
      bufB[by][bx] = (lc.b * (1 - st) + rc.b * st).round();
    }
  }

  // Vertical blend buffers
  final bufR2 = List.generate(regionH, (_) => List.filled(regionW, 0));
  final bufG2 = List.generate(regionH, (_) => List.filled(regionW, 0));
  final bufB2 = List.generate(regionH, (_) => List.filled(regionW, 0));

  for (int x = x1; x < x2; x++) {
    final bx = x - x1;
    final topStrip = <_RGB>[];
    for (int i = 1; i <= sampleDepth; i++) {
      final sy = y1 - i;
      if (sy >= 0) {
        final p = image.getPixel(x, sy);
        topStrip.add(_RGB(p.r.toInt(), p.g.toInt(), p.b.toInt()));
      }
    }
    final bottomStrip = <_RGB>[];
    for (int i = 1; i <= sampleDepth; i++) {
      final sy = y2 + i;
      if (sy < image.height) {
        final p = image.getPixel(x, sy);
        bottomStrip.add(_RGB(p.r.toInt(), p.g.toInt(), p.b.toInt()));
      }
    }
    for (int y = y1; y < y2; y++) {
      final by = y - y1;
      final t = regionH > 1 ? by / (regionH - 1) : 0.5;
      final tc = topStrip.isNotEmpty
          ? topStrip[by % topStrip.length]
          : _fromPixel(image.getPixel(x, y1.clamp(0, image.height - 1)));
      final bc = bottomStrip.isNotEmpty
          ? bottomStrip[(regionH - 1 - by) % bottomStrip.length]
          : _fromPixel(image.getPixel(x, y2.clamp(0, image.height - 1)));
      final st = t * t * (3 - 2 * t);
      bufR2[by][bx] = (tc.r * (1 - st) + bc.r * st).round();
      bufG2[by][bx] = (tc.g * (1 - st) + bc.g * st).round();
      bufB2[by][bx] = (tc.b * (1 - st) + bc.b * st).round();
    }
  }

  // Combine H + V
  final hw = regionH / (regionW + regionH);
  final vw = regionW / (regionW + regionH);
  for (int by = 0; by < regionH; by++) {
    for (int bx = 0; bx < regionW; bx++) {
      bufR[by][bx] = (bufR[by][bx] * hw + bufR2[by][bx] * vw).round();
      bufG[by][bx] = (bufG[by][bx] * hw + bufG2[by][bx] * vw).round();
      bufB[by][bx] = (bufB[by][bx] * hw + bufB2[by][bx] * vw).round();
    }
  }

  // Noise + blur
  for (int by = 0; by < regionH; by++) {
    for (int bx = 0; bx < regionW; bx++) {
      final noise = (rng.nextDouble() - 0.5) * 6;
      bufR[by][bx] = (bufR[by][bx] + noise).round().clamp(0, 255);
      bufG[by][bx] = (bufG[by][bx] + noise).round().clamp(0, 255);
      bufB[by][bx] = (bufB[by][bx] + noise).round().clamp(0, 255);
    }
  }
  for (int pass = 0; pass < 4; pass++) {
    _blurPass(bufR, regionW, regionH);
    _blurPass(bufG, regionW, regionH);
    _blurPass(bufB, regionW, regionH);
  }

  // Write back with feathered blending
  final feather = max(3, min(regionW, regionH) ~/ 6);
  for (int y = y1; y < y2; y++) {
    for (int x = x1; x < x2; x++) {
      if (mask != null && !mask(x, y)) continue;
      final by = y - y1;
      final bx = x - x1;
      final minDist = [
        (x - x1).toDouble(),
        (x2 - 1 - x).toDouble(),
        (y - y1).toDouble(),
        (y2 - 1 - y).toDouble(),
      ].reduce(min);
      var alpha = 1.0;
      if (minDist < feather) {
        alpha = minDist / feather;
        alpha = alpha * alpha * (3 - 2 * alpha);
      }
      final orig = image.getPixel(x, y);
      image.setPixel(
        x,
        y,
        img.ColorRgb8(
          (bufR[by][bx] * alpha + orig.r.toInt() * (1 - alpha)).round().clamp(0, 255),
          (bufG[by][bx] * alpha + orig.g.toInt() * (1 - alpha)).round().clamp(0, 255),
          (bufB[by][bx] * alpha + orig.b.toInt() * (1 - alpha)).round().clamp(0, 255),
        ),
      );
    }
  }
}

void _blurPass(List<List<int>> buf, int w, int h) {
  for (int y = 0; y < h; y++) {
    final tmp = List<int>.from(buf[y]);
    for (int x = 1; x < w - 1; x++) {
      buf[y][x] = (tmp[x - 1] + tmp[x] * 2 + tmp[x + 1]) ~/ 4;
    }
  }
  for (int x = 0; x < w; x++) {
    final tmp = List.generate(h, (y) => buf[y][x]);
    for (int y = 1; y < h - 1; y++) {
      buf[y][x] = (tmp[y - 1] + tmp[y] * 2 + tmp[y + 1]) ~/ 4;
    }
  }
}

class _RGB {
  final int r, g, b;
  _RGB(this.r, this.g, this.b);
}

_RGB _fromPixel(img.Pixel p) => _RGB(p.r.toInt(), p.g.toInt(), p.b.toInt());

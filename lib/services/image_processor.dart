import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'storage_service.dart';

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
  final List<Point<double>> points; // percentages
  final double brushSizePercent;

  ErasePath({
    required this.points,
    required this.brushSizePercent,
  });
}

class ImageProcessor {
  static final ImageProcessor _instance = ImageProcessor._internal();
  factory ImageProcessor() => _instance;
  ImageProcessor._internal();

  final _storageService = StorageService();

  /// Batch erase: apply the same marked regions/paths to ALL selected images
  Future<List<File>> batchErase(
    List<File> images, {
    List<EraseRegion> regions = const [],
    List<ErasePath> paths = const [],
    Function(double)? onProgress,
  }) async {
    List<File> results = [];
    
    for (int i = 0; i < images.length; i++) {
      if (onProgress != null) {
        onProgress(i / images.length);
      }

      try {
        final processed = await compute(_processImageInIsolate, _ProcessParams(
          imagePath: images[i].path,
          regions: regions,
          paths: paths,
        ));
        
        if (processed != null) {
          final outputFile = await _storageService.saveProcessedImage(images[i]);
          await outputFile.writeAsBytes(processed);
          results.add(outputFile);
        } else {
          results.add(images[i]);
        }
      } catch (e) {
        debugPrint("Error processing image: $e");
        results.add(images[i]);
      }
    }

    if (onProgress != null) {
      onProgress(1.0);
    }

    return results;
  }

  void dispose() {}
}

/// Parameters for isolate processing
class _ProcessParams {
  final String imagePath;
  final List<EraseRegion> regions;
  final List<ErasePath> paths;

  _ProcessParams({
    required this.imagePath,
    required this.regions,
    required this.paths,
  });
}

/// Run in isolate to avoid UI jank
List<int>? _processImageInIsolate(_ProcessParams params) {
  try {
    final bytes = File(params.imagePath).readAsBytesSync();
    final srcImage = img.decodeImage(bytes);
    if (srcImage == null) return null;

    final w = srcImage.width;
    final h = srcImage.height;

    // Process rectangular regions (from Auto Search)
    for (final region in params.regions) {
      final x1 = (region.xPercent * w).round().clamp(0, w - 1);
      final y1 = (region.yPercent * h).round().clamp(0, h - 1);
      final x2 = ((region.xPercent + region.wPercent) * w).round().clamp(0, w - 1);
      final y2 = ((region.yPercent + region.hPercent) * h).round().clamp(0, h - 1);

      if (x2 > x1 && y2 > y1) {
        // Expand the bounding box slightly for better context
        final expandX = ((x2 - x1) * 0.1).round();
        final expandY = ((y2 - y1) * 0.1).round();
        
        final ex1 = (x1 - expandX).clamp(0, w - 1);
        final ey1 = (y1 - expandY).clamp(0, h - 1);
        final ex2 = (x2 + expandX).clamp(0, w - 1);
        final ey2 = (y2 + expandY).clamp(0, h - 1);

        _textureFillInpaint(srcImage, ex1, ey1, ex2, ey2, null);
      }
    }

    // Process freehand paths
    if (params.paths.isNotEmpty) {
      for (final path in params.paths) {
        if (path.points.isEmpty) continue;
        
        // Find bounding box of the path
        double minX = 1.0, minY = 1.0, maxX = 0.0, maxY = 0.0;
        final brushSize = path.brushSizePercent;
        
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


        // Create a mask function
        bool inMask(int px, int py) {
          final fx = px / w;
          final fy = py / h;
          // Check distance to any line segment in the path
          for (int i = 0; i < path.points.length - 1; i++) {
            final p1 = path.points[i];
            final p2 = path.points[i + 1];
            if (_distanceToSegment(Point(fx, fy), p1, p2) <= brushSize) {
              return true;
            }
          }
          // Check single points
          if (path.points.length == 1) {
            final p1 = path.points.first;
            if (_distance(Point(fx, fy), p1) <= brushSize) return true;
          }
          return false;
        }

        if (x2 > x1 && y2 > y1) {
          _textureFillInpaint(srcImage, x1, y1, x2, y2, inMask);
        }
      }
    }

    return img.encodeJpg(srcImage, quality: 95);
  } catch (e) {
    return null;
  }
}

double _distance(Point<double> p1, Point<double> p2) {
  final dx = p1.x - p2.x;
  final dy = p1.y - p2.y;
  return sqrt(dx * dx + dy * dy);
}

double _distanceToSegment(Point<double> p, Point<double> v, Point<double> w) {
  final l2 = _distance(v, w) * _distance(v, w);
  if (l2 == 0) return _distance(p, v);
  var t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2;
  t = max(0.0, min(1.0, t));
  return _distance(p, Point(v.x + t * (w.x - v.x), v.y + t * (w.y - v.y)));
}

/// Texture-based inpainting with optional mask
void _textureFillInpaint(img.Image image, int x1, int y1, int x2, int y2, bool Function(int, int)? mask) {
  final regionW = x2 - x1;
  final regionH = y2 - y1;
  if (regionW <= 0 || regionH <= 0) return;

  final rng = Random(42);

  final sampleDepth = max(4, min(regionW, regionH) ~/ 4);

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

      _RGB leftColor;
      _RGB rightColor;

      if (leftStrip.isNotEmpty) {
        leftColor = leftStrip[bx % leftStrip.length];
      } else {
        final p = image.getPixel(x1.clamp(0, image.width - 1), y);
        leftColor = _RGB(p.r.toInt(), p.g.toInt(), p.b.toInt());
      }

      if (rightStrip.isNotEmpty) {
        final mirrorIdx = (regionW - 1 - bx) % rightStrip.length;
        rightColor = rightStrip[mirrorIdx];
      } else {
        final p = image.getPixel(x2.clamp(0, image.width - 1), y);
        rightColor = _RGB(p.r.toInt(), p.g.toInt(), p.b.toInt());
      }

      final st = t * t * (3 - 2 * t);
      bufR[by][bx] = (leftColor.r * (1 - st) + rightColor.r * st).round();
      bufG[by][bx] = (leftColor.g * (1 - st) + rightColor.g * st).round();
      bufB[by][bx] = (leftColor.b * (1 - st) + rightColor.b * st).round();
    }
  }

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

      _RGB topColor;
      _RGB bottomColor;

      if (topStrip.isNotEmpty) {
        topColor = topStrip[by % topStrip.length];
      } else {
        final p = image.getPixel(x, y1.clamp(0, image.height - 1));
        topColor = _RGB(p.r.toInt(), p.g.toInt(), p.b.toInt());
      }

      if (bottomStrip.isNotEmpty) {
        final mirrorIdx = (regionH - 1 - by) % bottomStrip.length;
        bottomColor = bottomStrip[mirrorIdx];
      } else {
        final p = image.getPixel(x, y2.clamp(0, image.height - 1));
        bottomColor = _RGB(p.r.toInt(), p.g.toInt(), p.b.toInt());
      }

      final st = t * t * (3 - 2 * t);
      bufR2[by][bx] = (topColor.r * (1 - st) + bottomColor.r * st).round();
      bufG2[by][bx] = (topColor.g * (1 - st) + bottomColor.g * st).round();
      bufB2[by][bx] = (topColor.b * (1 - st) + bottomColor.b * st).round();
    }
  }

  final hWeight = regionH / (regionW + regionH);
  final vWeight = regionW / (regionW + regionH);

  for (int by = 0; by < regionH; by++) {
    for (int bx = 0; bx < regionW; bx++) {
      bufR[by][bx] = (bufR[by][bx] * hWeight + bufR2[by][bx] * vWeight).round();
      bufG[by][bx] = (bufG[by][bx] * hWeight + bufG2[by][bx] * vWeight).round();
      bufB[by][bx] = (bufB[by][bx] * hWeight + bufB2[by][bx] * vWeight).round();
    }
  }

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

  final featherSize = max(3, min(regionW, regionH) ~/ 6);

  for (int y = y1; y < y2; y++) {
    for (int x = x1; x < x2; x++) {
      // If a mask is provided and this pixel is not in the mask, skip it entirely
      if (mask != null && !mask(x, y)) {
        continue;
      }

      final by = y - y1;
      final bx = x - x1;

      final distLeft = (x - x1).toDouble();
      final distRight = (x2 - 1 - x).toDouble();
      final distTop = (y - y1).toDouble();
      final distBottom = (y2 - 1 - y).toDouble();
      final minDist = [distLeft, distRight, distTop, distBottom].reduce(min);

      double alpha = 1.0;
      if (minDist < featherSize) {
        alpha = minDist / featherSize;
        alpha = alpha * alpha * (3 - 2 * alpha);
      }

      final original = image.getPixel(x, y);
      final finalR = (bufR[by][bx] * alpha + original.r.toInt() * (1 - alpha)).round().clamp(0, 255);
      final finalG = (bufG[by][bx] * alpha + original.g.toInt() * (1 - alpha)).round().clamp(0, 255);
      final finalB = (bufB[by][bx] * alpha + original.b.toInt() * (1 - alpha)).round().clamp(0, 255);

      image.setPixel(x, y, img.ColorRgb8(finalR, finalG, finalB));
    }
  }
}

void _blurPass(List<List<int>> buf, int w, int h) {
  for (int y = 0; y < h; y++) {
    final temp = List<int>.from(buf[y]);
    for (int x = 1; x < w - 1; x++) {
      buf[y][x] = (temp[x - 1] + temp[x] * 2 + temp[x + 1]) ~/ 4;
    }
  }
  for (int x = 0; x < w; x++) {
    final temp = List.generate(h, (y) => buf[y][x]);
    for (int y = 1; y < h - 1; y++) {
      buf[y][x] = (temp[y - 1] + temp[y] * 2 + temp[y + 1]) ~/ 4;
    }
  }
}

class _RGB {
  final int r, g, b;
  _RGB(this.r, this.g, this.b);
}

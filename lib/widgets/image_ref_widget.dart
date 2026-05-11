import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
// Conditional import for platform-specific image loading
import 'platform_image_loader.dart'
    if (dart.library.io) 'platform_image_loader_mobile.dart'
    if (dart.library.html) 'platform_image_loader_web.dart';

/// Shows an image from an [ImageRef].
/// - On web: uses memory bytes (loads if missing)
/// - On mobile: uses File path via platform-safe loader
class ImageRefWidget extends StatefulWidget {
  final ImageRef ref;
  final BoxFit fit;
  final int? cacheWidth;
  final Widget? placeholder;

  const ImageRefWidget({
    super.key,
    required this.ref,
    this.fit = BoxFit.cover,
    this.cacheWidth,
    this.placeholder,
  });

  @override
  State<ImageRefWidget> createState() => _ImageRefWidgetState();
}

class _ImageRefWidgetState extends State<ImageRefWidget> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ImageRefWidget old) {
    super.didUpdateWidget(old);
    if (old.ref.id != widget.ref.id) _load();
  }

  Future<void> _load() async {
    // If bytes are already in the ref, use them
    if (widget.ref.bytes != null) {
      _bytes = widget.ref.bytes;
      if (mounted) setState(() => _loading = false);
      return;
    }

    // On Web, we MUST load bytes into memory
    if (kIsWeb) {
      setState(() => _loading = true);
      _bytes = await StorageService().readBytes(widget.ref);
      if (mounted) setState(() => _loading = false);
    } else {
      // On Mobile, we'll use Image.file via path, so just stop loading
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return widget.placeholder ??
          const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
    }

    // Web or mobile with in-memory bytes
    if (_bytes != null) {
      return Image.memory(
        _bytes!,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        errorBuilder: (_, __, ___) => _errorWidget(),
      );
    }

    // Mobile — use file path via platform-safe loader
    if (!kIsWeb && widget.ref.path != null) {
      return platformFileImage(
        widget.ref.path!,
        fit: widget.fit,
        cacheWidth: widget.cacheWidth,
        errorBuilder: _errorWidget,
      );
    }

    return _errorWidget();
  }

  Widget _errorWidget() => Container(
        color: Colors.grey[900],
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
}

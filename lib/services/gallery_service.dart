import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

/// Unified image model — works on web and mobile.
/// On mobile: [path] is set.
/// On web:    [bytes] and [name] are set.
class PickedImage {
  final String? path;
  final Uint8List? bytes;
  final String name;

  const PickedImage({this.path, this.bytes, required this.name});

  bool get isValid => kIsWeb ? bytes != null : path != null;
}

class GalleryService {
  static final GalleryService _instance = GalleryService._internal();
  factory GalleryService() => _instance;
  GalleryService._internal();

  Future<List<PickedImage>> pickImages() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: kIsWeb, // web needs in-memory bytes
      );
      if (result == null) return [];

      return result.files
          .where((f) => kIsWeb ? f.bytes != null : f.path != null)
          .map((f) => PickedImage(
                path: f.path,
                bytes: f.bytes,
                name: f.name,
              ))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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
        // FIX: withData always true — web ko bytes chahiye,
        // mobile pe bhi bytes load karo taaki batchErase crash na ho
        withData: true,
      );

      if (result == null || result.files.isEmpty) return [];

      final images = <PickedImage>[];
      for (final f in result.files) {
        // Web: bytes must exist
        if (kIsWeb) {
          if (f.bytes != null && f.bytes!.isNotEmpty) {
            images.add(PickedImage(bytes: f.bytes, name: f.name));
          } else {
            debugPrint('GalleryService: skipping ${f.name} — no bytes on web');
          }
        } else {
          // Mobile: path must exist; bytes are bonus (withData:true se milenge)
          if (f.path != null) {
            images.add(
              PickedImage(
                path: f.path,
                bytes: f.bytes, // may be null on some mobile builds — ok
                name: f.name,
              ),
            );
          } else {
            debugPrint(
              'GalleryService: skipping ${f.name} — no path on mobile',
            );
          }
        }
      }
      return images;
    } catch (e) {
      debugPrint('GalleryService.pickImages error: $e');
      return [];
    }
  }
}

import 'dart:io';
import 'package:file_picker/file_picker.dart';

class GalleryService {
  static final GalleryService _instance = GalleryService._internal();
  factory GalleryService() => _instance;
  GalleryService._internal();

  /// Pick multiple images using the file picker
  Future<List<File>> pickImages() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
      );

      if (result != null) {
        return result.paths.where((path) => path != null).map((path) => File(path!)).toList();
      }
    } catch (e) {
      // Handle error
    }
    return [];
  }
}

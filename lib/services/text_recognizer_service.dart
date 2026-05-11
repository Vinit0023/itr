import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'text_recognizer_mobile.dart'
    if (dart.library.html) 'text_recognizer_web.dart' as platform;

class TextRecognizerService {
  static final TextRecognizerService _instance = TextRecognizerService._internal();
  factory TextRecognizerService() => _instance;
  TextRecognizerService._internal();

  /// Returns bounding boxes as percentage coords for [searchText] found in image.
  /// On mobile: uses Google ML Kit (accurate).
  /// On web: returns empty (ML Kit not available — user draws mask manually).
  Future<List<Map<String, double>>> findTextRegions(
    dynamic imageSource, // ImageRef on new code
    Uint8List imageBytes,
    String searchText,
    int imgWidth,
    int imgHeight,
  ) async {
    if (kIsWeb) {
      // ML Kit not available on web — user will draw manually
      return [];
    }
    return platform.findTextRegions(
      imageSource,
      imageBytes,
      searchText,
      imgWidth,
      imgHeight,
    );
  }

  void dispose() {
    if (!kIsWeb) platform.dispose();
  }
}

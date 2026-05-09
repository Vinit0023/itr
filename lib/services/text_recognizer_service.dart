import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class TextRecognizerService {
  static final TextRecognizerService _instance = TextRecognizerService._internal();
  factory TextRecognizerService() => _instance;
  TextRecognizerService._internal();

  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Scans the image for the specified text and returns a list of bounding boxes
  /// represented as percentage coordinates (xPercent, yPercent, wPercent, hPercent).
  Future<List<Map<String, double>>> findTextRegions(File imageFile, String searchText) async {
    if (searchText.trim().isEmpty) return [];

    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      // We need image dimensions to calculate percentages
      // ML Kit doesn't provide image size directly from File, so we decode header
      final decodedImage = await decodeImageFromList(await imageFile.readAsBytes());
      final imgWidth = decodedImage.width.toDouble();
      final imgHeight = decodedImage.height.toDouble();
      
      List<Map<String, double>> foundRegions = [];
      final searchLower = searchText.trim().toLowerCase();

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          // Check if the line contains our search text
          if (line.text.toLowerCase().contains(searchLower)) {
            // Alternatively, we could check individual words for more precise bounding boxes
            for (TextElement element in line.elements) {
              if (element.text.toLowerCase().contains(searchLower) || searchLower.contains(element.text.toLowerCase())) {
                final rect = element.boundingBox;
                foundRegions.add({
                  'xPercent': rect.left / imgWidth,
                  'yPercent': rect.top / imgHeight,
                  'wPercent': rect.width / imgWidth,
                  'hPercent': rect.height / imgHeight,
                });
              }
            }
          }
        }
      }

      return foundRegions;
    } catch (e) {
      debugPrint("Error in TextRecognizerService: $e");
      return [];
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}

// Mobile implementation using Google ML Kit
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import '../models/ocr_models.dart';

final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

/// Find text regions matching search text
/// Returns percentage-based coordinates
Future<List<Map<String, double>>> findTextRegions(
  dynamic imageSource,
  Uint8List imageBytes,
  String searchText,
  int imgWidth,
  int imgHeight,
) async {
  if (searchText.trim().isEmpty) return [];

  try {
    InputImage inputImage;
    
    // Crash Protection: Ensure we always have a valid file path for ML Kit
    if (imageSource is String && imageSource.isNotEmpty && File(imageSource).existsSync()) {
      inputImage = InputImage.fromFilePath(imageSource);
    } else if (imageBytes.isNotEmpty) {
      // JPG/PNG bytes cannot be passed directly to InputImage.fromBytes (which expects raw buffers)
      // We must write them to a temp file first.
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/temp_ocr_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(imageBytes);
      inputImage = InputImage.fromFilePath(tempFile.path);
    } else {
      debugPrint('TextRecognizer: No image source available');
      return [];
    }

    final recognized = await _recognizer.processImage(inputImage);
    final searchLower = searchText.trim().toLowerCase();
    final List<Map<String, double>> found = [];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        if (line.text.toLowerCase().contains(searchLower)) {
          for (final element in line.elements) {
            if (element.text.toLowerCase().contains(searchLower) ||
                searchLower.contains(element.text.toLowerCase())) {
              final rect = element.boundingBox;
              found.add({
                'xPercent': (rect.left / imgWidth).clamp(0, 1),
                'yPercent': (rect.top / imgHeight).clamp(0, 1),
                'wPercent': (rect.width / imgWidth).clamp(0, 1),
                'hPercent': (rect.height / imgHeight).clamp(0, 1),
              });
            }
          }
        }
      }
    }
    return found;
  } catch (e) {
    debugPrint('TextRecognizer Crash Prevented: $e');
    return [];
  }
}

/// Advanced OCR with better text detection and masking
/// Returns TextBoxPercent objects for better masking
Future<OCRResult> recognizeTextAdvanced(
  dynamic imageSource,
  int imgWidth,
  int imgHeight,
) async {
  try {
    InputImage inputImage;
    
    if (imageSource is String && imageSource.isNotEmpty && File(imageSource).existsSync()) {
      inputImage = InputImage.fromFilePath(imageSource);
    } else {
      return OCRResult(
        imageId: 'unknown',
        textBoxes: [],
        imageWidth: imgWidth,
        imageHeight: imgHeight,
      );
    }

    final recognized = await _recognizer.processImage(inputImage);
    final List<TextBox> textBoxes = [];

    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        for (final element in line.elements) {
          final rect = element.boundingBox;
          
          // Calculate confidence (0-1)
          // ML Kit doesn't give direct confidence, so we estimate from text length
          final textLength = element.text.length;
          final estimatedConfidence = (textLength > 0 ? 0.8 : 0.5).clamp(0, 1).toDouble();

          textBoxes.add(TextBox(
            left: rect.left.toDouble(),
            top: rect.top.toDouble(),
            right: (rect.left + rect.width).toDouble(),
            bottom: (rect.top + rect.height).toDouble(),
            text: element.text,
            confidence: estimatedConfidence,
          ));
        }
      }
    }

    return OCRResult(
      imageId: imageSource.toString(),
      textBoxes: textBoxes,
      imageWidth: imgWidth,
      imageHeight: imgHeight,
    );
  } catch (e) {
    debugPrint('Advanced OCR Error: $e');
    return OCRResult(
      imageId: imageSource.toString(),
      textBoxes: [],
      imageWidth: imgWidth,
      imageHeight: imgHeight,
    );
  }
}

/// Find text boxes with padding applied for better masking
Future<List<TextBoxPercent>> findTextBoxesWithPadding(
  dynamic imageSource,
  String searchText,
  int imgWidth,
  int imgHeight, {
  double paddingPercent = 2.0,
  double minConfidence = 0.5,
}) async {
  try {
    final result = await recognizeTextAdvanced(imageSource, imgWidth, imgHeight);
    final matches = result.findMatches(searchText, minConfidence: minConfidence);
    
    return matches
        .map((box) => box.toPercent(imgWidth, imgHeight).withPadding(paddingPercent))
        .toList();
  } catch (e) {
    debugPrint('Error finding text boxes: $e');
    return [];
  }
}

void dispose() {
  _recognizer.close();
}

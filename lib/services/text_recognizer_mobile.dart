// Mobile implementation using Google ML Kit
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

Future<List<Map<String, double>>> findTextRegions(
  dynamic imageSource,
  Uint8List imageBytes,
  String searchText,
  int imgWidth,
  int imgHeight,
) async {
  if (searchText.trim().isEmpty) return [];

  try {
    final InputImage inputImage;
    
    // Crash Protection: Check if path is valid
    if (imageSource is String && imageSource.isNotEmpty && File(imageSource).existsSync()) {
      inputImage = InputImage.fromFilePath(imageSource);
    } else {
      // Fallback: Agar path nahi hai toh bytes se process karne ki koshish karein
      // Mobile par ML Kit File/Path ko zyada behtar handle karta hai
      debugPrint('TextRecognizer: Invalid path or source');
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
    return found;
  } catch (e) {
    debugPrint('TextRecognizer Crash Prevented: $e');
    return [];
  }
}

void dispose() {
  _recognizer.close();
}
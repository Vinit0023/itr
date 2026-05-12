import 'dart:ui' as ui;

/// Represents a bounding box for text detection
class TextBox {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final String text;
  final double confidence;

  TextBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.text,
    required this.confidence,
  });

  /// Get width of bounding box
  double get width => right - left;

  /// Get height of bounding box
  double get height => bottom - top;

  /// Apply padding to bounding box (in pixels)
  TextBox withPadding(double paddingPercent) {
    final padW = width * paddingPercent;
    final padH = height * paddingPercent;

    return TextBox(
      left: (left - padW).clamp(0, double.infinity),
      top: (top - padH).clamp(0, double.infinity),
      right: right + padW,
      bottom: bottom + padH,
      text: text,
      confidence: confidence,
    );
  }

  /// Convert to percentage-based coordinates (0-100)
  TextBoxPercent toPercent(int imageWidth, int imageHeight) {
    return TextBoxPercent(
      xPercent: (left / imageWidth * 100).clamp(0, 100),
      yPercent: (top / imageHeight * 100).clamp(0, 100),
      wPercent: (width / imageWidth * 100).clamp(0, 100),
      hPercent: (height / imageHeight * 100).clamp(0, 100),
      text: text,
      confidence: confidence,
    );
  }

  /// Get Rect for drawing
  ui.Rect toRect() => ui.Rect.fromLTRB(left, top, right, bottom);

  @override
  String toString() =>
      'TextBox([$left,$top] ${width}x$height, text="$text", conf=$confidence)';
}

/// Percentage-based bounding box (0-100 scale)
class TextBoxPercent {
  final double xPercent;
  final double yPercent;
  final double wPercent;
  final double hPercent;
  final String text;
  final double confidence;

  TextBoxPercent({
    required this.xPercent,
    required this.yPercent,
    required this.wPercent,
    required this.hPercent,
    required this.text,
    required this.confidence,
  });

  /// Apply padding (percentage of box size)
  TextBoxPercent withPadding(double paddingPercent) {
    return TextBoxPercent(
      xPercent: (xPercent - paddingPercent).clamp(0, 100),
      yPercent: (yPercent - paddingPercent).clamp(0, 100),
      wPercent: (wPercent + paddingPercent * 2).clamp(0, 100),
      hPercent: (hPercent + paddingPercent * 2).clamp(0, 100),
      text: text,
      confidence: confidence,
    );
  }

  /// Convert to pixel-based coordinates
  TextBox toPixels(int imageWidth, int imageHeight) {
    return TextBox(
      left: (xPercent / 100 * imageWidth),
      top: (yPercent / 100 * imageHeight),
      right: ((xPercent + wPercent) / 100 * imageWidth),
      bottom: ((yPercent + hPercent) / 100 * imageHeight),
      text: text,
      confidence: confidence,
    );
  }

  @override
  String toString() =>
      'TextBoxPercent([$xPercent,$yPercent] ${wPercent}x$hPercent, text="$text", conf=$confidence)';
}

/// OCR Detection result with multiple text boxes
class OCRResult {
  final String imageId;
  final List<TextBox> textBoxes;
  final int imageWidth;
  final int imageHeight;

  OCRResult({
    required this.imageId,
    required this.textBoxes,
    required this.imageWidth,
    required this.imageHeight,
  });

  /// Find text boxes matching search text (case-insensitive, partial match)
  List<TextBox> findMatches(
    String searchText, {
    double minConfidence = 0.5,
  }) {
    final query = searchText.toLowerCase();
    return textBoxes
        .where((box) =>
            box.text.toLowerCase().contains(query) &&
            box.confidence >= minConfidence)
        .toList();
  }

  /// Get all unique texts detected
  List<String> get uniqueTexts => textBoxes.map((b) => b.text).toSet().toList();

  @override
  String toString() =>
      'OCRResult(imageId=$imageId, boxes=${textBoxes.length}, ${imageWidth}x$imageHeight)';
}

/// Mask region for inpainting/erasing
class MaskRegion {
  final double xPercent;
  final double yPercent;
  final double wPercent;
  final double hPercent;
  final String? label; // e.g., "text", "logo", "watermark"
  final double strength; // 0.0 - 1.0, how aggressive the erase should be

  MaskRegion({
    required this.xPercent,
    required this.yPercent,
    required this.wPercent,
    required this.hPercent,
    this.label,
    this.strength = 1.0,
  });

  /// Create from TextBox
  factory MaskRegion.fromTextBox(
    TextBoxPercent textBox, {
    double paddingPercent = 2.0,
    double strength = 1.0,
  }) {
    final padded = textBox.withPadding(paddingPercent);
    return MaskRegion(
      xPercent: padded.xPercent,
      yPercent: padded.yPercent,
      wPercent: padded.wPercent,
      hPercent: padded.hPercent,
      label: 'text:${textBox.text}',
      strength: strength,
    );
  }

  @override
  String toString() =>
      'MaskRegion([$xPercent,$yPercent] ${wPercent}x$hPercent, label=$label, strength=$strength)';
}

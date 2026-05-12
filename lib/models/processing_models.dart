import 'dart:typed_data';

/// Information about a single image processing operation
class ImageProcessingInfo {
  final String imageId;
  final String imageName;
  final int imageWidth;
  final int imageHeight;
  final Uint8List? originalBytes;
  final String status; // "pending", "processing", "completed", "failed"
  final String? errorMessage;
  final double progress; // 0.0 - 1.0

  ImageProcessingInfo({
    required this.imageId,
    required this.imageName,
    required this.imageWidth,
    required this.imageHeight,
    this.originalBytes,
    this.status = "pending",
    this.errorMessage,
    this.progress = 0.0,
  });

  /// Create a copy with updated fields
  ImageProcessingInfo copyWith({
    String? status,
    double? progress,
    String? errorMessage,
    Uint8List? originalBytes,
  }) {
    return ImageProcessingInfo(
      imageId: imageId,
      imageName: imageName,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      originalBytes: originalBytes ?? this.originalBytes,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      progress: progress ?? this.progress,
    );
  }

  bool get isCompleted => status == "completed";
  bool get isFailed => status == "failed";
  bool get isProcessing => status == "processing";

  @override
  String toString() =>
      'ImageProcessingInfo(id=$imageId, name=$imageName, status=$status, progress=$progress)';
}

/// Batch processing configuration
class BatchProcessConfig {
  final String searchText;
  final double minConfidence; // 0.5 default
  final double paddingPercent; // padding around detected text
  final bool useInpainting; // Use Lama or simple fill
  final int maxConcurrentImages; // How many to process at once

  BatchProcessConfig({
    required this.searchText,
    this.minConfidence = 0.5,
    this.paddingPercent = 2.0,
    this.useInpainting = true,
    this.maxConcurrentImages = 1, // Sequential by default
  });

  @override
  String toString() =>
      'BatchProcessConfig(text="$searchText", minConf=$minConfidence, padding=$paddingPercent)';
}

/// Result of processing a single image
class ImageProcessResult {
  final String imageId;
  final String imageName;
  final bool success;
  final Uint8List? processedBytes;
  final int textInstancesFound;
  final String? errorMessage;
  final DateTime timestamp;

  ImageProcessResult({
    required this.imageId,
    required this.imageName,
    required this.success,
    this.processedBytes,
    this.textInstancesFound = 0,
    this.errorMessage,
  }) : timestamp = DateTime.now();

  @override
  String toString() =>
      'ImageProcessResult(id=$imageId, success=$success, instances=$textInstancesFound)';
}

/// Batch processing progress
class BatchProcessProgress {
  final int totalImages;
  final int processedImages;
  final int failedImages;
  final DateTime startTime;
  final List<ImageProcessingInfo> imageInfos;

  BatchProcessProgress({
    required this.totalImages,
    required this.processedImages,
    required this.failedImages,
    required this.startTime,
    required this.imageInfos,
  });

  double get progressPercent => processedImages / totalImages;
  int get remainingImages => totalImages - processedImages - failedImages;
  Duration get elapsedTime => DateTime.now().difference(startTime);
  Duration? get estimatedRemaining {
    if (processedImages == 0) return null;
    final rate = elapsedTime.inMilliseconds / processedImages;
    return Duration(milliseconds: (rate * remainingImages).toInt());
  }

  @override
  String toString() =>
      'BatchProgress($processedImages/$totalImages, failed=$failedImages, progress=${(progressPercent * 100).toInt()}%)';
}

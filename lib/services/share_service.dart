import 'package:flutter/foundation.dart' show kIsWeb;

// Mobile-only import guard
import 'share_service_mobile.dart'
    if (dart.library.html) 'share_service_web.dart' as platform;

import 'storage_service.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  Function(List<ImageRef>)? onImagesReceived;

  void init() {
    if (!kIsWeb) {
      platform.init((refs) => onImagesReceived?.call(refs));
    }
    // On web: nothing to do — user picks via file picker instead
  }

  void dispose() {
    if (!kIsWeb) platform.dispose();
  }
}

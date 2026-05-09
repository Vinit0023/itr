import 'dart:async';
import 'dart:io';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'storage_service.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  final _storageService = StorageService();
  StreamSubscription? _intentDataStreamSubscription;

  // Callback to notify the UI when new images are processed
  Function(List<File>)? onImagesReceived;

  void init() {
    // For sharing images while the app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) async {
      if (value.isNotEmpty) {
        await _handleSharedMedia(value);
      }
    }, onError: (err) {
      // debugPrint("getIntentDataStream error: $err");
    });

    // For sharing images while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) async {
      if (value.isNotEmpty) {
        await _handleSharedMedia(value);
      }
      // Reset so it doesn't trigger again on rebuild
      ReceiveSharingIntent.instance.reset();
    });
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> media) async {
    List<File> savedFiles = [];
    for (var element in media) {
      if (element.path.isNotEmpty) {
        final file = File(element.path);
        if (await file.exists()) {
          final savedFile = await _storageService.saveReceivedImage(file);
          savedFiles.add(savedFile);
        }
      }
    }
    if (savedFiles.isNotEmpty && onImagesReceived != null) {
      onImagesReceived!(savedFiles);
    }
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}

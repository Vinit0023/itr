// Mobile-only share service implementation
import 'dart:io';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';
import 'storage_service.dart';

StreamSubscription? _sub;

void init(Function(List<ImageRef>) onReceived) {
  _sub = ReceiveSharingIntent.instance
      .getMediaStream()
      .listen((List<SharedMediaFile> value) async {
    if (value.isNotEmpty) {
      final refs = await _handle(value);
      if (refs.isNotEmpty) onReceived(refs);
    }
  });

  ReceiveSharingIntent.instance
      .getInitialMedia()
      .then((List<SharedMediaFile> value) async {
    if (value.isNotEmpty) {
      final refs = await _handle(value);
      if (refs.isNotEmpty) onReceived(refs);
    }
    ReceiveSharingIntent.instance.reset();
  });
}

Future<List<ImageRef>> _handle(List<SharedMediaFile> media) async {
  final storage = StorageService();
  final List<ImageRef> result = [];
  for (final item in media) {
    if (item.path.isEmpty) continue;
    final file = File(item.path);
    if (!await file.exists()) continue;
    final bytes = await file.readAsBytes();
    final ref = await storage.createProcessedRef(item.path.split('/').last);
    await storage.writeBytes(ref, bytes);
    result.add(ref);
  }
  return result;
}

void dispose() {
  _sub?.cancel();
}

// Web implementation — only compiled on web platform
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'storage_service.dart';

Future<String> getProcessedPath(String id) async => id; // not used on web

Future<void> writeFile(String path, Uint8List bytes) async {} // not used on web

Future<Uint8List?> readFile(String path) async => null; // not used on web

Future<void> deleteFile(String path) async {} // not used on web

Future<bool> saveToGallery(List<ImageRef> refs) async => false; // not used on web

/// Triggers a browser download for the given bytes.
void triggerDownload(Uint8List bytes, String fileName) {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/jpeg'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  anchor.click();
  web.URL.revokeObjectURL(url);
}

// Mobile implementation — only compiled on non-web platforms
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'storage_service.dart';

Future<String> getProcessedPath(String id) async {
  final dir = await getApplicationDocumentsDirectory();
  final processedDir = Directory(p.join(dir.path, 'ITR', 'processed'));
  if (!await processedDir.exists()) {
    await processedDir.create(recursive: true);
  }
  return p.join(processedDir.path, 'processed_$id.jpg');
}

Future<void> writeFile(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes);
}

Future<Uint8List?> readFile(String path) async {
  final file = File(path);
  if (await file.exists()) return file.readAsBytes();
  return null;
}

Future<void> deleteFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

Future<bool> saveToGallery(List<ImageRef> refs) async {
  try {
    for (final ref in refs) {
      if (ref.path != null && await File(ref.path!).exists()) {
        await ImageGallerySaverPlus.saveFile(ref.path!);
      }
    }
    return true;
  } catch (_) {
    return false;
  }
}

// Not used on mobile
void triggerDownload(Uint8List bytes, String name) {}

import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _uuid = const Uuid();

  Future<Directory> get _appDir async {
    final dir = await getApplicationDocumentsDirectory();
    final itrDir = Directory(p.join(dir.path, 'ITR'));
    if (!await itrDir.exists()) {
      await itrDir.create(recursive: true);
    }
    return itrDir;
  }

  Future<Directory> get _receivedDir async {
    final dir = await _appDir;
    final received = Directory(p.join(dir.path, 'received'));
    if (!await received.exists()) {
      await received.create(recursive: true);
    }
    return received;
  }

  Future<Directory> get _processedDir async {
    final dir = await _appDir;
    final processed = Directory(p.join(dir.path, 'processed'));
    if (!await processed.exists()) {
      await processed.create(recursive: true);
    }
    return processed;
  }

  Future<File> saveReceivedImage(File sourceFile) async {
    final receivedDir = await _receivedDir;
    final extension = p.extension(sourceFile.path);
    final fileName = '${_uuid.v4()}$extension';
    final targetPath = p.join(receivedDir.path, fileName);
    return await sourceFile.copy(targetPath);
  }

  /// Creates a new empty file in the processed directory and returns it.
  /// The caller is responsible for writing bytes to this file.
  Future<File> saveProcessedImage(File sourceFile) async {
    final processedDir = await _processedDir;
    final fileName = 'processed_${_uuid.v4()}.jpg';
    final targetPath = p.join(processedDir.path, fileName);
    return File(targetPath);
  }

  Future<List<File>> getReceivedImages() async {
    final dir = await _receivedDir;
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final ext = p.extension(f.path).toLowerCase();
          return ['.jpg', '.jpeg', '.png', '.webp', '.bmp'].contains(ext);
        })
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }

  Future<List<File>> getProcessedImages() async {
    final dir = await _processedDir;
    if (!await dir.exists()) return [];
    return dir
        .listSync()
        .whereType<File>()
        .where((f) {
          final ext = p.extension(f.path).toLowerCase();
          return ['.jpg', '.jpeg', '.png', '.webp', '.bmp'].contains(ext);
        })
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }

  Future<void> saveToAlbum(String albumName, List<File> images) async {
    final dir = await _appDir;
    final albumDir = Directory(p.join(dir.path, 'albums', albumName));
    if (!await albumDir.exists()) {
      await albumDir.create(recursive: true);
    }
    for (var img in images) {
      final fileName = p.basename(img.path);
      await img.copy(p.join(albumDir.path, fileName));
    }
  }

  Future<List<String>> getAlbums() async {
    final dir = await _appDir;
    final albumsDir = Directory(p.join(dir.path, 'albums'));
    if (!await albumsDir.exists()) return [];
    
    return albumsDir.listSync()
        .whereType<Directory>()
        .map((e) => p.basename(e.path))
        .toList();
  }

  /// Get all images inside a specific album
  Future<List<File>> getAlbumImages(String albumName) async {
    final dir = await _appDir;
    final albumDir = Directory(p.join(dir.path, 'albums', albumName));
    if (!await albumDir.exists()) return [];
    
    return albumDir
        .listSync()
        .whereType<File>()
        .where((f) {
          final ext = p.extension(f.path).toLowerCase();
          return ['.jpg', '.jpeg', '.png', '.webp', '.bmp'].contains(ext);
        })
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
  }

  /// Delete a single processed image
  Future<void> deleteProcessedImage(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clear all processed images
  Future<void> clearAllProcessed() async {
    final dir = await _processedDir;
    final files = dir.listSync().whereType<File>();
    for (var file in files) {
      await file.delete();
    }
  }

  /// Delete an album
  Future<void> deleteAlbum(String albumName) async {
    final dir = await _appDir;
    final albumDir = Directory(p.join(dir.path, 'albums', albumName));
    if (await albumDir.exists()) {
      await albumDir.delete(recursive: true);
    }
  }
}

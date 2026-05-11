import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// Mobile-only imports — guarded
import 'storage_service_mobile.dart'
    if (dart.library.html) 'storage_service_web.dart' as platform;

/// A unified image reference — on web we store bytes in memory,
/// on mobile we hold the file path.
class ImageRef {
  final String id;
  final String? path;       // mobile
  final Uint8List? bytes;   // web
  final String name;
  final DateTime createdAt;

  ImageRef({
    required this.id,
    this.path,
    this.bytes,
    required this.name,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ImageRef.fromJson(Map<String, dynamic> j) => ImageRef(
        id: j['id'],
        path: j['path'],
        name: j['name'],
        createdAt: DateTime.parse(j['createdAt']),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ImageRef && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  final _uuid = const Uuid();

  // ── In-memory store (web primary, mobile fallback for current session) ──
  final Map<String, Uint8List> _memoryStore = {};

  // ── Processed images list ─────────────────────────────────────
  final List<ImageRef> _processedRefs = [];
  // ── Albums ────────────────────────────────────────────────────
  final Map<String, List<ImageRef>> _albums = {};

  // ── Persist metadata (paths/ids) using shared_preferences ─────
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ─────────────────────────────────────────────────────────────
  // Create new processed image slot
  // ─────────────────────────────────────────────────────────────
  Future<ImageRef> createProcessedRef(String sourceName) async {
    final id = _uuid.v4();
    if (kIsWeb) {
      return ImageRef(id: id, name: 'processed_$id.jpg');
    } else {
      final path = await platform.getProcessedPath(id);
      return ImageRef(id: id, path: path, name: 'processed_$id.jpg');
    }
  }

  /// Write bytes to the ref (both web and mobile).
  Future<void> writeBytes(ImageRef ref, Uint8List bytes) async {
    if (kIsWeb) {
      _memoryStore[ref.id] = bytes;
    } else {
      await platform.writeFile(ref.path!, bytes);
    }
  }

  /// Read bytes from the ref.
  Future<Uint8List?> readBytes(ImageRef ref) async {
    if (kIsWeb) {
      return _memoryStore[ref.id];
    } else {
      return platform.readFile(ref.path!);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Processed images
  // ─────────────────────────────────────────────────────────────
  void addProcessed(ImageRef ref) {
    _processedRefs.insert(0, ref);
  }

  List<ImageRef> getProcessedImages() => List.unmodifiable(_processedRefs);

  void deleteProcessed(ImageRef ref) {
    _processedRefs.remove(ref);
    _memoryStore.remove(ref.id);
    if (!kIsWeb && ref.path != null) platform.deleteFile(ref.path!);
  }

  void clearAllProcessed() {
    for (final ref in _processedRefs) {
      _memoryStore.remove(ref.id);
      if (!kIsWeb && ref.path != null) platform.deleteFile(ref.path!);
    }
    _processedRefs.clear();
  }

  // ─────────────────────────────────────────────────────────────
  // Albums
  // ─────────────────────────────────────────────────────────────
  List<String> getAlbums() => _albums.keys.toList();

  Future<void> saveToAlbum(String albumName, List<ImageRef> images) async {
    _albums.putIfAbsent(albumName, () => []).addAll(images);
    // Persist album names
    final prefs = await _prefs;
    await prefs.setString('albums', jsonEncode(_albums.keys.toList()));
  }

  List<ImageRef> getAlbumImages(String albumName) =>
      _albums[albumName] ?? [];

  Future<void> deleteAlbum(String albumName) async {
    _albums.remove(albumName);
    final prefs = await _prefs;
    await prefs.setString('albums', jsonEncode(_albums.keys.toList()));
  }

  // ─────────────────────────────────────────────────────────────
  // Save to device gallery (mobile only)
  // ─────────────────────────────────────────────────────────────
  Future<bool> saveToGallery(List<ImageRef> refs) async {
    if (kIsWeb) {
      // Web: trigger browser download for each image
      for (final ref in refs) {
        final bytes = _memoryStore[ref.id];
        if (bytes != null) {
          platform.triggerDownload(bytes, ref.name);
        }
      }
      return true;
    } else {
      return platform.saveToGallery(refs);
    }
  }
}

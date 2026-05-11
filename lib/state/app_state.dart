import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb, ChangeNotifier, debugPrint;
import '../services/storage_service.dart';
import '../services/share_service.dart';
import '../services/image_processor.dart';
import '../services/gallery_service.dart';
import '../services/text_recognizer_service.dart';

class AppState extends ChangeNotifier {
  final _storage        = StorageService();
  final _shareService   = ShareService();
  final _imageProcessor = ImageProcessor();
  final _galleryService = GalleryService();
  final _textRecognizer = TextRecognizerService();

  final List<ImageRef> _receivedImages  = [];
  List<ImageRef> _processedImages = [];
  List<ImageRef> _selectedImages  = [];
  List<String>   _albums          = [];

  bool   _isLoading       = false;
  double _processProgress = 0.0;

  List<ImageRef> get receivedImages  => _receivedImages;
  List<ImageRef> get processedImages => _processedImages;
  List<ImageRef> get selectedImages  => _selectedImages;
  List<String>   get albums          => _albums;
  bool           get isLoading       => _isLoading;
  double         get processProgress => _processProgress;

  AppState() { _init(); }

  Future<void> _init() async {
    _shareService.onImagesReceived = (refs) {
      _receivedImages.insertAll(0, refs);
      notifyListeners();
    };
    _shareService.init();
    _processedImages = _storage.getProcessedImages();
    _albums = _storage.getAlbums();
    notifyListeners();
  }

  void toggleImageSelection(ImageRef ref) {
    if (_selectedImages.contains(ref)) {
      _selectedImages.remove(ref);
    } else {
      _selectedImages.add(ref);
    }
    notifyListeners();
  }

  // Alias for toggleImageSelection
  void toggleSelection(ImageRef ref) => toggleImageSelection(ref);

  void selectAllRecent() {
    _selectedImages = List.from(_receivedImages);
    notifyListeners();
  }

  void clearSelection() {
    _selectedImages.clear();
    notifyListeners();
  }

  Future<void> pickImages() async {
    final picked = await _galleryService.pickImages();
    if (picked.isEmpty) return;

    for (final p in picked) {
      final ref = await _storage.createProcessedRef(p.name);
      if (p.bytes != null) {
        await _storage.writeBytes(ref, p.bytes!);
        // Chrome fix: bytes ko direct ref mein update karein
        _selectedImages.add(ImageRef(
          id: ref.id,
          name: ref.name,
          path: ref.path,
          bytes: p.bytes,
        ));
      }
    }
    notifyListeners();
  }

  // Alias for pickImages
  Future<void> pickFromGallery() => pickImages();

  // --- FIX FOR TEST CASE 2 & ERASE DISPLAY ---
  Future<List<ImageRef>> batchErase(String searchText) async {
    if (_selectedImages.isEmpty || searchText.trim().isEmpty) return [];

    _isLoading = true;
    _processProgress = 0.0;
    notifyListeners();

    try {
      final List<ImageRef> finalResults = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        final ref = _selectedImages[i];
        if (ref.bytes == null) continue;

        final ui.Image decoded = await ui.instantiateImageCodec(ref.bytes!)
            .then((c) => c.getNextFrame().then((f) => f.image));

        final regions = await _textRecognizer.findTextRegions(
          kIsWeb ? ref : ref.path,
          ref.bytes!,
          searchText,
          decoded.width,
          decoded.height,
        );

        if (regions.isNotEmpty) {
          final processed = await _imageProcessor.batchErase(
            [ref],
            regions: regions.map((r) => EraseRegion(
              xPercent: r['xPercent']!,
              yPercent: r['yPercent']!,
              wPercent: r['wPercent']!,
              hPercent: r['hPercent']!,
            )).toList(),
          );
          finalResults.addAll(processed);
        } else {
          finalResults.add(ref);
        }

        _processProgress = (i + 1) / _selectedImages.length;
        notifyListeners();
      }

      // Important: Save to storage and update UI list
      for (var res in finalResults) { _storage.addProcessed(res); }
      _processedImages = finalResults; 
      _selectedImages = List.from(finalResults);
      
      return finalResults;
    } catch (e) {
      debugPrint("Batch Erase Error: $e");
      return _selectedImages;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Alias for batchErase
  Future<List<ImageRef>> autoSearchAndErase(String searchText) => batchErase(searchText);

  Future<void> saveToAlbum(String albumName) async {
    if (_selectedImages.isEmpty) return;
    await _storage.saveToAlbum(albumName, _selectedImages);
    _albums = _storage.getAlbums();
    notifyListeners();
  }

  List<ImageRef> getAlbumImages(String albumName) => _storage.getAlbumImages(albumName);

  Future<void> deleteAlbum(String albumName) async {
    await _storage.deleteAlbum(albumName);
    _albums = _storage.getAlbums();
    notifyListeners();
  }

  Future<bool> saveAllToGallery() async {
    if (_selectedImages.isEmpty) return false;
    return _storage.saveToGallery(_selectedImages);
  }

  void deleteProcessedImage(ImageRef ref) {
    _storage.deleteProcessed(ref);
    _processedImages = _storage.getProcessedImages();
    notifyListeners();
  }

  Future<void> clearAllProcessed() async {
    _storage.clearAllProcessed();
    _processedImages = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _shareService.dispose();
    _imageProcessor.dispose();
    _textRecognizer.dispose();
    super.dispose();
  }
}
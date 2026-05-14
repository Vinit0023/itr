import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart'
    show kIsWeb, ChangeNotifier, debugPrint;
import '../services/storage_service.dart';
import '../services/share_service.dart';
import '../services/image_processor.dart';
import '../services/gallery_service.dart';
import '../services/text_recognizer_service.dart';

class AppState extends ChangeNotifier {
  final _storage = StorageService();
  final _shareService = ShareService();
  final _imageProcessor = ImageProcessor();
  final _galleryService = GalleryService();
  final _textRecognizer = TextRecognizerService();

  final List<ImageRef> _receivedImages = [];
  List<ImageRef> _processedImages = [];
  List<ImageRef> _selectedImages = [];
  List<String> _albums = [];

  bool _isLoading = false;
  double _processProgress = 0.0;
  int _currentProcessingImageIndex = 0;

  List<ImageRef> get receivedImages => _receivedImages;
  List<ImageRef> get processedImages => _processedImages;
  List<ImageRef> get selectedImages => _selectedImages;
  List<String> get albums => _albums;
  bool get isLoading => _isLoading;
  double get processProgress => _processProgress;
  int get currentProcessingImageIndex => _currentProcessingImageIndex;
  int get totalProcessingImages => _selectedImages.length;

  AppState() {
    _init();
  }

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

  void toggleSelection(ImageRef ref) => toggleImageSelection(ref);

  void selectAllRecent() {
    _selectedImages = List.from(_receivedImages);
    notifyListeners();
  }

  void clearSelection() {
    _selectedImages.clear();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUG FIX 1 (Chrome — images grid nahi dikhti after picking):
  //
  // Pehle: picked images sirf _selectedImages mein add hoti thi.
  //   SelectImagesScreen ka grid sirf _receivedImages se render hota hai.
  //   Isliye Chrome pe gallery pick ke baad kuch nahi dikhta tha.
  //
  // Fix: dono lists mein add karo — grid mein dikhega + pre-selected bhi hoga.
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> pickImages() async {
    final picked = await _galleryService.pickImages();
    if (picked.isEmpty) return;

    for (final p in picked) {
      final ref = await _storage.createProcessedRef(p.name);

      final imageRef = ImageRef(
        id: ref.id,
        name: ref.name,
        path: ref.path,
        bytes: p.bytes,
      );

      if (p.bytes != null) {
        await _storage.writeBytes(ref, p.bytes!);
      }

      // FIX: _receivedImages mein bhi add karo — yahi grid mein dikhta hai
      _receivedImages.insert(0, imageRef);
      // Pre-select bhi karo taaki user ko dobara tap na karna pade
      _selectedImages.add(imageRef);
    }
    notifyListeners();
  }

  Future<void> pickFromGallery() => pickImages();

  // ─────────────────────────────────────────────────────────────────────────
  // DELETE IMAGE - Preview se image remove karne ke liye
  // ─────────────────────────────────────────────────────────────────────────
  void removeImage(ImageRef ref) {
    _selectedImages.removeWhere((img) => img.id == ref.id);
    _processedImages.removeWhere((img) => img.id == ref.id);
    _storage.deleteProcessed(ref);
    notifyListeners();
  }

  void removeImageAt(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      final ref = _selectedImages[index];
      removeImage(ref);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ADD MORE IMAGES - Preview se baad mein images add karne ke liye
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> addMoreImages() async {
    await pickImages();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUG FIX 2 (Phone — Auto Erase pe app crash):
  //
  // Pehle: mobile pe ImageRef.bytes == null hota hai (sirf path hota hai).
  //   Code ref.bytes! use karta tha — null assertion crash deta tha.
  //
  // Fix: pehle bytes load karo path se agar memory mein nahi hain.
  // ─────────────────────────────────────────────────────────────────────────
  /// Unified Automated Erase Loop
  /// 1. Detect Text (Google ML Kit)
  /// 2. Construct Mask (Dynamic UI Canvas logic in ImageProcessor)
  /// 3. Inpaint (Hugging Face or Local Texture Fill)
  Future<List<ImageRef>> batchErase(String searchText) async {
    if (_selectedImages.isEmpty || searchText.trim().isEmpty) return [];

    _isLoading = true;
    _processProgress = 0.0;
    _currentProcessingImageIndex = 0;
    notifyListeners();

    try {
      final List<ImageRef> finalResults = [];

      for (int i = 0; i < _selectedImages.length; i++) {
        _currentProcessingImageIndex = i + 1;
        final ref = _selectedImages[i];

        // 1. Load Bytes
        Uint8List? imageBytes = ref.bytes ?? await _storage.readBytes(ref);
        if (imageBytes == null) {
          finalResults.add(ref);
          continue;
        }

        // 2. Safe decoding for dimensions
        final ui.Codec codec = await ui.instantiateImageCodec(imageBytes);
        final ui.FrameInfo fi = await codec.getNextFrame();
        final ui.Image decoded = fi.image;

        // 3. Detect Regions (ML Kit - FREE)
        final regions = await _textRecognizer.findTextRegions(
          kIsWeb ? ref : ref.path,
          imageBytes,
          searchText,
          decoded.width,
          decoded.height,
        );

        if (regions.isNotEmpty) {
          // 4. Automated Process (HF API or Local)
          final refWithBytes = ImageRef(
            id: ref.id,
            name: ref.name,
            path: ref.path,
            bytes: imageBytes,
            createdAt: ref.createdAt,
          );
          
          final processed = await _imageProcessor.batchErase(
            [refWithBytes],
            width: decoded.width,
            height: decoded.height,
            regions: regions.map((r) => EraseRegion(
              xPercent: r['xPercent'] ?? 0.0,
              yPercent: r['yPercent'] ?? 0.0,
              wPercent: r['wPercent'] ?? 0.0,
              hPercent: r['hPercent'] ?? 0.0,
            )).toList(),
          );
          finalResults.addAll(processed);
        } else {
          finalResults.add(ref);
        }

        _processProgress = (i + 1) / _selectedImages.length;
        notifyListeners();
      }

      // Finalize
      for (var res in finalResults) {
        _storage.addProcessed(res);
      }
      _processedImages = finalResults;
      _selectedImages = List.from(finalResults);

      return finalResults;
    } catch (e) {
      debugPrint("Automated Erase Error: $e");
      return _selectedImages;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<ImageRef>> autoSearchAndErase(String searchText) =>
      batchErase(searchText);

  Future<void> saveToAlbum(String albumName) async {
    if (_selectedImages.isEmpty) return;
    await _storage.saveToAlbum(albumName, _selectedImages);
    _albums = _storage.getAlbums();
    notifyListeners();
  }

  List<ImageRef> getAlbumImages(String albumName) =>
      _storage.getAlbumImages(albumName);

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

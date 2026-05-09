import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../services/storage_service.dart';
import '../services/share_service.dart';
import '../services/image_processor.dart';
import '../services/gallery_service.dart';
import '../services/text_recognizer_service.dart';

class AppState extends ChangeNotifier {
  final _storageService = StorageService();
  final _shareService = ShareService();
  final _imageProcessor = ImageProcessor();
  final _galleryService = GalleryService();
  final _textRecognizer = TextRecognizerService();

  List<File> _receivedImages = [];
  List<File> _processedImages = [];
  List<File> _selectedImages = [];
  List<String> _albums = [];
  
  bool _isLoading = false;
  double _processProgress = 0.0;

  List<File> get receivedImages => _receivedImages;
  List<File> get processedImages => _processedImages;
  List<File> get selectedImages => _selectedImages;
  List<String> get albums => _albums;
  
  bool get isLoading => _isLoading;
  double get processProgress => _processProgress;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    _shareService.init();
    _shareService.onImagesReceived = (files) {
      _receivedImages.insertAll(0, files);
      notifyListeners();
    };
    await loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    _receivedImages = await _storageService.getReceivedImages();
    _processedImages = await _storageService.getProcessedImages();
    _albums = await _storageService.getAlbums();
    _isLoading = false;
    notifyListeners();
  }

  void toggleSelection(File image) {
    if (_selectedImages.contains(image)) {
      _selectedImages.remove(image);
    } else {
      _selectedImages.add(image);
    }
    notifyListeners();
  }
  
  void clearSelection() {
    _selectedImages.clear();
    notifyListeners();
  }
  
  void selectAllRecent() {
    _selectedImages = List.from(_receivedImages);
    notifyListeners();
  }

  Future<void> pickFromGallery() async {
    final images = await _galleryService.pickImages();
    if (images.isNotEmpty) {
      _selectedImages.addAll(images);
      notifyListeners();
    }
  }

  Future<List<File>> batchProcess({List<EraseRegion> regions = const [], List<ErasePath> paths = const []}) async {
    if (_selectedImages.isEmpty || (regions.isEmpty && paths.isEmpty)) return [];
    
    _isLoading = true;
    _processProgress = 0.0;
    notifyListeners();
    
    final results = await _imageProcessor.batchErase(
      _selectedImages,
      regions: regions,
      paths: paths,
      onProgress: (progress) {
        _processProgress = progress;
        notifyListeners();
      }
    );
    
    _processedImages.insertAll(0, results);
    _selectedImages = List.from(results);
    
    _isLoading = false;
    _processProgress = 1.0;
    notifyListeners();
    
    return results;
  }

  /// Automatically find and erase specific text from all selected images
  Future<List<File>> autoSearchAndErase(String searchText) async {
    if (_selectedImages.isEmpty || searchText.trim().isEmpty) return [];

    _isLoading = true;
    _processProgress = 0.0;
    notifyListeners();

    List<File> finalResults = [];
    
    for (int i = 0; i < _selectedImages.length; i++) {
      final imgFile = _selectedImages[i];
      
      // Step 1: Find text regions using ML Kit
      final foundBoxes = await _textRecognizer.findTextRegions(imgFile, searchText);
      
      if (foundBoxes.isNotEmpty) {
        // Convert to EraseRegion
        final regions = foundBoxes.map((b) => EraseRegion(
          xPercent: b['xPercent']!,
          yPercent: b['yPercent']!,
          wPercent: b['wPercent']!,
          hPercent: b['hPercent']!,
        )).toList();

        // Step 2: Erase just for this image
        final result = await _imageProcessor.batchErase([imgFile], regions: regions);
        finalResults.addAll(result);
      } else {
        // Text not found, return original image
        finalResults.add(imgFile);
      }

      _processProgress = (i + 1) / _selectedImages.length;
      notifyListeners();
    }

    _processedImages.insertAll(0, finalResults);
    _selectedImages = List.from(finalResults);
    
    _isLoading = false;
    _processProgress = 1.0;
    notifyListeners();

    return finalResults;
  }


  
  Future<void> saveToAlbum(String albumName) async {
    if (_selectedImages.isEmpty) return;
    await _storageService.saveToAlbum(albumName, _selectedImages);
    _albums = await _storageService.getAlbums();
    notifyListeners();
  }

  Future<bool> saveAllToGallery() async {
    if (_selectedImages.isEmpty) return false;

    try {
      for (final file in _selectedImages) {
        if (await file.exists()) {
          await ImageGallerySaverPlus.saveFile(file.path);
        }
      }
      return true;
    } catch (e) {
      debugPrint("Error saving to gallery: $e");
      return false;
    }
  }

  Future<List<File>> getAlbumImages(String albumName) async {
    return await _storageService.getAlbumImages(albumName);
  }

  Future<void> deleteProcessedImage(File file) async {
    await _storageService.deleteProcessedImage(file);
    _processedImages.remove(file);
    notifyListeners();
  }

  Future<void> clearAllProcessed() async {
    await _storageService.clearAllProcessed();
    _processedImages.clear();
    notifyListeners();
  }

  Future<void> deleteAlbum(String albumName) async {
    await _storageService.deleteAlbum(albumName);
    _albums.remove(albumName);
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

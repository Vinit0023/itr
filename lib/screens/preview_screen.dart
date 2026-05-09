import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isSaving = false;

  void _showAlbumDialog() {
    final TextEditingController albumController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: const Text('Save to Album'),
          content: Consumer<AppState>(
            builder: (context, state, child) {
              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: albumController,
                      decoration: const InputDecoration(
                        hintText: 'New Album Name',
                        hintStyle: TextStyle(color: Colors.white54),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    if (state.albums.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Or select existing:', style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: state.albums.map((album) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ActionChip(
                              label: Text(album),
                              onPressed: () {
                                albumController.text = album;
                              },
                              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                              side: BorderSide.none,
                            ),
                          )).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (albumController.text.trim().isNotEmpty) {
                  await Provider.of<AppState>(context, listen: false).saveToAlbum(albumController.text.trim());
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Saved to album "${albumController.text.trim()}"')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Save Album'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSaveAll() async {
    if (_isSaving) return;
    
    setState(() => _isSaving = true);
    
    final state = Provider.of<AppState>(context, listen: false);
    final success = await state.saveAllToGallery();
    
    if (mounted) {
      setState(() => _isSaving = false);
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.greenAccent, size: 20),
                SizedBox(width: 8),
                Text('All images saved to gallery!'),
              ],
            ),
          ),
        );
        // Go back to home after saving
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                SizedBox(width: 8),
                Text('Failed to save some images'),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Results'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.selectedImages.isEmpty) {
            return const Center(child: Text("No images to preview"));
          }

          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: state.selectedImages.length,
                  itemBuilder: (context, index) {
                    final file = state.selectedImages[index];
                    return Container(
                      margin: const EdgeInsets.all(24),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: InteractiveViewer(
                          child: Image.file(
                            file,
                            fit: BoxFit.contain,
                            key: ValueKey('preview_${file.path}_${file.lastModifiedSync().millisecondsSinceEpoch}'),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Page indicator
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${_currentIndex + 1} / ${state.selectedImages.length}',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
              
              // Dots Indicator
              if (state.selectedImages.length > 1 && state.selectedImages.length <= 10)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    state.selectedImages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentIndex == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentIndex == index ? Theme.of(context).colorScheme.primary : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Action Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
                              )
                            : const Icon(Icons.save_alt),
                        label: Text(_isSaving ? 'Saving...' : 'Save to Gallery'),
                        onPressed: _isSaving ? null : _handleSaveAll,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.photo_album),
                        label: const Text('Create Album'),
                        onPressed: _showAlbumDialog,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}

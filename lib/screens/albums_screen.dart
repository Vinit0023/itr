import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/app_theme.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Albums'),
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.albums.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_album_outlined,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No albums yet',
                    style: TextStyle(color: Colors.white54, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Process images and save them\nto albums to see them here',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white30, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: state.albums.length,
            itemBuilder: (context, index) {
              final albumName = state.albums[index];
              return GestureDetector(
                onTap: () => _openAlbum(context, albumName, state),
                onLongPress: () => _confirmDeleteAlbum(context, albumName, state),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.photo_album_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(
                      albumName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: const Text(
                      'Tap to view • Long press to delete',
                      style: TextStyle(color: Colors.white30, fontSize: 11),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white54,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) {
            Navigator.pop(context);
          } else if (index == 1) {
            Navigator.pushNamed(context, '/select');
          }
        },
      ),
    );
  }

  void _openAlbum(BuildContext context, String albumName, AppState state) async {
    final images = await state.getAlbumImages(albumName);
    
    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AlbumDetailScreen(
          albumName: albumName,
          images: images,
        ),
      ),
    );
  }

  void _confirmDeleteAlbum(BuildContext context, String albumName, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Album?', style: TextStyle(color: Colors.white)),
        content: Text(
          'Are you sure you want to delete "$albumName"? The images inside will be permanently removed.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await state.deleteAlbum(albumName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('"$albumName" deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

/// Screen that shows all images inside an album
class _AlbumDetailScreen extends StatelessWidget {
  final String albumName;
  final List<File> images;

  const _AlbumDetailScreen({
    required this.albumName,
    required this.images,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(albumName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: images.isEmpty
          ? const Center(
              child: Text(
                'No images in this album',
                style: TextStyle(color: Colors.white54, fontSize: 16),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final file = images[index];
                return GestureDetector(
                  onTap: () => _viewImage(context, file),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      file,
                      fit: BoxFit.cover,
                      key: ValueKey('album_${file.path}_${file.lastModifiedSync().millisecondsSinceEpoch}'),
                      cacheWidth: 200,
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _viewImage(BuildContext context, File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(
                file,
                fit: BoxFit.contain,
                key: ValueKey('view_${file.path}'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

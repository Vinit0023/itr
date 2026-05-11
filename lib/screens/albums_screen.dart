import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/storage_service.dart';
import '../widgets/image_ref_widget.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/app_theme.dart';

class AlbumsScreen extends StatelessWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      extendBody: true,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              SliverAppBar(
                pinned: true,
                backgroundColor: AppTheme.bgDeep,
                automaticallyImplyLeading: false,
                title: Text('Albums', style: Theme.of(context).textTheme.titleLarge),
              ),
              if (state.albums.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Icon(
                            Icons.photo_album_outlined,
                            size: 52,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No albums yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Process images and save them\nto albums to see them here',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final albumName = state.albums[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _AlbumTile(
                            albumName: albumName,
                            onTap: () => _openAlbum(context, albumName, state),
                            onDelete: () => _confirmDelete(context, albumName, state),
                          ),
                        );
                      },
                      childCount: state.albums.length,
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 2,
        onTap: (index) {
          if (index == 0) Navigator.pop(context);
          if (index == 1) Navigator.pushNamed(context, '/select');
        },
      ),
    );
  }

  void _openAlbum(BuildContext context, String albumName, AppState state) {
    final images = state.getAlbumImages(albumName);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AlbumDetailScreen(albumName: albumName, images: images),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String albumName, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "$albumName"?'),
        content: const Text('All images inside this album will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
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

class _AlbumTile extends StatelessWidget {
  final String albumName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _AlbumTile({
    required this.albumName,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.photo_album_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(albumName, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to view • Long press to delete',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}

class _AlbumDetailScreen extends StatelessWidget {
  final String albumName;
  final List<ImageRef> images;

  const _AlbumDetailScreen({required this.albumName, required this.images});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      appBar: AppBar(
        title: Text(albumName),
        backgroundColor: AppTheme.bgDeep,
      ),
      body: images.isEmpty
          ? Center(
              child: Text(
                'No images in this album',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final ref = images[index];
                return GestureDetector(
                  onTap: () => _viewImageRef(context, ref),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ImageRefWidget(
                      ref: ref,
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _viewImageRef(BuildContext context, ImageRef ref) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              child: ImageRefWidget(ref: ref, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }
}


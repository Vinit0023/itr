import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/storage_service.dart';
import '../widgets/image_ref_widget.dart';
import '../theme/app_theme.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key});

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isSaving = false;
  bool _isGridView = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAll(AppState state) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final success = await state.saveAllToGallery();

    if (mounted) {
      setState(() => _isSaving = false);
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error_outline,
                color: success ? Colors.greenAccent : Colors.redAccent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(success ? 'Saved to gallery!' : 'Failed to save some images'),
            ],
          ),
        ),
      );
      if (success) {
        navigator.popUntil((r) => r.isFirst);
      }
    }
  }

  void _showAlbumDialog(AppState state) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Save to Album', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Album name (e.g. Products, June Sale)',
                prefixIcon: Icon(Icons.photo_album_outlined, color: AppTheme.textMuted),
              ),
            ),
            if (state.albums.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Existing albums', style: Theme.of(ctx).textTheme.bodyLarge),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: state.albums
                    .map((a) => ActionChip(
                          label: Text(a),
                          onPressed: () => ctrl.text = a,
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (ctrl.text.trim().isEmpty) return;
                  final albumName = ctrl.text.trim();
                  final scaffoldMsg = ScaffoldMessenger.of(context);
                  await state.saveToAlbum(albumName);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    scaffoldMsg.showSnackBar(
                      SnackBar(content: Text('Saved to "$albumName"')),
                    );
                  }
                },
                child: const Text('Save to Album'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          if (state.selectedImages.isEmpty) {
            return const Center(child: Text('No images to preview'));
          }

          return Column(
            children: [
              // ── App Bar ──────────────────────────────────────
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: const Icon(Icons.home_outlined, size: 18),
                        ),
                        onPressed: () =>
                            Navigator.of(context).popUntil((r) => r.isFirst),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Results',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      // Toggle grid / single view
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isGridView
                                ? AppTheme.crimson.withValues(alpha: 0.2)
                                : AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isGridView ? AppTheme.crimson : AppTheme.cardBorder,
                            ),
                          ),
                          child: Icon(
                            _isGridView ? Icons.view_carousel_outlined : Icons.grid_view_rounded,
                            size: 18,
                            color: _isGridView ? AppTheme.roseGlow : AppTheme.textSecondary,
                          ),
                        ),
                        onPressed: () => setState(() => _isGridView = !_isGridView),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Image View ────────────────────────────────────
              Expanded(
                child: _isGridView
                    ? _GridView(
                        images: state.selectedImages,
                        onTap: (i) => setState(() {
                          _isGridView = false;
                          _currentIndex = i;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _pageController.jumpToPage(i);
                          });
                        }),
                      )
                    : Column(
                        children: [
                          Expanded(
                            child: PageView.builder(
                              controller: _pageController,
                              onPageChanged: (i) => setState(() => _currentIndex = i),
                              itemCount: state.selectedImages.length,
                              itemBuilder: (context, index) {
                                final ref = state.selectedImages[index];
                                return Container(
                                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: InteractiveViewer(
                                      child: ImageRefWidget(
                                        ref: ref,
                                        fit: BoxFit.contain,
                                        key: ValueKey('prev_${ref.id}'),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Page indicator dots
                          if (state.selectedImages.length > 1)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  state.selectedImages.length > 10
                                      ? 10
                                      : state.selectedImages.length,
                                  (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: _currentIndex == i ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: _currentIndex == i
                                          ? AppTheme.crimson
                                          : AppTheme.cardBorder,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            const SizedBox(height: 12),
                          Text(
                            '${_currentIndex + 1} of ${state.selectedImages.length}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
              ),

              // ── Action Bar ────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  border: Border(top: BorderSide(color: AppTheme.cardBorder)),
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.photo_album_outlined, size: 18),
                          label: const Text('Save to Album'),
                          onPressed: () => _showAlbumDialog(state),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save_alt, size: 18),
                          label: Text(_isSaving ? 'Saving...' : 'Save to Gallery'),
                          onPressed: _isSaving ? null : () => _handleSaveAll(state),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _GridView extends StatelessWidget {
  final List<ImageRef> images;
  final void Function(int) onTap;

  const _GridView({required this.images, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.9,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        final ref = images[index];
        return GestureDetector(
          onTap: () => onTap(index),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ImageRefWidget(
                    ref: ref,
                    fit: BoxFit.cover,
                    key: ValueKey('grid_${ref.id}'),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: AppTheme.overlayGradient,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'Image ${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


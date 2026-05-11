import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/storage_service.dart';
import '../widgets/image_ref_widget.dart';
import '../theme/app_theme.dart';

class SelectImagesScreen extends StatelessWidget {
  const SelectImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  slivers: [
                    // ── App Bar ───────────────────────────────────────
                    SliverToBoxAdapter(
                      child: SafeArea(
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
                                    border: Border.all(
                                      color: AppTheme.cardBorder,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new,
                                    size: 16,
                                  ),
                                ),
                                onPressed: () {
                                  state.clearSelection();
                                  Navigator.pop(context);
                                },
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  state.receivedImages.isEmpty
                                      ? 'Select Images'
                                      : '${state.selectedImages.length} / ${state.receivedImages.length} selected',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              if (state.receivedImages.isNotEmpty)
                                TextButton(
                                  onPressed: () => state.selectAllRecent(),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.roseGlow,
                                  ),
                                  child: const Text('Select All'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Pick Source Buttons ───────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Row(
                          children: [
                            Expanded(
                              child: _SourceCard(
                                icon: Icons.photo_library_rounded,
                                label: 'Gallery',
                                sublabel: 'Pick from gallery',
                                onTap: () => state.pickFromGallery(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SourceCard(
                                icon: Icons.folder_open_rounded,
                                label: 'Files',
                                sublabel: 'Browse folders',
                                onTap: () => state.pickFromGallery(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Section Label (sirf jab images hain) ─────────
                    if (state.receivedImages.isNotEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                          child: Row(
                            children: [
                              Text(
                                kIsWeb ? 'Picked Images' : 'Shared with App',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.crimson.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${state.receivedImages.length}',
                                  style: TextStyle(
                                    color: AppTheme.roseGlow,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Empty State OR Image Grid ─────────────────────
                    if (state.receivedImages.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          onPick: () => state.pickFromGallery(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 10,
                                mainAxisSpacing: 10,
                              ),
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final image = state.receivedImages[index];
                            final isSelected = state.selectedImages.contains(
                              image,
                            );
                            return _ImageTile(
                              file: image,
                              isSelected: isSelected,
                              onTap: () => state.toggleSelection(image),
                            );
                          }, childCount: state.receivedImages.length),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Bottom Panel: counter + add more + continue ────────
              if (state.receivedImages.isNotEmpty)
                _BottomPanel(
                  selectedCount: state.selectedImages.length,
                  onAddMore: () => state.pickFromGallery(),
                  onContinue: state.selectedImages.isEmpty
                      ? null
                      : () => Navigator.pushNamed(context, '/preview-select'),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State — direct pick button
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final VoidCallback onPick;
  const _EmptyState({required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppTheme.cardBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 52,
                color: AppTheme.roseGlow,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No images selected',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              kIsWeb
                  ? 'Click "Gallery" above or use the button\nbelow to pick images from your computer'
                  : 'Tap Gallery above or share images\nfrom your phone gallery',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: const Text(
                  'Pick Images from Gallery',
                  style: TextStyle(fontSize: 15),
                ),
                onPressed: onPick,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.crimson,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Panel: selected counter + Add More + Continue
// ─────────────────────────────────────────────────────────────────────────────
class _BottomPanel extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onAddMore;
  final VoidCallback? onContinue;

  const _BottomPanel({
    required this.selectedCount,
    required this.onAddMore,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        border: Border(top: BorderSide(color: AppTheme.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Selected count badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.crimson.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.crimson.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        color: AppTheme.roseGlow,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$selectedCount selected',
                        style: TextStyle(
                          color: AppTheme.roseGlow,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Add More button
                GestureDetector(
                  onTap: onAddMore,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: AppTheme.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Add More',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                // Continue button
                ElevatedButton(
                  onPressed: onContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: onContinue != null
                        ? AppTheme.crimson
                        : AppTheme.cardBg,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Continue', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_ios, size: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Source Card
// ─────────────────────────────────────────────────────────────────────────────
class _SourceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final VoidCallback onTap;

  const _SourceCard({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 14),
                  ),
                  Text(
                    sublabel,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Image Tile with selection animation
// ─────────────────────────────────────────────────────────────────────────────
class _ImageTile extends StatelessWidget {
  final ImageRef file;
  final bool isSelected;
  final VoidCallback onTap;

  const _ImageTile({
    required this.file,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.crimson : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.crimson.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ]
              : [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedScale(
                scale: isSelected ? 0.90 : 1.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: ImageRefWidget(
                  ref: file,
                  fit: BoxFit.cover,
                  cacheWidth: 200,
                ),
              ),
              if (isSelected)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppTheme.crimson.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              Positioned(
                top: 8,
                right: 8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? Colors.transparent
                        : Colors.black.withValues(alpha: 0.3),
                    gradient: isSelected ? AppTheme.primaryGradient : null,
                    border: Border.all(
                      color: isSelected
                          ? Colors.transparent
                          : Colors.white.withValues(alpha: 0.8),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

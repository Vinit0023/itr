import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/storage_service.dart';
import '../widgets/image_ref_widget.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Consumer<AppState>(
        builder: (context, state, _) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            slivers: [
              // ── Hero App Bar ──────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: AppTheme.bgDeep,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: const Icon(Icons.settings_outlined, size: 20),
                    ),
                    onPressed: () => _showSettingsDialog(context, state),
                  ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.pin,
                  background: Stack(
                    children: [
                      // Subtle gradient background
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topRight,
                              end: Alignment.bottomLeft,
                              colors: [
                                AppTheme.maroon.withValues(alpha: 0.25),
                                AppTheme.bgDeep,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Decorative circle
                      Positioned(
                        top: -30,
                        right: -30,
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.maroon.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      // Content
                      Positioned(
                        left: 24,
                        bottom: 20,
                        right: 80,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'TextEraser',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.roseGlow,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Clean your\nimages instantly",
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 28,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Stats Row ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      _StatChip(
                        icon: Icons.auto_fix_high,
                        label: '${state.processedImages.length}',
                        sublabel: 'Processed',
                        color: AppTheme.crimson,
                      ),
                      const SizedBox(width: 12),
                      _StatChip(
                        icon: Icons.photo_album_rounded,
                        label: '${state.albums.length}',
                        sublabel: 'Albums',
                        color: AppTheme.maroon,
                      ),
                    ],
                  ),
                ),
              ),

              // ── Section Header ────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recent Results',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (state.processedImages.isNotEmpty)
                        TextButton(
                          onPressed: () => _showAllProcessed(context, state),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.roseGlow,
                            padding: EdgeInsets.zero,
                          ),
                          child: const Text('View All'),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Grid or Empty State ───────────────────────────
              if (state.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (state.processedImages.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Icon(
                            Icons.auto_fix_high_outlined,
                            size: 48,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'No processed images yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap + to select images and start erasing',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final file = state.processedImages[index];
                        return _ProcessedImageCard(
                          file: file,
                          onTap: () => _showFullImage(context, file),
                          onDelete: () => state.deleteProcessedImage(file),
                        );
                      },
                      childCount: state.processedImages.length > 6
                          ? 6
                          : state.processedImages.length,
                    ),
                  ),
                ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 130)),
            ],
          );
        },
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, '/select');
          if (index == 2) Navigator.pushNamed(context, '/albums');
        },
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, AppState state) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.cardBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text('Settings', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            _SettingsTile(
              icon: Icons.delete_sweep_outlined,
              iconColor: Colors.redAccent,
              title: 'Clear Processed Images',
              subtitle: 'Remove all processed images',
              onTap: () {
                Navigator.pop(ctx);
                _confirmClear(context, state);
              },
            ),
            const Divider(height: 24),
            _SettingsTile(
              icon: Icons.info_outline,
              iconColor: AppTheme.roseGlow,
              title: 'About TextEraser',
              subtitle: 'Version 1.0.0',
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmClear(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All?'),
        content: const Text('This will permanently delete all processed images.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await state.clearAllProcessed();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All processed images cleared')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showFullImage(BuildContext context, ImageRef ref) {
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
              child: ImageRefWidget(
                ref: ref,
                fit: BoxFit.contain,
                key: ValueKey('full_${ref.id}'),
              ),
            ),
          ),
        ),
      ),
    );
  }


  void _showAllProcessed(BuildContext context, AppState state) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('All Processed Images')),
          body: GridView.builder(
            padding: const EdgeInsets.all(16),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: state.processedImages.length,
            itemBuilder: (context, index) {
              final ref = state.processedImages[index];
              return GestureDetector(
                onTap: () => _showFullImage(context, ref),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ImageRefWidget(
                    ref: ref,
                    fit: BoxFit.cover,
                    cacheWidth: 200,
                    key: ValueKey('all_${ref.id}'),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Reusable Widgets ──────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                Text(
                  sublabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessedImageCard extends StatelessWidget {
  final ImageRef file;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProcessedImageCard({
    required this.file,
    required this.onTap,
    required this.onDelete,
  });

  Widget _buildImage() {
    return ImageRefWidget(
      ref: file,
      fit: BoxFit.cover,
      cacheWidth: 300,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildImage(),
              // Gradient overlay
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppTheme.overlayGradient,
                  ),
                ),
              ),
              // Done badge
              Positioned(
                bottom: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.4)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.greenAccent, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Done',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              // Delete button
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: onDelete,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14)),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

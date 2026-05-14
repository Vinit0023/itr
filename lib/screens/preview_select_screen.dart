import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../services/storage_service.dart';
import '../widgets/image_ref_widget.dart';
import '../theme/app_theme.dart';

/// This screen shows selected images in a grid so the user can
/// review, remove, or add more — BEFORE going to the process screen.
class PreviewSelectScreen extends StatefulWidget {
  const PreviewSelectScreen({super.key});

  @override
  State<PreviewSelectScreen> createState() => _PreviewSelectScreenState();
}

class _PreviewSelectScreenState extends State<PreviewSelectScreen> {
  final TextEditingController _hintController = TextEditingController();

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

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
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    // ── App Bar ──────────────────────────────────────
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
                                    border: Border.all(color: AppTheme.cardBorder),
                                  ),
                                  child: const Icon(Icons.arrow_back_ios_new, size: 16),
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Review Selection',
                                      style: Theme.of(context).textTheme.titleLarge,
                                    ),
                                    Text(
                                      '${state.selectedImages.length} image${state.selectedImages.length == 1 ? '' : 's'} selected',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                              // Add more button
                              GestureDetector(
                                onTap: () => state.pickFromGallery(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBg,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.cardBorder),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, color: AppTheme.roseGlow, size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Add',
                                        style: TextStyle(
                                          color: AppTheme.roseGlow,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
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
                    ),

                    // ── Text Hint Field ───────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.cardBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        gradient: AppTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.auto_fix_high, size: 14, color: Colors.white),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Auto-Erase Text Hint',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                              TextField(
                                controller: _hintController,
                                style: const TextStyle(color: AppTheme.textPrimary),
                                decoration: InputDecoration(
                                  hintText: 'e.g. ₹299, SALE, 50% OFF — will be erased from all images',
                                  hintStyle: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                                  suffixIcon: _hintController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(Icons.clear, color: AppTheme.textMuted, size: 18),
                                          onPressed: () {
                                            _hintController.clear();
                                            setState(() {});
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // ── Info hint ────────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 13, color: AppTheme.textMuted),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Leave blank to manually draw the erase mask on next screen',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ── Images Grid Label ─────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Selected Images', style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ),
                    ),

                    // ── Grid or Empty State ───────────────────────────
                    if (state.selectedImages.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.photo_outlined, size: 48, color: AppTheme.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No images selected',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        sliver: SliverGrid(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final image = state.selectedImages[index];
                              return _SelectedImageTile(
                                imageRef: image,
                                onRemove: () => state.toggleSelection(image),
                                onView: () => _viewImage(context, image),
                              );
                            },
                            childCount: state.selectedImages.length,
                          ),
                        ),
                      ),
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
                  child: Column(
                    children: [
                      // Automated erase button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.auto_fix_high, size: 18),
                          label: Text(_hintController.text.trim().isEmpty 
                              ? 'Enter text to start' 
                              : 'Auto Erase "${_hintController.text.trim()}"'),
                          onPressed: (_hintController.text.trim().isEmpty || state.selectedImages.isEmpty)
                              ? null
                              : () => _handleAutoErase(context, state),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.crimson,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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

  Future<void> _handleAutoErase(BuildContext context, AppState state) async {
    final text = _hintController.text.trim();
    FocusScope.of(context).unfocus();
    
    // Navigate to ProcessScreen first, it will handle the state.batchErase call
    Navigator.pushNamed(context, '/process', arguments: text);
  }

  void _viewImage(BuildContext context, ImageRef ref) {
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

class _SelectedImageTile extends StatelessWidget {
  final ImageRef imageRef;
  final VoidCallback onRemove;
  final VoidCallback onView;

  const _SelectedImageTile({
    required this.imageRef,
    required this.onRemove,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onView,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ImageRefWidget(
                ref: imageRef,
                fit: BoxFit.cover,
              ),
              // Remove button
              Positioned(
                top: 5,
                right: 5,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
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


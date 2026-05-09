import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showSettingsDialog(BuildContext context) {
    final state = Provider.of<AppState>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Settings', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                title: const Text('Clear Processed Images', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Remove all processed images', style: TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmClearProcessed(context, state);
                },
              ),
              const Divider(color: Colors.white12),
              ListTile(
                leading: Icon(Icons.info_outline, color: AppTheme.accentCyan),
                title: const Text('About TextEraser', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Version 1.0.0', style: TextStyle(color: Colors.white38, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAboutDialog(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearProcessed(BuildContext context, AppState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear All?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete all processed images. This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
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

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.auto_fix_high, color: AppTheme.accentCyan),
            const SizedBox(width: 8),
            const Text('TextEraser', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Remove text and watermarks from your images with ease. '
          'Select images, mark the areas to erase, and let TextEraser do the rest!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TextEraser'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsDialog(context),
          )
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              // Clear Flutter image cache before reloading
              imageCache.clear();
              imageCache.clearLiveImages();
              await state.loadData();
            },
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back,',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Let\'s clean some images',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Processed',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            TextButton(
                              onPressed: state.processedImages.isEmpty
                                  ? null
                                  : () => _showAllProcessed(context, state),
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.processedImages.isEmpty)
                  const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No processed images yet.\nTap + to start!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white54, fontSize: 16),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final file = state.processedImages[index];
                          return GestureDetector(
                            onTap: () => _showFullImage(context, file),
                            child: Card(
                              clipBehavior: Clip.antiAlias,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                    key: ValueKey('${file.path}_${file.lastModifiedSync().millisecondsSinceEpoch}'),
                                    cacheWidth: 300,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withValues(alpha: 0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: Colors.greenAccent,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: state.processedImages.length > 4 ? 4 : state.processedImages.length,
                      ),
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
              ],
            ),
          );
        },
      ),
      extendBody: true,
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/select');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/albums');
          }
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, dynamic file) {
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
                key: ValueKey('full_${file.path}_${file.lastModifiedSync().millisecondsSinceEpoch}'),
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
          appBar: AppBar(
            title: const Text('All Processed Images'),
          ),
          body: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: state.processedImages.length,
            itemBuilder: (context, index) {
              final file = state.processedImages[index];
              return GestureDetector(
                onTap: () => _showFullImage(context, file),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    file,
                    fit: BoxFit.cover,
                    key: ValueKey('all_${file.path}_${file.lastModifiedSync().millisecondsSinceEpoch}'),
                    cacheWidth: 200,
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

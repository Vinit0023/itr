
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';


class SelectImagesScreen extends StatelessWidget {
  const SelectImagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Images'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Provider.of<AppState>(context, listen: false).clearSelection();
            Navigator.pop(context);
          },
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () => state.pickFromGallery(),
                    ),
                    _SourceButton(
                      icon: Icons.folder_rounded,
                      label: 'Folder',
                      onTap: () => state.pickFromGallery(), // Reusing gallery picker for now
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Received via Share',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextButton(
                      onPressed: () => state.selectAllRecent(),
                      child: const Text('Select All'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.receivedImages.isEmpty
                    ? const Center(
                        child: Text(
                          "No recently shared images",
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: state.receivedImages.length,
                        itemBuilder: (context, index) {
                          final image = state.receivedImages[index];
                          final isSelected = state.selectedImages.contains(image);

                          return GestureDetector(
                            onTap: () => state.toggleSelection(image),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                  width: 3,
                                ),
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(9),
                                    child: Image.file(
                                      image,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  if (isSelected)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              // Floating Continue Panel
              if (state.selectedImages.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${state.selectedImages.length} Selected',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/process');
                          },
                          child: const Text('Continue'),
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

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

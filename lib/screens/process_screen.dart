import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class ProcessScreen extends StatefulWidget {
  const ProcessScreen({super.key});

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _ProcessScreenState extends State<ProcessScreen> {
  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasStarted) {
      _hasStarted = true;
      final searchText = ModalRoute.of(context)?.settings.arguments as String?;
      if (searchText != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _startProcessing(searchText);
        });
      }
    }
  }

  Future<void> _startProcessing(String text) async {
    final state = Provider.of<AppState>(context, listen: false);
    final results = await state.batchErase(text);

    if (mounted) {
      if (results.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/preview');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No matching text found")),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Large circular progress indicator
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: state.processProgress,
                      strokeWidth: 8,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.crimson),
                      backgroundColor: Colors.white12,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${(state.processProgress * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.crimson,
                          ),
                        ),
                        const Text(
                          "DONE",
                          style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.white54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // Image counter
              Text(
                "Processing Image ${state.currentProcessingImageIndex}",
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                "of ${state.totalProcessingImages} total",
                style: const TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 24),
              
              // Linear progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: state.processProgress,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.crimson),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
              const Text(
                "AI is cleaning your images...",
                style: TextStyle(fontSize: 15, color: Colors.white70, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 40),
              
              // Cancel button
              TextButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                label: const Text(
                  "Cancel Processing",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
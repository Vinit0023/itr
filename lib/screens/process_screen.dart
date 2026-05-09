import 'dart:math';
import 'dart:ui' show PointMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image/image.dart' as img;
import '../state/app_state.dart';
import '../services/image_processor.dart';
import '../theme/app_theme.dart';

class ProcessScreen extends StatefulWidget {
  const ProcessScreen({super.key});

  @override
  State<ProcessScreen> createState() => _ProcessScreenState();
}

class _Stroke {
  final List<Offset> points;
  final double brushSize;
  _Stroke({required this.points, required this.brushSize});
}

class _ProcessScreenState extends State<ProcessScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TransformationController _transformController = TransformationController();
  
  bool _isDrawMode = true;
  double _brushSize = 20.0;
  
  final List<_Stroke> _strokes = [];
  _Stroke? _currentStroke;
  
  final GlobalKey _imageKey = GlobalKey();
  Size? _imageSize;
  double? _aspectRatio;
  
  @override
  void initState() {
    super.initState();
    _loadImageAspectRatio();
  }

  Future<void> _loadImageAspectRatio() async {
    final state = Provider.of<AppState>(context, listen: false);
    if (state.selectedImages.isNotEmpty) {
      final bytes = await state.selectedImages.first.readAsBytes();
      // Use Dart image library to read just the header/size without loading whole image to UI memory
      final decoded = img.decodeImage(bytes);
      if (decoded != null) {
        setState(() {
          _aspectRatio = decoded.width / decoded.height;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _calculateImageSize();
        });
      }
    }
  }

  void _calculateImageSize() {
    if (_imageKey.currentContext != null) {
      final RenderBox renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
      setState(() {
        _imageSize = renderBox.size;
      });
    }
  }

  void _onPanStart(DragStartDetails details) {
    if (!_isDrawMode) return;
    if (_imageKey.currentContext == null) return;
    final RenderBox renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _currentStroke = _Stroke(points: [localPosition], brushSize: _brushSize);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawMode || _currentStroke == null) return;
    if (_imageKey.currentContext == null) return;
    final RenderBox renderBox = _imageKey.currentContext!.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _currentStroke!.points.add(localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawMode || _currentStroke == null) return;
    
    setState(() {
      _strokes.add(_currentStroke!);
      _currentStroke = null;
    });
  }

  Future<void> _handleAutoSearch() async {
    final text = _searchController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter text to search')),
      );
      return;
    }

    FocusScope.of(context).unfocus();

    final state = Provider.of<AppState>(context, listen: false);
    
    imageCache.clear();
    imageCache.clearLiveImages();
    
    await state.autoSearchAndErase(text);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/preview');
    }
  }

  Future<void> _handleProcess() async {
    if (_strokes.isEmpty && _currentStroke == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draw over the areas you want to erase')),
      );
      return;
    }

    if (_imageSize == null) return;

    final state = Provider.of<AppState>(context, listen: false);
    
    // Convert strokes to percentages based on the exact image size
    List<ErasePath> erasePaths = _strokes.map((stroke) {
      return ErasePath(
        brushSizePercent: stroke.brushSize / max(_imageSize!.width, _imageSize!.height),
        points: stroke.points.map((p) => Point<double>(
          (p.dx / _imageSize!.width).clamp(0.0, 1.0), 
          (p.dy / _imageSize!.height).clamp(0.0, 1.0)
        )).toList(),
      );
    }).toList();
    
    imageCache.clear();
    imageCache.clearLiveImages();
    
    await state.batchProcess(paths: erasePaths);

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/preview');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw & Erase'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<AppState>(
        builder: (context, state, child) {
          if (state.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: state.processProgress,
                    color: AppTheme.accentCyan,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'AI Processing... ${(state.processProgress * 100).toInt()}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          if (state.selectedImages.isEmpty) {
            return const Center(child: Text('No images selected'));
          }

          return Column(
            children: [
              // Auto Search Bar
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.accentPurple.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Auto Search & Erase (e.g. 1099)',
                          hintStyle: TextStyle(color: Colors.white38),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          prefixIcon: Icon(Icons.saved_search, color: AppTheme.accentPurple),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _handleAutoSearch,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(15)),
                        ),
                        child: const Text('Auto Erase', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),

              // Tool Options Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Toggle Draw / Pan
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.pan_tool, color: !_isDrawMode ? AppTheme.accentCyan : Colors.white38),
                            onPressed: () => setState(() => _isDrawMode = false),
                            tooltip: 'Pan & Zoom',
                          ),
                          Container(width: 1, height: 24, color: Colors.white12),
                          IconButton(
                            icon: Icon(Icons.brush, color: _isDrawMode ? AppTheme.accentCyan : Colors.white38),
                            onPressed: () => setState(() => _isDrawMode = true),
                            tooltip: 'Draw Mask',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Brush Size Slider
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(Icons.circle, size: 8, color: Colors.white54),
                          Expanded(
                            child: Slider(
                              value: _brushSize,
                              min: 5.0,
                              max: 80.0,
                              activeColor: AppTheme.accentCyan,
                              onChanged: _isDrawMode ? (val) => setState(() => _brushSize = val) : null,
                            ),
                          ),
                          const Icon(Icons.circle, size: 24, color: Colors.white54),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Main Drawing Canvas
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InteractiveViewer(
                      transformationController: _transformController,
                      panEnabled: !_isDrawMode,
                      scaleEnabled: !_isDrawMode,
                      minScale: 0.5,
                      maxScale: 5.0,
                      child: _aspectRatio == null 
                        ? const Center(child: CircularProgressIndicator())
                        : Center(
                            child: AspectRatio(
                              aspectRatio: _aspectRatio!,
                              child: GestureDetector(
                                onPanStart: _onPanStart,
                                onPanUpdate: _onPanUpdate,
                                onPanEnd: _onPanEnd,
                                child: Stack(
                                  key: _imageKey,
                                  alignment: Alignment.center,
                                  children: [
                                    Image.file(
                                      state.selectedImages.first,
                                      fit: BoxFit.fill,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                    if (_imageSize != null)
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: _MaskPainter(
                                            strokes: _strokes,
                                            currentStroke: _currentStroke,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                ),
              ),

              // Action Bar
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo),
                      onPressed: _strokes.isEmpty ? null : () {
                        setState(() {
                          _strokes.removeLast();
                          // Force recalculate size just in case
                          _calculateImageSize();
                        });
                      },
                      color: Colors.white,
                      style: IconButton.styleFrom(backgroundColor: AppTheme.cardBg),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _strokes.isEmpty ? null : () => setState(() => _strokes.clear()),
                      color: Colors.redAccent,
                      style: IconButton.styleFrom(backgroundColor: AppTheme.cardBg),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _strokes.isEmpty ? null : _handleProcess,
                        icon: const Icon(Icons.auto_fix_high),
                        label: Text('Erase Selection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentCyan,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MaskPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? currentStroke;

  _MaskPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.5)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      paint.strokeWidth = stroke.brushSize * 2; 
      _drawStroke(canvas, stroke, paint);
    }

    if (currentStroke != null) {
      paint.strokeWidth = currentStroke!.brushSize * 2;
      _drawStroke(canvas, currentStroke!, paint);
    }
  }

  void _drawStroke(Canvas canvas, _Stroke stroke, Paint paint) {
    if (stroke.points.isEmpty) return;
    if (stroke.points.length == 1) {
      canvas.drawPoints(PointMode.points, stroke.points, paint);
      return;
    }

    final path = Path();
    path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) {
    return true; 
  }
}

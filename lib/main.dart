import 'dart:ui' as ui;
import 'dart:math';
import 'package:flutter/material.dart';

// Entry point of the application
void main() {
  runApp(const ProfileApp());
}

// A helper class to generate images with different colors
class ImageGenerator {
  // Generates a simple 10x10 px image with a solid color
  static Future<ui.Image> createImageWithColor(Color color) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
        recorder, const Rect.fromLTWH(0.0, 0.0, 10.0, 10.0));
    final paint = Paint()..color = color;
    canvas.drawRect(const Rect.fromLTWH(0.0, 0.0, 10.0, 10.0), paint);
    final picture = recorder.endRecording();
    return await picture.toImage(10, 10);
  }

  // Generates 100 different colored images
  static Future<List<ui.Image>> createImages(int count, Random random) async {
    final images = <ui.Image>[];
    for (int i = 0; i < count; i++) {
      final color = Color.fromARGB(
        255,
        (random.nextDouble() * 255).toInt(),
        (random.nextDouble() * 255).toInt(),
        (random.nextDouble() * 255).toInt(),
      );
      final image = await createImageWithColor(color);
      images.add(image);
    }
    return images;
  }
}

// The root widget of the application
class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Painting Profiling',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const ProfilingHomeScreen(),
    );
  }
}

// The main screen that allows switching between the two painting approaches
class ProfilingHomeScreen extends StatefulWidget {
  const ProfilingHomeScreen({super.key});

  @override
  _ProfilingHomeScreenState createState() => _ProfilingHomeScreenState();
}

class _ProfilingHomeScreenState extends State<ProfilingHomeScreen> {
  // Holds the generated images, will be initialized in initState
  List<ui.Image>? _images;
  // Determines which painting method is currently active
  Widget _currentDisplay = const Center(child: CircularProgressIndicator());
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    // Generate 100 different colored images when the widget is first created
    ImageGenerator.createImages(100, _random).then((images) {
      setState(() {
        _images = images;
        // Default to showing the single CustomPaint approach first
        _showSingleCustomPaint();
      });
    });
  }

  // Sets the display to the Single CustomPaint method
  void _showSingleCustomPaint() {
    if (_images != null) {
      setState(() {
        _currentDisplay = SingleCustomPaintScreen(images: _images!);
      });
    }
  }

  // Sets the display to the Flow delegate method
  void _showFlowDelegate() {
    if (_images != null) {
      setState(() {
        _currentDisplay = FlowDelegateScreen(images: _images!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painting Profiling Example'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              'Use Flutter DevTools to profile the performance of each approach.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _images == null ? null : _showSingleCustomPaint,
                child: const Text('Single CustomPaint'),
              ),
              ElevatedButton(
                onPressed: _images == null ? null : _showFlowDelegate,
                child: const Text('Flow Delegate'),
              ),
            ],
          ),
          const Divider(height: 24),
          // The area where the selected painting method is rendered
          Expanded(child: _currentDisplay),
        ],
      ),
    );
  }
}

// --- Approach 1: A single CustomPaint to draw all images ---

class SingleCustomPaintScreen extends StatefulWidget {
  final List<ui.Image> images;
  const SingleCustomPaintScreen({super.key, required this.images});

  @override
  State<SingleCustomPaintScreen> createState() =>
      _SingleCustomPaintScreenState();
}

class _SingleCustomPaintScreenState extends State<SingleCustomPaintScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: GridPainter(image: widget.image, random: _random),
          size: Size.infinite,
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  final List<ui.Image> images;
  final Random random;

  GridPainter({required this.images, required this.random});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < images.length; i++) {
      final image = images[i];
      final baseX = (i % 10) * 20.0 + 10;
      final baseY = (i ~/ 10) * 20.0 + 10;

      // Random transformations
      final translateX = baseX + (random.nextDouble() - 0.5) * 10.0;
      final translateY = baseY + (random.nextDouble() - 0.5) * 10.0;
      final scale = 0.8 + random.nextDouble() * 0.4; // 0.8 to 1.2
      final rotation =
          (random.nextDouble() - 0.5) * 0.5; // -0.25 to 0.25 radians

      final srcRect = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      final paint = Paint();

      canvas.save();
      canvas.translate(translateX + 7.5, translateY + 7.5);
      canvas.scale(scale);
      canvas.rotate(rotation);
      canvas.drawImageRect(
        image,
        srcRect,
        Rect.fromLTWH(-7.5, -7.5, 15, 15),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) => true;
}

// --- Approach 2: A Flow widget with 100 CustomPaint children ---

class FlowDelegateScreen extends StatefulWidget {
  final List<ui.Image> images;
  const FlowDelegateScreen({super.key, required this.images});

  @override
  State<FlowDelegateScreen> createState() => _FlowDelegateScreenState();
}

class _FlowDelegateScreenState extends State<FlowDelegateScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 50),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Flow(
          delegate: GridFlowDelegate(random: _random),
          children: List.generate(
            images.length,
            (index) => Align(
              alignment: Alignment.topLeft,
              child: CustomPaint(
                painter: SingleImagePainter(
                  image: widget.images[index],
                ),
                size: const Size(15, 15),
              ),
            ),
          ),
        );
      },
    );
  }
}

class GridFlowDelegate extends FlowDelegate {
  final Random random;

  GridFlowDelegate({required this.random});

  @override
  void paintChildren(FlowPaintingContext context) {
    for (int i = 0; i < context.childCount; i++) {
      final baseX = (i % 10) * 20.0 + 10;
      final baseY = (i ~/ 10) * 20.0 + 10;

      // Random transformations
      final translateX = baseX + (random.nextDouble() - 0.5) * 10.0;
      final translateY = baseY + (random.nextDouble() - 0.5) * 10.0;
      final scale = 0.8 + random.nextDouble() * 0.4;
      final rotation = (random.nextDouble() - 0.5) * 0.5;

      final transform = Matrix4.identity()
        ..translate(translateX, translateY)
        ..scale(scale)
        ..rotateZ(rotation);

      context.paintChild(i, transform: transform);
    }
  }

  @override
  bool shouldRepaint(covariant GridFlowDelegate oldDelegate) => true;
}

// A painter responsible for drawing only one image with color tint
class SingleImagePainter extends CustomPainter {
  final ui.Image image;

  SingleImagePainter({required this.image});

  @override
  void paint(Canvas canvas, Size size) {
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final dstRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint();

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant SingleImagePainter oldDelegate) => true;
}

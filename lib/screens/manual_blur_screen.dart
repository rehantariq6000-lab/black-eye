import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/detection_match.dart';

/// Lets the user drag rectangles over the image to hide areas that the
/// automatic detection missed.
///
/// The user draws in screen coordinates, but we store the boxes in image
/// (pixel) coordinates so they line up when the image is masked later.
class ManualBlurScreen extends StatefulWidget {
  /// The original image the boxes will be drawn on.
  final File image;

  const ManualBlurScreen({super.key, required this.image});

  @override
  State<ManualBlurScreen> createState() => _ManualBlurScreenState();
}

class _ManualBlurScreenState extends State<ManualBlurScreen> {
  final List<Rect> _boxesImageSpace = [];

  int? _imageWidth;
  int? _imageHeight;

  // The rectangle the user is currently dragging (in screen coordinates).
  Offset? _dragStart;
  Offset? _dragEnd;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  Future<void> _loadImageSize() async {
    final bytes = await widget.image.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() {
      _imageWidth = frame.image.width;
      _imageHeight = frame.image.height;
    });
  }

  /// Works out where the image sits inside the given box using BoxFit.contain
  /// (letterboxed), so we can convert between screen and image coordinates.
  _FitInfo _fit(Size boxSize) {
    final imgW = _imageWidth!.toDouble();
    final imgH = _imageHeight!.toDouble();
    final scale = (boxSize.width / imgW).clamp(0.0, boxSize.height / imgH);
    final dispW = imgW * scale;
    final dispH = imgH * scale;
    final dx = (boxSize.width - dispW) / 2;
    final dy = (boxSize.height - dispH) / 2;
    return _FitInfo(scale: scale, offset: Offset(dx, dy), size: Size(dispW, dispH));
  }

  void _finishBox(Size boxSize) {
    if (_dragStart == null || _dragEnd == null) return;
    final fit = _fit(boxSize);

    // Convert both corners from screen space to image space.
    Offset toImage(Offset p) => Offset(
          ((p.dx - fit.offset.dx) / fit.scale).clamp(0.0, _imageWidth!.toDouble()),
          ((p.dy - fit.offset.dy) / fit.scale).clamp(0.0, _imageHeight!.toDouble()),
        );

    final a = toImage(_dragStart!);
    final b = toImage(_dragEnd!);
    final rect = Rect.fromPoints(a, b);

    // Ignore tiny accidental taps.
    if (rect.width > 4 && rect.height > 4) {
      setState(() => _boxesImageSpace.add(rect));
    }
    setState(() {
      _dragStart = null;
      _dragEnd = null;
    });
  }

  void _done() {
    final matches = _boxesImageSpace
        .map((r) => DetectionMatch(box: r, categoryLabel: 'Manual'))
        .toList();
    Navigator.of(context).pop(matches);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _imageWidth != null && _imageHeight != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.manualBlurTitle),
        actions: [
          if (_boxesImageSpace.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () => setState(() => _boxesImageSpace.removeLast()),
            ),
          TextButton(
            onPressed: _done,
            child: Text(S.done, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: !ready
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(S.manualBlurHint),
                ),
                Expanded(child: _buildCanvas()),
              ],
            ),
    );
  }

  Widget _buildCanvas() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = Size(constraints.maxWidth, constraints.maxHeight);
        final fit = _fit(boxSize);
        return GestureDetector(
          onPanStart: (d) => setState(() {
            _dragStart = d.localPosition;
            _dragEnd = d.localPosition;
          }),
          onPanUpdate: (d) => setState(() => _dragEnd = d.localPosition),
          onPanEnd: (_) => _finishBox(boxSize),
          child: Stack(
            children: [
              Positioned(
                left: fit.offset.dx,
                top: fit.offset.dy,
                width: fit.size.width,
                height: fit.size.height,
                child: Image.file(widget.image, fit: BoxFit.fill),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _BoxPainter(
                    boxes: _boxesImageSpace,
                    fit: fit,
                    current: (_dragStart != null && _dragEnd != null)
                        ? Rect.fromPoints(_dragStart!, _dragEnd!)
                        : null,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FitInfo {
  final double scale;
  final Offset offset;
  final Size size;
  const _FitInfo({required this.scale, required this.offset, required this.size});
}

/// Draws the saved boxes (in image space) and the one being dragged.
class _BoxPainter extends CustomPainter {
  final List<Rect> boxes;
  final _FitInfo fit;
  final Rect? current;

  _BoxPainter({required this.boxes, required this.fit, this.current});

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()..color = Colors.black.withValues(alpha: 0.45);
    final border = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final box in boxes) {
      // Convert the image-space box back to screen space to draw it.
      final screenRect = Rect.fromLTWH(
        fit.offset.dx + box.left * fit.scale,
        fit.offset.dy + box.top * fit.scale,
        box.width * fit.scale,
        box.height * fit.scale,
      );
      canvas.drawRect(screenRect, fill);
    }

    if (current != null) {
      canvas.drawRect(current!, border);
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter old) => true;
}

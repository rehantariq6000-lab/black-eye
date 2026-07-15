import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../models/detection_match.dart';
import '../models/mask_style.dart';

/// Hides the sensitive areas of an image using the chosen [MaskStyle].
class ImageMasker {
  /// Reads [original], hides every area in [matches] with [style], and saves
  /// the result as a new file which is returned.
  Future<File> maskImage(
    File original,
    List<DetectionMatch> matches,
    MaskStyle style,
  ) async {
    final bytes = await original.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw Exception('Could not read the selected image.');
    }

    applyMasks(image, matches, style);
    return _writeToFile(img.encodeJpg(image));
  }

  /// Hides the areas directly on the given [image] (edited in place).
  /// Kept separate so PDF pages can reuse the same logic.
  void applyMasks(img.Image image, List<DetectionMatch> matches, MaskStyle style) {
    for (final match in matches) {
      // Keep the rectangle inside the image so we never go out of bounds.
      final x = match.box.left.round().clamp(0, image.width - 1);
      final y = match.box.top.round().clamp(0, image.height - 1);
      final w = match.box.width.round().clamp(1, image.width - x);
      final h = match.box.height.round().clamp(1, image.height - y);

      switch (style) {
        case MaskStyle.blur:
          _blurRegion(image, x, y, w, h);
        case MaskStyle.pixelate:
          _pixelateRegion(image, x, y, w, h);
        case MaskStyle.blackBox:
          img.fillRect(image,
              x1: x, y1: y, x2: x + w - 1, y2: y + h - 1,
              color: img.ColorRgb8(0, 0, 0));
      }
    }
  }

  void _blurRegion(img.Image image, int x, int y, int w, int h) {
    final region = img.copyCrop(image, x: x, y: y, width: w, height: h);
    final blurred = img.gaussianBlur(region, radius: 12);
    img.compositeImage(image, blurred, dstX: x, dstY: y);
  }

  void _pixelateRegion(img.Image image, int x, int y, int w, int h) {
    final region = img.copyCrop(image, x: x, y: y, width: w, height: h);
    // Shrink then grow back with no smoothing to get big blocky pixels.
    final small = img.copyResize(region,
        width: math.max(1, w ~/ 10),
        height: math.max(1, h ~/ 10),
        interpolation: img.Interpolation.nearest);
    final blocky = img.copyResize(small,
        width: w, height: h, interpolation: img.Interpolation.nearest);
    img.compositeImage(image, blocky, dstX: x, dstY: y);
  }

  Future<File> _writeToFile(List<int> jpgBytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final name = 'black_eye_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(jpgBytes);
    return file;
  }
}

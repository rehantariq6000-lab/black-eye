import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import '../models/detection_match.dart';
import '../models/mask_style.dart';

/// Hides the sensitive areas of an image using the chosen [MaskStyle].
///
/// Works on raw bytes (no file system), so the exact same code runs on the
/// web, on mobile, and on desktop.
class ImageMasker {
  /// Returns new image bytes where every area in [matches] is hidden.
  Uint8List maskBytes(
    Uint8List originalBytes,
    List<DetectionMatch> matches,
    MaskStyle style,
  ) {
    final image = img.decodeImage(originalBytes);
    if (image == null) {
      throw Exception('Could not read the selected image.');
    }
    applyMasks(image, matches, style);
    return Uint8List.fromList(img.encodeJpg(image));
  }

  /// Hides the areas directly on the given [image] (edited in place).
  void applyMasks(img.Image image, List<DetectionMatch> matches, MaskStyle style) {
    for (final match in matches) {
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
    final small = img.copyResize(region,
        width: math.max(1, w ~/ 10),
        height: math.max(1, h ~/ 10),
        interpolation: img.Interpolation.nearest);
    final blocky = img.copyResize(small,
        width: w, height: h, interpolation: img.Interpolation.nearest);
    img.compositeImage(image, blocky, dstX: x, dstY: y);
  }
}

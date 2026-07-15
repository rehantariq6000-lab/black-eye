import 'dart:ui';

/// One piece of sensitive text that was found in the image.
///
/// [box] is where it sits on the image (in image pixels), and [categoryLabel]
/// tells us what kind of data it is (e.g. "Email addresses").
class DetectionMatch {
  final Rect box;
  final String categoryLabel;

  const DetectionMatch({
    required this.box,
    required this.categoryLabel,
  });
}

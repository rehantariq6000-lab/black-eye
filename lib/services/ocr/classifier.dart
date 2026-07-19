import 'dart:ui';

import '../../models/detection_category.dart';
import '../../models/detection_match.dart';
import 'ocr_models.dart';

/// Turns recognised text into a list of sensitive areas to blur.
///
/// This is shared by both OCR engines (ML Kit on mobile, Tesseract on the
/// web) so the detection rules and the tight word-level masking behave
/// exactly the same on every platform.
List<DetectionMatch> classifyLines(
  List<OcrLine> lines,
  Set<String> enabledKeys,
  List<String> keywords,
) {
  final matches = <DetectionMatch>[];
  for (final line in lines) {
    _matchLine(line, enabledKeys, keywords, matches);
  }
  return matches;
}

void _matchLine(
  OcrLine line,
  Set<String> enabledKeys,
  List<String> keywords,
  List<DetectionMatch> out,
) {
  final text = line.text;
  final hits = <_Hit>[];

  // The user's own keywords.
  final lower = text.toLowerCase();
  for (final word in keywords) {
    if (word.isEmpty) continue;
    final index = lower.indexOf(word.toLowerCase());
    if (index >= 0) {
      hits.add(_Hit(text.substring(index, index + word.length), 'Keyword: $word'));
    }
  }

  // The built-in RegEx categories.
  for (final category in kAllCategories) {
    if (category.key == kQrKey) continue; // QR is handled by the detector
    if (!enabledKeys.contains(category.key)) continue;
    for (final match in category.pattern.allMatches(text)) {
      hits.add(_Hit(match.group(0)!, category.label));
    }
  }

  if (hits.isEmpty) return;

  for (final hit in hits) {
    final boxes = <DetectionMatch>[];
    for (final word in line.words) {
      final w = word.text.trim();
      if (w.isNotEmpty && hit.text.contains(w)) {
        boxes.add(DetectionMatch(box: word.box, categoryLabel: hit.label));
      }
    }
    if (boxes.isEmpty) {
      // Fallback: if we cannot line up the words, blur the whole line.
      final lineBox = _lineBounds(line);
      if (lineBox != null) {
        out.add(DetectionMatch(box: lineBox, categoryLabel: hit.label));
      }
    } else {
      out.addAll(boxes);
    }
  }
}

/// The bounding box that covers every word in a line.
Rect? _lineBounds(OcrLine line) {
  if (line.words.isEmpty) return null;
  var rect = line.words.first.box;
  for (final word in line.words.skip(1)) {
    rect = rect.expandToInclude(word.box);
  }
  return rect;
}

class _Hit {
  final String text;
  final String label;
  const _Hit(this.text, this.label);
}

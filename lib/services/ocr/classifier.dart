import 'dart:ui';

import '../../models/detection_category.dart';
import '../../models/detection_match.dart';
import 'ocr_models.dart';

/// Turns recognised text into a list of sensitive areas to blur.
///
/// Shared by both OCR engines (ML Kit on mobile, Tesseract on the web). It
/// checks each line two ways so nothing slips through:
///   1. Whole-line match — catches values split across several words, like a
///      card number "5412 7512 3412 3456" or a spaced IBAN.
///   2. Single-word match — catches values the OCR returns as one token, like
///      an email, an SSN "478-63-7291", or an ID "S123-456-789-012".
/// A word is blurred if it matches either way, so every enabled category is
/// reliably covered.
List<DetectionMatch> classifyLines(
  List<OcrLine> lines,
  Set<String> enabledKeys,
  List<String> keywords,
) {
  final out = <DetectionMatch>[];
  for (final line in lines) {
    final blur = <OcrWord, String>{}; // word -> label

    // 1. Whole-line matches: mark the words inside each matched value.
    final lineHits = _hits(line.text, enabledKeys, keywords);
    for (final hit in lineHits) {
      for (final word in line.words) {
        final w = word.text.trim();
        if (w.isNotEmpty && (hit.text.contains(w) || w.contains(hit.text))) {
          blur[word] = hit.label;
        }
      }
    }

    // 2. Single-word matches: catch tokens the line scan missed.
    for (final word in line.words) {
      if (blur.containsKey(word)) continue;
      final wordHits = _hits(word.text, enabledKeys, keywords);
      if (wordHits.isNotEmpty) blur[word] = wordHits.first.label;
    }

    blur.forEach((word, label) {
      out.add(DetectionMatch(box: word.box, categoryLabel: label));
    });

    // Safety net: a line matched but we couldn't line up any word — blur it.
    if (lineHits.isNotEmpty && blur.isEmpty) {
      final b = _lineBounds(line);
      if (b != null) {
        out.add(DetectionMatch(box: b, categoryLabel: lineHits.first.label));
      }
    }
  }
  return out;
}

/// Every sensitive value found in [text], with its category label.
List<_Hit> _hits(String text, Set<String> enabledKeys, List<String> keywords) {
  final hits = <_Hit>[];
  if (text.trim().isEmpty) return hits;

  final lower = text.toLowerCase();
  for (final word in keywords) {
    if (word.isEmpty) continue;
    final index = lower.indexOf(word.toLowerCase());
    if (index >= 0) {
      hits.add(_Hit(text.substring(index, index + word.length), 'Keyword: $word'));
    }
  }

  for (final category in kAllCategories) {
    if (category.key == kQrKey) continue;
    if (!enabledKeys.contains(category.key)) continue;
    for (final match in category.pattern.allMatches(text)) {
      final value = match.group(0)!;
      if (category.validate != null && !category.validate!(value)) continue;
      hits.add(_Hit(value, category.label));
    }
  }
  return hits;
}

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

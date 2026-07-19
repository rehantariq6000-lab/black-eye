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
/// Field labels that are followed by a person's name.
const _nameLabels = {'name', 'ln', 'fn', 'holder', 'inhaber', 'kontoinhaber'};

List<DetectionMatch> classifyLines(
  List<OcrLine> lines,
  Set<String> enabledKeys,
  List<String> keywords,
) {
  final out = <DetectionMatch>[];
  final namesOn = enabledKeys.contains(kNameKey);
  var expectNameNextLine = false;

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

    // 3. Names: blur the value after a name label ("Full Name: ...", "LN ..."),
    //    or a name-looking line that follows a bare label line ("CARD HOLDER").
    if (namesOn) {
      final words = line.words;
      var lastLabel = -1;
      for (var i = 0; i < words.length; i++) {
        if (_nameLabels.contains(_normalize(words[i].text))) lastLabel = i;
      }
      if (lastLabel >= 0) {
        var blurred = false;
        for (var i = lastLabel + 1; i < words.length; i++) {
          if (_nameLike(words[i].text)) {
            blur[words[i]] = 'Name';
            blurred = true;
          }
        }
        expectNameNextLine = !blurred; // label with no value -> name is next
      } else if (expectNameNextLine && _looksLikeName(line)) {
        for (final w in line.words) {
          blur[w] = 'Name';
        }
        expectNameNextLine = false;
      } else {
        expectNameNextLine = false;
      }
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

/// Lower-cased letters only (drops ":", ".", etc.) for label comparison.
String _normalize(String s) =>
    s.toLowerCase().replaceAll(RegExp(r'[^a-zäöüß]'), '');

/// A single word that looks like part of a name (letters, maybe an initial).
bool _nameLike(String word) {
  final t = word.replaceAll(RegExp(r'[.,]'), '').trim();
  return t.isNotEmpty && RegExp(r'^[A-Za-zÀ-ſ]+$').hasMatch(t);
}

/// A whole line that looks like a name: up to 4 name-like words.
bool _looksLikeName(OcrLine line) {
  final words =
      line.words.where((w) => w.text.trim().isNotEmpty).toList();
  if (words.isEmpty || words.length > 4) return false;
  return words.every((w) => _nameLike(w.text));
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

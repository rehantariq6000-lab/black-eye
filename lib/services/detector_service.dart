import 'dart:io';
import 'dart:ui';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../models/detection_category.dart';
import '../models/detection_match.dart';

/// Reads the text (and QR codes) out of an image and decides which parts are
/// sensitive.
///
/// This is the heart of Black Eye. It uses Google ML Kit to do the OCR and
/// barcode scanning (both give us the position of what they find), then
/// checks each line against our rules and the user's own keywords.
///
/// The OCR uses the Latin script recognizer, which reads English and German
/// (including umlauts like ä, ö, ü and ß) out of the box.
class DetectorService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcodeScanner =
      BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  /// Finds all sensitive content in [imageFile].
  Future<List<DetectionMatch>> detect(
    File imageFile,
    Set<String> enabledKeys,
    List<String> keywords,
  ) async {
    final inputImage = InputImage.fromFile(imageFile);
    final matches = <DetectionMatch>[];

    // --- Text (OCR) ---
    final recognizedText = await _recognizer.processImage(inputImage);
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        _matchLine(line, enabledKeys, keywords, matches);
      }
    }

    // --- QR codes ---
    if (enabledKeys.contains(kQrKey)) {
      final barcodes = await _barcodeScanner.processImage(inputImage);
      for (final barcode in barcodes) {
        matches.add(DetectionMatch(box: barcode.boundingBox, categoryLabel: 'QR code'));
      }
    }

    return matches;
  }

  /// Checks one line of text and adds tight boxes for anything sensitive.
  ///
  /// Instead of blurring the whole line, we only blur the individual words
  /// (ML Kit "elements") that are actually part of the sensitive value, so
  /// the mask covers just the private data and nothing more.
  void _matchLine(
    TextLine line,
    Set<String> enabledKeys,
    List<String> keywords,
    List<DetectionMatch> out,
  ) {
    final text = line.text;

    // Collect every sensitive substring found in this line, with a label.
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
      if (category.key == kQrKey) continue; // QR is handled separately
      if (!enabledKeys.contains(category.key)) continue;
      for (final match in category.pattern.allMatches(text)) {
        hits.add(_Hit(match.group(0)!, category.label));
      }
    }

    if (hits.isEmpty) return;

    for (final hit in hits) {
      final boxes = _boxesForHit(line, hit.text);
      if (boxes.isEmpty) {
        // Fallback: if we cannot line up the words, blur the whole line.
        out.add(DetectionMatch(box: line.boundingBox, categoryLabel: hit.label));
      } else {
        for (final box in boxes) {
          out.add(DetectionMatch(box: box, categoryLabel: hit.label));
        }
      }
    }
  }

  /// Returns the boxes of the words that make up [matchedText] inside [line].
  List<Rect> _boxesForHit(TextLine line, String matchedText) {
    final boxes = <Rect>[];
    for (final element in line.elements) {
      final word = element.text.trim();
      if (word.isNotEmpty && matchedText.contains(word)) {
        boxes.add(element.boundingBox);
      }
    }
    return boxes;
  }

  /// Frees the ML Kit resources. Call this when the screen is closed.
  void dispose() {
    _recognizer.close();
    _barcodeScanner.close();
  }
}

/// A single sensitive value found in a line, plus its category label.
class _Hit {
  final String text;
  final String label;
  const _Hit(this.text, this.label);
}

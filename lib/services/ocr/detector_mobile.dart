import 'dart:io';
import 'dart:typed_data';

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import '../../models/detection_category.dart';
import '../../models/detection_match.dart';
import 'classifier.dart';
import 'detector.dart';
import 'ocr_models.dart';

/// Creates the mobile/native detector (used on Android, iOS, macOS, Windows).
Detector createDetector() => MobileDetector();

/// OCR + QR detection using Google ML Kit. ML Kit needs the image on disk,
/// so we use the [filePath] passed in from the picker.
class MobileDetector implements Detector {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.latin);
  final BarcodeScanner _barcodeScanner =
      BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  @override
  Future<List<DetectionMatch>> detect({
    required Uint8List bytes,
    String? filePath,
    required Set<String> enabledKeys,
    required List<String> keywords,
    required bool german,
  }) async {
    // ML Kit's Latin recognizer already reads both English and German.
    final inputImage = filePath != null
        ? InputImage.fromFile(File(filePath))
        : InputImage.fromFilePath('');

    final recognizedText = await _recognizer.processImage(inputImage);

    // Turn ML Kit's result into our shared line/word model.
    final lines = <OcrLine>[];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final words = [
          for (final element in line.elements)
            OcrWord(element.text, element.boundingBox),
        ];
        lines.add(OcrLine(line.text, words));
      }
    }

    final matches = classifyLines(lines, enabledKeys, keywords);

    // QR codes.
    if (enabledKeys.contains(kQrKey)) {
      final barcodes = await _barcodeScanner.processImage(inputImage);
      for (final barcode in barcodes) {
        matches.add(DetectionMatch(box: barcode.boundingBox, categoryLabel: 'QR code'));
      }
    }

    return matches;
  }

  @override
  void dispose() {
    _recognizer.close();
    _barcodeScanner.close();
  }
}

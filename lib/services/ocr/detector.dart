import 'dart:typed_data';

import '../../models/detection_match.dart';

// Pick the right OCR engine at compile time:
// - on the web we use Tesseract.js (runs in the browser)
// - everywhere else we use Google ML Kit (runs natively on the device)
import 'detector_mobile.dart'
    if (dart.library.js_interop) 'detector_web.dart' as impl;

/// Finds the sensitive areas in an image, whatever the platform.
abstract class Detector {
  /// [bytes] are the raw image bytes (used on the web). [filePath] is the
  /// path to the same image on disk (used by ML Kit on mobile/desktop).
  Future<List<DetectionMatch>> detect({
    required Uint8List bytes,
    String? filePath,
    required Set<String> enabledKeys,
    required List<String> keywords,
    required bool german,
  });

  void dispose();
}

/// Creates the correct detector for the current platform.
Detector createDetector() => impl.createDetector();

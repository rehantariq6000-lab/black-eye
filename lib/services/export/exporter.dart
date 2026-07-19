import 'dart:typed_data';

import 'exporter_mobile.dart'
    if (dart.library.js_interop) 'exporter_web.dart' as impl;

/// Saves and shares the protected image, in the way that fits the platform.
abstract class Exporter {
  /// Whether "save to gallery" makes sense here (mobile only).
  bool get canSaveToGallery;

  /// Saves the image (to the gallery on mobile, as a download on the web).
  Future<void> save(Uint8List bytes, String fileName);

  /// Shares the image (system share sheet on mobile, download on the web).
  Future<void> share(Uint8List bytes, String fileName);
}

Exporter createExporter() => impl.createExporter();

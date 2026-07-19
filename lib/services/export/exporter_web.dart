import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

import 'exporter.dart';

Exporter createExporter() => WebExporter();

/// On the web there is no gallery, so both "save" and "share" download the
/// protected image as a file to the user's computer.
class WebExporter implements Exporter {
  @override
  bool get canSaveToGallery => true; // shown as "Download" in the UI

  @override
  Future<void> save(Uint8List bytes, String fileName) async => _download(bytes, fileName);

  @override
  Future<void> share(Uint8List bytes, String fileName) async => _download(bytes, fileName);

  void _download(Uint8List bytes, String fileName) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: 'image/jpeg'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}

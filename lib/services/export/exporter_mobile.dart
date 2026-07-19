import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'exporter.dart';

Exporter createExporter() => MobileExporter();

/// Saves to the phone gallery and shares through the system share sheet
/// (WhatsApp, email, etc.).
class MobileExporter implements Exporter {
  @override
  bool get canSaveToGallery => true;

  @override
  Future<void> save(Uint8List bytes, String fileName) async {
    final file = await _writeTemp(bytes, fileName);
    await Gal.putImage(file.path);
  }

  @override
  Future<void> share(Uint8List bytes, String fileName) async {
    final file = await _writeTemp(bytes, fileName);
    await Share.shareXFiles([XFile(file.path)], text: 'Protected with Black Eye');
  }

  Future<File> _writeTemp(Uint8List bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file;
  }
}

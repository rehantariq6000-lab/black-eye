import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';

import '../models/detection_match.dart';
import '../models/mask_style.dart';
import 'image_masker.dart';
import 'ocr/detector.dart';

/// Scans a PDF the same way as an image: it turns every page into a picture,
/// finds and hides the sensitive parts, then builds a new protected PDF.
class PdfService {
  final Detector _detector;
  final ImageMasker _masker;

  PdfService(this._detector, this._masker);

  /// Processes [pdfFile] and returns the new protected PDF, along with how
  /// many sensitive items were hidden in total.
  Future<({File file, int hidden})> protectPdf(
    File pdfFile,
    Set<String> enabledKeys,
    List<String> keywords,
    MaskStyle style,
    bool german,
  ) async {
    final document = await PdfDocument.openFile(pdfFile.path);
    final outputPdf = pw.Document();
    var totalHidden = 0;

    for (var i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      final rendered = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      if (rendered == null) continue;

      final pageBytes = rendered.bytes;
      final matches = await _detector.detect(
        bytes: pageBytes,
        filePath: await _writeTempPng(pageBytes),
        enabledKeys: enabledKeys,
        keywords: keywords,
        german: german,
      );
      totalHidden += matches.length;

      final maskedBytes = _maskPage(pageBytes, matches, style);
      outputPdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) =>
              pw.Center(child: pw.Image(pw.MemoryImage(maskedBytes))),
        ),
      );
    }

    await document.close();
    final file = await _writePdf(await outputPdf.save());
    return (file: file, hidden: totalHidden);
  }

  Uint8List _maskPage(Uint8List pngBytes, List<DetectionMatch> matches, MaskStyle style) {
    final image = img.decodePng(pngBytes)!;
    _masker.applyMasks(image, matches, style);
    return Uint8List.fromList(img.encodeJpg(image));
  }

  Future<String> _writeTempPng(Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File(
        '${dir.path}/page_${DateTime.now().microsecondsSinceEpoch}.png');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  Future<File> _writePdf(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/black_eye_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}

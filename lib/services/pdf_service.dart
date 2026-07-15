import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' hide PdfDocument;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdfx/pdfx.dart';

import '../models/detection_match.dart';
import '../models/mask_style.dart';
import 'detector_service.dart';
import 'image_masker.dart';

/// Scans a PDF the same way as an image: it turns every page into a picture,
/// finds and hides the sensitive parts, then builds a new protected PDF.
class PdfService {
  final DetectorService _detector;
  final ImageMasker _masker;

  PdfService(this._detector, this._masker);

  /// Processes [pdfFile] and returns the new protected PDF, along with how
  /// many sensitive items were hidden in total.
  Future<({File file, int hidden})> protectPdf(
    File pdfFile,
    Set<String> enabledKeys,
    List<String> keywords,
    MaskStyle style,
  ) async {
    final document = await PdfDocument.openFile(pdfFile.path);
    final outputPdf = pw.Document();
    var totalHidden = 0;

    for (var i = 1; i <= document.pagesCount; i++) {
      final page = await document.getPage(i);
      // Render at 2x so the text is sharp enough for OCR.
      final rendered = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      if (rendered == null) continue;

      final maskedBytes = await _maskPage(rendered.bytes, enabledKeys, keywords,
          style, (count) => totalHidden += count);

      outputPdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) => pw.Center(
            child: pw.Image(pw.MemoryImage(maskedBytes)),
          ),
        ),
      );
    }

    await document.close();
    final file = await _writePdf(await outputPdf.save());
    return (file: file, hidden: totalHidden);
  }

  /// Detects and hides sensitive areas on a single rendered page image.
  Future<Uint8List> _maskPage(
    Uint8List pngBytes,
    Set<String> enabledKeys,
    List<String> keywords,
    MaskStyle style,
    void Function(int) onHidden,
  ) async {
    // ML Kit needs a file, so write the page to a temporary image first.
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
        '${tempDir.path}/page_${DateTime.now().microsecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(pngBytes);

    final List<DetectionMatch> matches =
        await _detector.detect(tempFile, enabledKeys, keywords);
    onHidden(matches.length);

    final image = img.decodePng(pngBytes)!;
    _masker.applyMasks(image, matches, style);
    return Uint8List.fromList(img.encodeJpg(image));
  }

  Future<File> _writePdf(Uint8List bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(
        '${dir.path}/black_eye_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(bytes);
    return file;
  }
}

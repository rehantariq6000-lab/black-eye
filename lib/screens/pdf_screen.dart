import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';
import '../services/image_masker.dart';
import '../services/ocr/detector.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';

/// Lets the user pick a PDF, scans every page for sensitive information,
/// hides it, and produces a new protected PDF to share.
class PdfScreen extends StatefulWidget {
  const PdfScreen({super.key});

  @override
  State<PdfScreen> createState() => _PdfScreenState();
}

class _PdfScreenState extends State<PdfScreen> {
  final Detector _detector = createDetector();
  final SettingsService _settings = SettingsService();
  late final PdfService _pdfService = PdfService(_detector, ImageMasker());

  bool _busy = false;
  File? _resultPdf;
  int _hidden = 0;

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  Future<void> _pickAndProtect() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (path == null) return;

    setState(() {
      _busy = true;
      _resultPdf = null;
    });

    try {
      final enabledKeys = await _settings.loadEnabledKeys();
      final keywords = await _settings.loadKeywords();
      final style = await _settings.loadMaskStyle();

      final german = appLanguage.value == AppLanguage.german;
      final output = await _pdfService.protectPdf(
          File(path), enabledKeys, keywords, style, german);
      await _settings.addScanStats(output.hidden);

      setState(() {
        _resultPdf = output.file;
        _hidden = output.hidden;
      });
    } catch (e) {
      _showMessage('Could not process the PDF: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_resultPdf == null) return;
    await Share.shareXFiles([XFile(_resultPdf!.path)],
        text: 'Protected with Black Eye');
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.scanPdf)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(S.pdfIntro),
            const SizedBox(height: 24),
            if (_busy) const CircularProgressIndicator(),
            if (!_busy && _resultPdf != null)
              Column(
                children: [
                  const Icon(Icons.check_circle,
                      color: Colors.green, size: 48),
                  const SizedBox(height: 8),
                  Text(S.pdfDone(_hidden)),
                ],
              ),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(S.pickPdf),
              onPressed: _busy ? null : _pickAndProtect,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.share),
              label: Text(S.sharePdf),
              onPressed: (_resultPdf == null || _busy) ? null : _share,
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/app_strings.dart';
import '../models/detection_match.dart';
import '../models/mask_style.dart';
import '../services/export/exporter.dart';
import '../services/image_masker.dart';
import '../services/ocr/detector.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/gradient_background.dart';
import '../widgets/image_preview.dart';
import 'manual_blur_screen.dart';
import 'pdf_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// The main screen. The user picks an image, the app scans it, blurs the
/// sensitive parts, and lets the user compare, add manual blur, save, share.
///
/// Everything works on raw image bytes, so it runs the same on the web,
/// mobile and desktop.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final Detector _detector = createDetector();
  final ImageMasker _masker = ImageMasker();
  final Exporter _exporter = createExporter();
  final SettingsService _settings = SettingsService();

  Uint8List? _originalBytes;
  Uint8List? _maskedBytes;
  List<DetectionMatch> _matches = [];
  MaskStyle _maskStyle = MaskStyle.blur;
  bool _showOriginal = false;
  bool _busy = false;

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  bool get _de => appLanguage.value == AppLanguage.german;

  /// Full workflow: pick -> scan -> blur -> show.
  Future<void> _pickAndProtect(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _busy = true;
      _originalBytes = bytes;
      _maskedBytes = null;
      _showOriginal = false;
    });

    try {
      final enabledKeys = await _settings.loadEnabledKeys();
      final keywords = await _settings.loadKeywords();
      _maskStyle = await _settings.loadMaskStyle();

      _matches = await _detector.detect(
        bytes: bytes,
        filePath: picked.path.isEmpty ? null : picked.path,
        enabledKeys: enabledKeys,
        keywords: keywords,
        german: _de,
      );
      final masked = _masker.maskBytes(bytes, _matches, _maskStyle);
      await _settings.addScanStats(_matches.length);

      setState(() => _maskedBytes = masked);
    } catch (e) {
      _showMessage('${_de ? 'Fehler' : 'Something went wrong'}: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  /// Opens the manual-blur screen and re-masks with any boxes the user drew.
  Future<void> _addManualBlur() async {
    if (_originalBytes == null) return;
    final extra = await Navigator.of(context).push<List<DetectionMatch>>(
      MaterialPageRoute(
        builder: (_) => ManualBlurScreen(imageBytes: _originalBytes!),
      ),
    );
    if (extra == null || extra.isEmpty) return;

    setState(() => _busy = true);
    try {
      _matches = [..._matches, ...extra];
      final masked = _masker.maskBytes(_originalBytes!, _matches, _maskStyle);
      setState(() {
        _maskedBytes = masked;
        _showOriginal = false;
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_maskedBytes == null) return;
    await _exporter.share(_maskedBytes!, _fileName());
  }

  Future<void> _save() async {
    if (_maskedBytes == null) return;
    try {
      await _exporter.save(_maskedBytes!, _fileName());
      _showMessage(_de ? 'Gespeichert' : 'Saved');
    } catch (e) {
      _showMessage('${_de ? 'Fehler' : 'Could not save'}: $e');
    }
  }

  String _fileName() => 'black_eye_protected.jpg';

  void _openSettings() => _open(const SettingsScreen());
  void _openStats() => _open(const StatsScreen());
  void _openPdf() => _open(const PdfScreen());

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {}); // language may have changed
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        titleSpacing: 8,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 30),
            const SizedBox(width: 10),
            Text(S.appTitle),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: _openSettings),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'stats') _openStats();
              if (value == 'pdf') _openPdf();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'pdf', child: Text(S.scanPdf)),
              PopupMenuItem(value: 'stats', child: Text(S.privacyStats)),
            ],
          ),
        ],
      ),
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ImagePreview(
                    original: _originalBytes,
                    masked: _maskedBytes,
                    showOriginal: _showOriginal,
                    busy: _busy,
                  ),
                ),
                const SizedBox(height: 10),
                _buildOnDeviceBadge(),
                const SizedBox(height: 10),
                if (_maskedBytes != null) _buildResultBar(),
                const SizedBox(height: 12),
                _buildActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnDeviceBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 14, color: AppColors.accent),
        const SizedBox(width: 6),
        Text(S.onDeviceBadge,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    );
  }

  Widget _buildResultBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(S.itemsHidden(_matches.length),
                style: const TextStyle(fontWeight: FontWeight.bold)),
            TextButton.icon(
              icon: Icon(
                  _showOriginal ? Icons.visibility_off : Icons.visibility),
              label: Text(_showOriginal ? S.showProtected : S.showOriginal),
              onPressed: () => setState(() => _showOriginal = !_showOriginal),
            ),
          ],
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit),
          label: Text(S.addManualBlur),
          onPressed: _busy ? null : _addManualBlur,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final hasResult = _maskedBytes != null && !_busy;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.photo_library),
                label: Text(S.gallery),
                onPressed:
                    _busy ? null : () => _pickAndProtect(ImageSource.gallery),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.camera_alt),
                label: Text(S.camera),
                onPressed:
                    _busy ? null : () => _pickAndProtect(ImageSource.camera),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.download),
                label: Text(S.saveToGallery),
                onPressed: hasResult ? _save : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.share),
                label: Text(S.shareImage),
                onPressed: hasResult ? _share : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

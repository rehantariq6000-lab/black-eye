import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_strings.dart';
import '../models/detection_match.dart';
import '../models/mask_style.dart';
import '../services/detector_service.dart';
import '../services/image_masker.dart';
import '../services/settings_service.dart';
import '../widgets/image_preview.dart';
import 'manual_blur_screen.dart';
import 'pdf_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

/// The main screen. The user picks an image, the app scans it, blurs the
/// sensitive parts, and lets the user compare, add manual blur, save, share.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  final DetectorService _detector = DetectorService();
  final ImageMasker _masker = ImageMasker();
  final SettingsService _settings = SettingsService();

  File? _originalImage;
  File? _maskedImage;
  List<DetectionMatch> _matches = [];
  MaskStyle _maskStyle = MaskStyle.blur;
  bool _showOriginal = false;
  bool _busy = false;

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  /// Full workflow: pick -> scan -> blur -> show.
  Future<void> _pickAndProtect(ImageSource source) async {
    final picked = await _picker.pickImage(source: source);
    if (picked == null) return;

    setState(() {
      _busy = true;
      _originalImage = File(picked.path);
      _maskedImage = null;
      _showOriginal = false;
    });

    try {
      final enabledKeys = await _settings.loadEnabledKeys();
      final keywords = await _settings.loadKeywords();
      _maskStyle = await _settings.loadMaskStyle();

      _matches = await _detector.detect(_originalImage!, enabledKeys, keywords);
      final masked = await _masker.maskImage(_originalImage!, _matches, _maskStyle);
      await _settings.addScanStats(_matches.length);

      setState(() => _maskedImage = masked);
    } catch (e) {
      _showMessage('${_de ? 'Fehler' : 'Something went wrong'}: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  /// Opens the manual-blur screen and re-masks with any boxes the user drew.
  Future<void> _addManualBlur() async {
    if (_originalImage == null) return;
    final extra = await Navigator.of(context).push<List<DetectionMatch>>(
      MaterialPageRoute(builder: (_) => ManualBlurScreen(image: _originalImage!)),
    );
    if (extra == null || extra.isEmpty) return;

    setState(() => _busy = true);
    try {
      _matches = [..._matches, ...extra];
      final masked = await _masker.maskImage(_originalImage!, _matches, _maskStyle);
      setState(() {
        _maskedImage = masked;
        _showOriginal = false;
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _share() async {
    if (_maskedImage == null) return;
    await Share.shareXFiles([XFile(_maskedImage!.path)],
        text: 'Protected with Black Eye');
  }

  Future<void> _saveToGallery() async {
    if (_maskedImage == null) return;
    try {
      await Gal.putImage(_maskedImage!.path);
      _showMessage(S.savedToGallery);
    } catch (e) {
      _showMessage('${_de ? 'Fehler' : 'Could not save'}: $e');
    }
  }

  bool get _de => appLanguage.value == AppLanguage.german;

  void _openSettings() => _open(const SettingsScreen());
  void _openStats() => _open(const StatsScreen());
  void _openPdf() => _open(const PdfScreen());

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    // Language may have changed on the settings screen -> refresh this screen.
    if (mounted) setState(() {});
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.appTitle),
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: ImagePreview(
                original: _originalImage,
                masked: _maskedImage,
                showOriginal: _showOriginal,
                busy: _busy,
              ),
            ),
            const SizedBox(height: 12),
            if (_maskedImage != null) _buildResultBar(),
            const SizedBox(height: 12),
            _buildActionButtons(),
          ],
        ),
      ),
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
    final hasResult = _maskedImage != null && !_busy;
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
            // Saving to the gallery is a mobile feature (not available on web).
            if (!kIsWeb) ...[
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download),
                  label: Text(S.saveToGallery),
                  onPressed: hasResult ? _saveToGallery : null,
                ),
              ),
              const SizedBox(width: 12),
            ],
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

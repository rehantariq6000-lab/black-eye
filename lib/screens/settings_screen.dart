import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/detection_category.dart';
import '../models/mask_style.dart';
import '../services/settings_service.dart';

/// Lets the user choose the language, what Black Eye looks for (categories +
/// own keywords), and how it hides things (the mask style). Everything is
/// saved on device.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settings = SettingsService();
  final TextEditingController _keywordController = TextEditingController();

  Set<String> _enabledKeys = {};
  List<String> _keywords = [];
  MaskStyle _maskStyle = MaskStyle.blur;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final keys = await _settings.loadEnabledKeys();
    final keywords = await _settings.loadKeywords();
    final style = await _settings.loadMaskStyle();
    setState(() {
      _enabledKeys = keys;
      _keywords = keywords;
      _maskStyle = style;
      _loading = false;
    });
  }

  Future<void> _toggleCategory(String key, bool isOn) async {
    setState(() {
      isOn ? _enabledKeys.add(key) : _enabledKeys.remove(key);
    });
    await _settings.setEnabled(key, isOn);
  }

  Future<void> _addKeyword() async {
    final word = _keywordController.text.trim();
    if (word.isEmpty) return;
    await _settings.addKeyword(word);
    _keywordController.clear();
    setState(() => _keywords = List.of(_keywords)..add(word));
  }

  Future<void> _removeKeyword(String word) async {
    await _settings.removeKeyword(word);
    setState(() => _keywords = List.of(_keywords)..remove(word));
  }

  Future<void> _setMaskStyle(MaskStyle style) async {
    await _settings.setMaskStyle(style);
    setState(() => _maskStyle = style);
  }

  Future<void> _setLanguage(AppLanguage language) async {
    await _settings.setLanguageIndex(language.index);
    appLanguage.value = language;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.settings)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                _sectionTitle(S.language),
                _buildLanguagePicker(),
                const Divider(),
                _sectionTitle(S.whatToDetect),
                for (final category in kAllCategories)
                  SwitchListTile(
                    title: Text(S.categoryLabel(category.key)),
                    value: _enabledKeys.contains(category.key),
                    onChanged: (isOn) => _toggleCategory(category.key, isOn),
                  ),
                const Divider(),
                _sectionTitle(S.maskingStyle),
                for (final style in MaskStyle.values)
                  ListTile(
                    title: Text(style.label),
                    leading: Icon(_maskStyle == style
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked),
                    onTap: () => _setMaskStyle(style),
                  ),
                const Divider(),
                _sectionTitle(S.yourKeywords),
                _buildKeywordField(),
                _buildKeywordChips(),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(text,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildLanguagePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<AppLanguage>(
        segments: const [
          ButtonSegment(value: AppLanguage.english, label: Text('English')),
          ButtonSegment(value: AppLanguage.german, label: Text('Deutsch')),
        ],
        selected: {appLanguage.value},
        onSelectionChanged: (selection) => _setLanguage(selection.first),
      ),
    );
  }

  Widget _buildKeywordField() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _keywordController,
              decoration: InputDecoration(
                hintText: S.keywordHint,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addKeyword(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(icon: const Icon(Icons.add), onPressed: _addKeyword),
        ],
      ),
    );
  }

  Widget _buildKeywordChips() {
    if (_keywords.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(S.noKeywords, style: const TextStyle(color: Colors.grey)),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        children: [
          for (final word in _keywords)
            Chip(label: Text(word), onDeleted: () => _removeKeyword(word)),
        ],
      ),
    );
  }
}

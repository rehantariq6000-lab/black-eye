import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/detection_category.dart';
import '../models/mask_style.dart';
import '../models/shortcut.dart';
import '../services/settings_service.dart';
import '../theme.dart';

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

  Set<String> _enabledKeys = {};
  List<Shortcut> _shortcuts = [];
  MaskStyle _maskStyle = MaskStyle.blur;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final keys = await _settings.loadEnabledKeys();
    final shortcuts = await _settings.loadShortcuts();
    final style = await _settings.loadMaskStyle();
    setState(() {
      _enabledKeys = keys;
      _shortcuts = shortcuts;
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

  // ---- Shortcuts -----------------------------------------------------------

  Future<void> _saveShortcutDialog() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.saveShortcut),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(hintText: S.shortcutNameHint),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(S.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(S.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final shortcut = Shortcut(
      name: name,
      categoryKeys: _enabledKeys.toList(),
      maskStyleIndex: _maskStyle.index,
    );
    await _settings.saveShortcut(shortcut);
    final list = await _settings.loadShortcuts();
    setState(() => _shortcuts = list);
  }

  Future<void> _applyShortcut(Shortcut shortcut) async {
    await _settings.applyShortcut(shortcut);
    setState(() {
      _enabledKeys = shortcut.categoryKeys.toSet();
      _maskStyle = MaskStyle.fromIndex(shortcut.maskStyleIndex);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.shortcutApplied(shortcut.name))),
      );
    }
  }

  Future<void> _deleteShortcut(String name) async {
    await _settings.deleteShortcut(name);
    final list = await _settings.loadShortcuts();
    setState(() => _shortcuts = list);
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
                _buildDetectDropdown(),
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
                _sectionTitle(S.shortcuts),
                _buildShortcuts(),
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

  /// A collapsible dropdown of checkboxes. Ticking a box turns that category
  /// on; the scanner reads exactly this list, so what is ticked is what gets
  /// hidden.
  Widget _buildDetectDropdown() {
    final selected = _enabledKeys.length;
    final total = kAllCategories.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            leading: const Icon(Icons.shield_outlined, color: AppColors.accent),
            title: Text(S.whatToDetect),
            subtitle: Text('$selected / $total ${S.selectedLabel}',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              for (final category in kAllCategories)
                CheckboxListTile(
                  dense: true,
                  controlAffinity: ListTileControlAffinity.leading,
                  activeColor: AppColors.accent,
                  value: _enabledKeys.contains(category.key),
                  onChanged: (v) => _toggleCategory(category.key, v ?? false),
                  title: Text(S.categoryLabel(category.key)),
                ),
            ],
          ),
        ),
      ),
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

  Widget _buildShortcuts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(S.shortcutsHint,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        ),
        if (_shortcuts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(S.noShortcuts,
                style: const TextStyle(color: Colors.grey)),
          )
        else
          for (final shortcut in _shortcuts)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              child: Card(
                margin: EdgeInsets.zero,
                child: ListTile(
                  leading: const Icon(Icons.bolt, color: AppColors.accent),
                  title: Text(shortcut.name),
                  subtitle: Text(
                    '${shortcut.categoryKeys.length} ${S.selectedLabel} · '
                    '${MaskStyle.fromIndex(shortcut.maskStyleIndex).label}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _deleteShortcut(shortcut.name),
                  ),
                  onTap: () => _applyShortcut(shortcut),
                ),
              ),
            ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.add),
            label: Text(S.saveShortcut),
            onPressed: _saveShortcutDialog,
          ),
        ),
      ],
    );
  }
}

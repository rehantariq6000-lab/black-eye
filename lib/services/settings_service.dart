import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/detection_category.dart';
import '../models/mask_style.dart';
import '../models/shortcut.dart';

/// Stores everything Black Eye needs to remember between sessions:
/// which categories are on, the user's own keywords, the chosen mask style,
/// and simple privacy statistics. Uses shared_preferences (on-device).
class SettingsService {
  static const String _categoryPrefix = 'category_';
  static const String _keywordsKey = 'keywords';
  static const String _maskStyleKey = 'mask_style';
  static const String _imagesScannedKey = 'stats_images_scanned';
  static const String _itemsHiddenKey = 'stats_items_hidden';
  static const String _onboardedKey = 'onboarded';
  static const String _userNameKey = 'user_name';
  static const String _userDobKey = 'user_dob';
  static const String _languageKey = 'language';

  // ---- Onboarding / profile ------------------------------------------------

  /// True once the user has finished the welcome screens.
  Future<bool> isOnboarded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardedKey) ?? false;
  }

  /// Saves the user's name and date of birth and marks onboarding as done.
  Future<void> completeOnboarding(String name, String dateOfBirth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userNameKey, name);
    await prefs.setString(_userDobKey, dateOfBirth);
    await prefs.setBool(_onboardedKey, true);
  }

  Future<String> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey) ?? '';
  }

  // ---- Language ------------------------------------------------------------

  /// Loads the saved language index (0 = English, 1 = German).
  Future<int> loadLanguageIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_languageKey) ?? 0;
  }

  Future<void> setLanguageIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_languageKey, index);
  }

  // ---- Shortcuts (saved presets) -------------------------------------------

  static const String _shortcutsKey = 'shortcuts';

  Future<List<Shortcut>> loadShortcuts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shortcutsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Shortcut.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Adds or replaces a shortcut with the same name.
  Future<void> saveShortcut(Shortcut shortcut) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadShortcuts()
      ..removeWhere((s) => s.name == shortcut.name)
      ..add(shortcut);
    await prefs.setString(
        _shortcutsKey, jsonEncode(list.map((s) => s.toJson()).toList()));
  }

  Future<void> deleteShortcut(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await loadShortcuts()..removeWhere((s) => s.name == name);
    await prefs.setString(
        _shortcutsKey, jsonEncode(list.map((s) => s.toJson()).toList()));
  }

  /// Applies a shortcut: turns the listed categories on (others off) and sets
  /// the masking style, so the next scan uses exactly this preset.
  Future<void> applyShortcut(Shortcut shortcut) async {
    for (final category in kAllCategories) {
      await setEnabled(category.key, shortcut.categoryKeys.contains(category.key));
    }
    await setMaskStyle(MaskStyle.fromIndex(shortcut.maskStyleIndex));
  }

  // ---- Categories ----------------------------------------------------------

  /// Loads the set of enabled category keys. By default everything is on.
  Future<Set<String>> loadEnabledKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = <String>{};
    for (final category in kAllCategories) {
      final isOn = prefs.getBool('$_categoryPrefix${category.key}') ?? true;
      if (isOn) {
        enabled.add(category.key);
      }
    }
    return enabled;
  }

  Future<void> setEnabled(String key, bool isOn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_categoryPrefix$key', isOn);
  }

  // ---- Custom keywords -----------------------------------------------------

  Future<List<String>> loadKeywords() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keywordsKey) ?? [];
  }

  Future<void> addKeyword(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final words = prefs.getStringList(_keywordsKey) ?? [];
    final trimmed = word.trim();
    if (trimmed.isNotEmpty && !words.contains(trimmed)) {
      words.add(trimmed);
      await prefs.setStringList(_keywordsKey, words);
    }
  }

  Future<void> removeKeyword(String word) async {
    final prefs = await SharedPreferences.getInstance();
    final words = prefs.getStringList(_keywordsKey) ?? [];
    words.remove(word);
    await prefs.setStringList(_keywordsKey, words);
  }

  // ---- Mask style ----------------------------------------------------------

  Future<MaskStyle> loadMaskStyle() async {
    final prefs = await SharedPreferences.getInstance();
    return MaskStyle.fromIndex(prefs.getInt(_maskStyleKey));
  }

  Future<void> setMaskStyle(MaskStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_maskStyleKey, style.index);
  }

  // ---- Statistics ----------------------------------------------------------

  /// Adds one scanned file and [hidden] hidden items to the running totals.
  Future<void> addScanStats(int hidden) async {
    final prefs = await SharedPreferences.getInstance();
    final images = (prefs.getInt(_imagesScannedKey) ?? 0) + 1;
    final items = (prefs.getInt(_itemsHiddenKey) ?? 0) + hidden;
    await prefs.setInt(_imagesScannedKey, images);
    await prefs.setInt(_itemsHiddenKey, items);
  }

  Future<(int imagesScanned, int itemsHidden)> loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      prefs.getInt(_imagesScannedKey) ?? 0,
      prefs.getInt(_itemsHiddenKey) ?? 0,
    );
  }
}

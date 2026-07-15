import '../l10n/app_strings.dart';

/// The different ways Black Eye can hide a sensitive area.
enum MaskStyle {
  blur,
  pixelate,
  blackBox;

  /// A nice name to show in the UI (in the selected language).
  String get label {
    final german = appLanguage.value == AppLanguage.german;
    switch (this) {
      case MaskStyle.blur:
        return german ? 'Weichzeichnen' : 'Blur';
      case MaskStyle.pixelate:
        return german ? 'Verpixeln' : 'Pixelate';
      case MaskStyle.blackBox:
        return german ? 'Schwarzer Balken' : 'Black box';
    }
  }

  /// Turns a saved index back into a MaskStyle (defaults to blur).
  static MaskStyle fromIndex(int? index) {
    if (index == null || index < 0 || index >= MaskStyle.values.length) {
      return MaskStyle.blur;
    }
    return MaskStyle.values[index];
  }
}

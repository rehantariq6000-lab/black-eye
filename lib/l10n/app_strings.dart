import 'package:flutter/widgets.dart';

/// The languages Black Eye can show. English and German.
enum AppLanguage { english, german }

/// The language currently selected. Screens listen to this so they rebuild
/// (and re-read their text) the moment the user switches language.
final ValueNotifier<AppLanguage> appLanguage =
    ValueNotifier<AppLanguage>(AppLanguage.english);

/// All user-facing text, in both languages. `S.xxx` returns the right string
/// for whatever language is currently selected.
class S {
  static bool get _de => appLanguage.value == AppLanguage.german;

  static String _pick(String en, String de) => _de ? de : en;

  static String get appTitle => 'Black Eye';
  static String get pickImageHint =>
      _pick('Pick an image to protect', 'Bild zum Schützen auswählen');
  static String get gallery => _pick('Gallery', 'Galerie');
  static String get camera => _pick('Camera', 'Kamera');
  static String get shareImage =>
      _pick('Share protected image', 'Geschütztes Bild teilen');
  static String get sharePdf =>
      _pick('Share protected PDF', 'Geschütztes PDF teilen');
  static String get saveToGallery =>
      _pick('Save to gallery', 'In Galerie speichern');
  static String get savedToGallery =>
      _pick('Saved to your gallery', 'In Galerie gespeichert');
  static String itemsHidden(int n) =>
      _pick('$n item(s) hidden', '$n Element(e) versteckt');
  static String get showOriginal => _pick('Show original', 'Original anzeigen');
  static String get showProtected =>
      _pick('Show protected', 'Geschützt anzeigen');
  static String get addManualBlur =>
      _pick('Add manual blur', 'Manuell verdecken');

  static String get settings => _pick('Settings', 'Einstellungen');
  static String get whatToDetect => _pick('What to detect', 'Was erkennen');
  static String get maskingStyle => _pick('Masking style', 'Maskierungsstil');
  static String get yourKeywords =>
      _pick('Your own keywords', 'Eigene Schlüsselwörter');
  static String get keywordHint =>
      _pick('e.g. a name or project', 'z. B. ein Name oder Projekt');
  static String get noKeywords =>
      _pick('No keywords yet.', 'Noch keine Schlüsselwörter.');
  static String get language => _pick('Language', 'Sprache');

  static String get privacyStats =>
      _pick('Privacy statistics', 'Datenschutz-Statistik');
  static String get filesScanned => _pick('Files scanned', 'Dateien gescannt');
  static String get itemsHiddenStat =>
      _pick('Sensitive items hidden', 'Sensible Elemente versteckt');
  static String get statsNote => _pick(
      'Black Eye only stores these counts. No confidential data is ever saved.',
      'Black Eye speichert nur diese Zahlen. Es werden nie vertrauliche Daten gespeichert.');

  static String get scanPdf => _pick('Scan a PDF', 'PDF scannen');
  static String get pickPdf => _pick('Pick a PDF', 'PDF auswählen');
  static String get pdfIntro => _pick(
      'Pick a PDF and Black Eye will hide sensitive information on every page, '
          'then let you share the protected copy.',
      'Wähle ein PDF und Black Eye versteckt sensible Informationen auf jeder '
          'Seite und lässt dich die geschützte Kopie teilen.');
  static String pdfDone(int n) => _pick(
      'Done. $n item(s) hidden.', 'Fertig. $n Element(e) versteckt.');

  static String get manualBlurTitle =>
      _pick('Manual blur', 'Manuell verdecken');
  static String get manualBlurHint => _pick(
      'Drag over any area you want to hide.',
      'Ziehe über einen Bereich, den du verstecken möchtest.');
  static String get done => _pick('Done', 'Fertig');

  /// The display name of a detection category, by its key.
  static String categoryLabel(String key) {
    switch (key) {
      case 'email':
        return _pick('Email addresses', 'E-Mail-Adressen');
      case 'phone':
        return _pick('Phone numbers', 'Telefonnummern');
      case 'card':
        return _pick('Credit / debit card numbers',
            'Kredit-/Debitkartennummern');
      case 'iban':
        return _pick('Bank account / IBAN', 'Bankkonto / IBAN');
      case 'id':
        return _pick('ID / passport numbers', 'Ausweis-/Passnummern');
      case 'qr':
        return _pick('QR codes', 'QR-Codes');
      default:
        return key;
    }
  }
}

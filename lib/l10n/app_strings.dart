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
  static String get selectedLabel => _pick('selected', 'ausgewählt');
  static String get maskingStyle => _pick('Masking style', 'Maskierungsstil');
  static String get yourKeywords =>
      _pick('Your own keywords', 'Eigene Schlüsselwörter');
  static String get keywordHint =>
      _pick('e.g. a name or project', 'z. B. ein Name oder Projekt');
  static String get noKeywords =>
      _pick('No keywords yet.', 'Noch keine Schlüsselwörter.');

  // Shortcuts (saved presets)
  static String get shortcuts => _pick('Shortcuts', 'Schnellzugriffe');
  static String get shortcutsHint => _pick(
      'Save your current detection + masking settings, then apply them in one tap.',
      'Speichere deine aktuellen Einstellungen und wende sie mit einem Tipp an.');
  static String get saveShortcut =>
      _pick('Save current as shortcut', 'Aktuelle als Schnellzugriff speichern');
  static String get shortcutNameHint =>
      _pick('Shortcut name (e.g. Work docs)', 'Name (z. B. Arbeitsdokumente)');
  static String get noShortcuts =>
      _pick('No shortcuts yet.', 'Noch keine Schnellzugriffe.');
  static String get save => _pick('Save', 'Speichern');
  static String get cancel => _pick('Cancel', 'Abbrechen');
  static String shortcutApplied(String name) =>
      _pick('Applied "$name"', '„$name" angewendet');
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

  // ---- Onboarding ----------------------------------------------------------

  static String get welcomeTitle => _pick('Welcome to Black Eye', 'Willkommen bei Black Eye');
  static String get tagline => _pick('PRIVACY SCREENING', 'DATENSCHUTZ-PRÜFUNG');
  static String get nameLabel => _pick('Full name', 'Vollständiger Name');
  static String get dobLabel => _pick('Date of birth', 'Geburtsdatum');
  static String get day => _pick('Day', 'Tag');
  static String get month => _pick('Month', 'Monat');
  static String get year => _pick('Year', 'Jahr');
  static String get continueLabel => _pick('Continue', 'Weiter');
  static String get fillDetailsError => _pick(
      'Please enter your name and full date of birth.',
      'Bitte geben Sie Ihren Namen und Ihr vollständiges Geburtsdatum ein.');
  static String get profileIntro => _pick(
      'Set up your profile to get started. Your details stay on this device.',
      'Richten Sie Ihr Profil ein. Ihre Daten bleiben auf diesem Gerät.');

  static List<String> get months => _de
      ? const [
          'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli',
          'August', 'September', 'Oktober', 'November', 'Dezember'
        ]
      : const [
          'January', 'February', 'March', 'April', 'May', 'June', 'July',
          'August', 'September', 'October', 'November', 'December'
        ];

  // ---- Privacy agreement (GDPR / DSGVO) ------------------------------------

  static String get privacyTitle =>
      _pick('Privacy Agreement', 'Datenschutzvereinbarung');
  static String get privacySubtitle => _pick(
      'Compliant with the EU General Data Protection Regulation (GDPR).',
      'Konform mit der EU-Datenschutz-Grundverordnung (DSGVO).');
  static String get privacyConsent => _pick(
      'I have read and understood this privacy notice and agree to it.',
      'Ich habe diese Datenschutzhinweise gelesen, verstanden und stimme ihnen zu.');
  static String get iAgree => _pick('I agree and continue', 'Zustimmen und fortfahren');

  /// The privacy notice as a list of (heading, body) sections.
  static List<(String, String)> get privacySections => _de
      ? const [
          ('1. Verarbeitung auf dem Gerät',
              'Die gesamte Analyse von Bildern und Dokumenten erfolgt ausschließlich lokal auf Ihrem Gerät. Ihre Dateien werden niemals auf einen Server oder in eine Cloud hochgeladen.'),
          ('2. Keine Datenerfassung',
              'Wir erfassen, speichern oder übermitteln keine personenbezogenen Daten. Black Eye verwendet keine Benutzerkonten, keine Werbung und kein Tracking.'),
          ('3. Anonyme Statistiken',
              'Es werden lediglich anonyme Zähler (gescannte Dateien, versteckte Elemente) lokal auf Ihrem Gerät gespeichert. Diese verlassen das Gerät zu keinem Zeitpunkt.'),
          ('4. Rechtsgrundlage (Art. 6 DSGVO)',
              'Da keine personenbezogenen Daten an uns übertragen oder von uns verarbeitet werden, entsteht kein Verantwortlichenverhältnis im Sinne von Art. 4 DSGVO. Die Verarbeitung auf Ihrem Gerät unterliegt allein Ihrer Kontrolle.'),
          ('5. Ihre Rechte',
              'Sie behalten jederzeit die vollständige Kontrolle über Ihre Daten. Durch Deinstallation der App werden alle lokal gespeicherten Daten unwiderruflich gelöscht.'),
        ]
      : const [
          ('1. On-device processing',
              'All analysis of images and documents happens locally on your device. Your files are never uploaded to any server or cloud.'),
          ('2. No data collection',
              'We do not collect, store, or transmit any personal data. Black Eye has no user accounts, no advertising, and no tracking.'),
          ('3. Anonymous statistics',
              'Only anonymous counters (files scanned, items hidden) are stored locally on your device. They never leave it.'),
          ('4. Legal basis (Art. 6 GDPR)',
              'Because no personal data is transmitted to or processed by us, no data-controller relationship arises under Art. 4 GDPR. Processing on your device is under your sole control.'),
          ('5. Your rights',
              'You remain in full control of your data at all times. Uninstalling the app permanently deletes all locally stored data.'),
        ];

  // ---- Home footer ---------------------------------------------------------

  static String get onDeviceBadge =>
      _pick('On-device · Nothing is uploaded', 'Auf dem Gerät · Nichts wird hochgeladen');

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
      case 'ssn':
        return _pick('Social security numbers', 'Sozialversicherungsnummern');
      case 'iban':
        return _pick('Bank account / IBAN', 'Bankkonto / IBAN');
      case 'id':
        return _pick('ID / passport numbers', 'Ausweis-/Passnummern');
      case 'address':
        return _pick('Postal addresses', 'Postanschriften');
      case 'qr':
        return _pick('QR codes', 'QR-Codes');
      default:
        return key;
    }
  }
}

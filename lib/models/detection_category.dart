/// The different kinds of sensitive information Black Eye can look for.
///
/// Each category has a [key] (used to save the on/off setting), a [label]
/// shown in the UI, a [pattern] (regular expression) used to find this kind of
/// data in the OCR text, and an optional [validate] check to reject false
/// positives (e.g. a "phone number" must actually contain enough digits).
class DetectionCategory {
  final String key;
  final String label;
  final RegExp pattern;
  final bool Function(String match)? validate;

  const DetectionCategory({
    required this.key,
    required this.label,
    required this.pattern,
    this.validate,
  });
}

/// The settings key used for QR-code detection (handled by the detector, not
/// by a regular expression).
const String kQrKey = 'qr';

int _digits(String s) => s.replaceAll(RegExp(r'\D'), '').length;

/// All categories the app supports. Patterns are deliberately generous so
/// that real-world formats (spaces, dashes, brackets) are still caught.
final List<DetectionCategory> kAllCategories = [
  DetectionCategory(
    key: 'email',
    label: 'Email addresses',
    pattern: RegExp(r'[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}'),
  ),
  DetectionCategory(
    key: 'phone',
    label: 'Phone numbers',
    // A run of digits with the usual phone punctuation: + ( ) space - .
    pattern: RegExp(r'(?:\+?\d[\d\s().\-]{6,}\d)'),
    validate: (m) {
      final d = _digits(m);
      return d >= 7 && d <= 15;
    },
  ),
  DetectionCategory(
    key: 'card',
    label: 'Credit / debit card numbers',
    // 13–19 digits, optionally split into groups by spaces or dashes.
    pattern: RegExp(r'\d(?:[ \-]?\d){12,18}'),
    validate: (m) {
      final d = _digits(m);
      return d >= 13 && d <= 19;
    },
  ),
  DetectionCategory(
    key: 'ssn',
    label: 'Social security numbers',
    pattern: RegExp(r'\b\d{3}-\d{2}-\d{4}\b'),
  ),
  DetectionCategory(
    key: 'iban',
    label: 'Bank account / IBAN',
    // Two letters, two digits, then 10–30 more chars that may be spaced.
    pattern: RegExp(r'\b[A-Z]{2}\d{2}(?:\s?[A-Z0-9]){10,30}\b'),
  ),
  DetectionCategory(
    key: 'id',
    label: 'ID / passport numbers',
    // Passport / ID formats: letters+digits, grouped license numbers, or an
    // 8–9 char uppercase code that mixes letters and digits (e.g. L01X00T47).
    pattern: RegExp(
        r'\b(?:[A-Z]{1,2}\d{6,9}'
        r'|[A-Z]?\d{3}[- ]\d{3}[- ]\d{3}(?:[- ]\d{2,4})?'
        r'|(?=[A-Z0-9]*[A-Z])(?=[A-Z0-9]*\d)[A-Z0-9]{8,9})\b'),
  ),
  DetectionCategory(
    key: 'address',
    label: 'Postal addresses',
    // A street line (number + name + street type, EN & DE) or a city/ZIP line.
    pattern: RegExp(
      r'\b\d{1,6}\s+\w+(?:\s+\w+){0,4}\s+(?:street|st|avenue|ave|drive|dr|road|rd|lane|ln|boulevard|blvd|court|ct|way|place|pl|terrace|ter|strasse|straße|str|weg|allee|platz|gasse|ring)\b'
      r'|[A-Za-z.\-]+,\s*[A-Za-z]{2}\s*\d{5}(?:-\d{4})?'
      r'|\b\d{4,5}\s+[A-Za-zÀ-ſ]{3,}',
      caseSensitive: false,
    ),
  ),
  DetectionCategory(
    key: kQrKey,
    label: 'QR codes',
    pattern: RegExp(r'(?!x)x'), // never matches text; handled by the detector
  ),
];

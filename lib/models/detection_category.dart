/// The different kinds of sensitive information Black Eye can look for.
///
/// Each category has a [key] (used to save the on/off setting), a [label]
/// shown in the UI, and a [pattern] (a regular expression) used to find
/// this kind of data inside the text that OCR reads from the image.
class DetectionCategory {
  final String key;
  final String label;
  final RegExp pattern;

  const DetectionCategory({
    required this.key,
    required this.label,
    required this.pattern,
  });
}

/// The settings key used for QR-code detection. QR codes are not found with
/// a regular expression, so they are handled separately in DetectorService,
/// but they still have an on/off switch like the other categories.
const String kQrKey = 'qr';

/// All categories the app supports. This is the single place to add or
/// change detection rules.
final List<DetectionCategory> kAllCategories = [
  DetectionCategory(
    key: 'email',
    label: 'Email addresses',
    pattern: RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'),
  ),
  DetectionCategory(
    key: 'phone',
    label: 'Phone numbers',
    pattern: RegExp(r'(\+?\d[\d\s\-]{7,}\d)'),
  ),
  DetectionCategory(
    key: 'card',
    label: 'Credit / debit card numbers',
    // 13 to 16 digits, possibly split by spaces or dashes.
    pattern: RegExp(r'\b(?:\d[ -]?){13,16}\b'),
  ),
  DetectionCategory(
    key: 'iban',
    label: 'Bank account / IBAN',
    pattern: RegExp(r'\b[A-Z]{2}\d{2}[A-Z0-9]{10,30}\b'),
  ),
  DetectionCategory(
    key: 'id',
    label: 'ID / passport numbers',
    pattern: RegExp(r'\b[A-Z]{1,2}\d{6,8}\b'),
  ),
  DetectionCategory(
    key: kQrKey,
    label: 'QR codes',
    // QR codes are detected by ML Kit barcode scanning, not by this pattern,
    // so we use one that never matches any text.
    pattern: RegExp(r'(?!x)x'),
  ),
];

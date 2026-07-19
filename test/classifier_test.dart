import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:black_eye/models/detection_category.dart';
import 'package:black_eye/services/ocr/classifier.dart';
import 'package:black_eye/services/ocr/ocr_models.dart';

/// Builds an OcrLine from words, giving each word a fake box. This mimics what
/// the OCR engines return so we can test the detection rules directly.
OcrLine line(String text) {
  final parts = text.split(' ');
  var x = 0.0;
  final words = <OcrWord>[];
  for (final p in parts) {
    words.add(OcrWord(p, Rect.fromLTWH(x, 0, p.length * 10.0, 20)));
    x += p.length * 10.0 + 10;
  }
  return OcrLine(text, words);
}

void main() {
  final allKeys = kAllCategories.map((c) => c.key).toSet();

  // Each of these real-world values must produce at least one blur box.
  final samples = <String, String>{
    'card (spaced)': '5412 7512 3412 3456',
    'card (joined)': '5412751234123456',
    'email': 'rehan.tariq@mail.com',
    'phone (US)': '(512) 555-0198',
    'phone (intl)': '+49 170 1234567',
    'ssn': '478-63-7291',
    'iban (spaced)': 'DE89 3704 0044 0532',
    'id / license': 'S123-456-789-012',
    'passport': 'L01X00T47',
    'street address': '1234 Oakridge Drive',
    'city / zip': 'Austin, TX 78748',
    'german zip': '10115 Berlin',
  };

  samples.forEach((name, value) {
    test('detects $name', () {
      final matches = classifyLines([line('Value: $value')], allKeys, const []);
      expect(matches, isNotEmpty, reason: '"$value" ($name) was not detected');
    });
  });

  test('respects settings: disabled category is not hidden', () {
    // Only email enabled -> a card number should NOT be blurred.
    final matches = classifyLines([line('Card 5412 7512 3412 3456')], {'email'}, const []);
    expect(matches, isEmpty);
  });

  test('custom keyword is hidden', () {
    final matches = classifyLines([line('Project Titan is secret')], allKeys, ['Titan']);
    expect(matches, isNotEmpty);
  });

  // Values taken straight from the demo ID / card / statement image.
  final demo = <String, String>{
    'DL number': 'S123-456-789-012',
    'DOB slashes': '04/22/1998',
    'DOB written': 'April 22, 1998',
    'DD long number': '12345678901234567890',
    'account number': '876543210',
    'email w/ digits': 'rehan.tariq98@examplemail.com',
  };
  demo.forEach((name, value) {
    test('demo image: $name', () {
      final m = classifyLines([line('Field: $value')], allKeys, const []);
      expect(m, isNotEmpty, reason: '"$value" ($name) missed');
    });
  });

  test('demo image: inline name label is hidden', () {
    final m = classifyLines([line('Full Name: Rehan Alexander Tariq')], allKeys, const []);
    expect(m.length, greaterThanOrEqualTo(3)); // Rehan, Alexander, Tariq
  });

  test('demo image: LN / FN license names are hidden', () {
    final m = classifyLines([line('LN TARIQ'), line('FN REHAN ALEXANDER')], allKeys, const []);
    expect(m.length, greaterThanOrEqualTo(3));
  });

  test('demo image: cardholder name after CARD HOLDER label', () {
    final m = classifyLines([line('CARD HOLDER'), line('REHAN A. TARIQ')], allKeys, const []);
    expect(m, isNotEmpty);
  });

  test('does not blur document headers', () {
    final m = classifyLines([line('PERSONAL INFORMATION'), line('ACCOUNT STATEMENT')], allKeys, const []);
    expect(m, isEmpty);
  });
}

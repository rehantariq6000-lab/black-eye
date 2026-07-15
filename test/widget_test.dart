import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:black_eye/main.dart';

void main() {
  testWidgets('First launch shows the welcome screen', (tester) async {
    // Pretend this is a fresh install (no saved settings).
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const BlackEyeApp());
    await tester.pumpAndSettle();

    // The onboarding asks for the user's name.
    expect(find.byType(TextField), findsWidgets);
    expect(find.text('Continue'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/settings_service.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore the saved language before the app is shown.
  final settings = SettingsService();
  final languageIndex = await settings.loadLanguageIndex();
  appLanguage.value = AppLanguage.values[languageIndex];

  runApp(const BlackEyeApp());
}

/// Black Eye - Intelligent Privacy Protection System.
///
/// Scans images and PDFs with on-device OCR, finds sensitive information such
/// as card numbers or emails, and blurs it before the content is shared.
class BlackEyeApp extends StatelessWidget {
  const BlackEyeApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app when the language changes so every screen updates.
    return ValueListenableBuilder<AppLanguage>(
      valueListenable: appLanguage,
      builder: (context, _, __) {
        return MaterialApp(
          title: 'Black Eye',
          debugShowCheckedModeBanner: false,
          theme: buildAppTheme(),
          home: const _StartupGate(),
        );
      },
    );
  }
}

/// Decides whether to show the welcome flow or go straight to the app.
class _StartupGate extends StatelessWidget {
  const _StartupGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: SettingsService().isOnboarded(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        return snapshot.data! ? const HomeScreen() : const OnboardingScreen();
      },
    );
  }
}

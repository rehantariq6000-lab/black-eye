import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import 'home_screen.dart';

/// The welcome flow shown the first time the app is opened:
/// 1. Logo + name and date of birth
/// 2. Privacy agreement
/// After agreeing, the user goes to the main app.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final SettingsService _settings = SettingsService();
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();

  DateTime? _dateOfBirth;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _de => appLanguage.value == AppLanguage.german;

  void _goToPrivacy() {
    if (_nameController.text.trim().isEmpty || _dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_de
                ? 'Bitte Namen und Geburtsdatum eingeben.'
                : 'Please enter your name and date of birth.')),
      );
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
    );
    if (picked != null) setState(() => _dateOfBirth = picked);
  }

  Future<void> _agreeAndFinish() async {
    final dob = _dateOfBirth!;
    final dobText = '${dob.day}.${dob.month}.${dob.year}';
    await _settings.completeOnboarding(_nameController.text.trim(), dobText);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildProfilePage(),
            _buildPrivacyPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfilePage() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),
          const AppLogo(size: 140),
          const SizedBox(height: 16),
          Text(
            _de ? 'Willkommen bei Black Eye' : 'Welcome to Black Eye',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            _de ? 'Datenschutz-Prüfung' : 'Privacy Screening',
            style: const TextStyle(color: AppColors.accent, letterSpacing: 2),
          ),
          const SizedBox(height: 36),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: _de ? 'Name' : 'Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: _de ? 'Geburtsdatum' : 'Date of birth',
                prefixIcon: const Icon(Icons.cake_outlined),
                border: const OutlineInputBorder(),
              ),
              child: Text(
                _dateOfBirth == null
                    ? (_de ? 'Tippen zum Auswählen' : 'Tap to select')
                    : '${_dateOfBirth!.day}.${_dateOfBirth!.month}.${_dateOfBirth!.year}',
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: _goToPrivacy,
            child: Text(_de ? 'Weiter' : 'Continue'),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPage() {
    final points = _de
        ? [
            'Alle Verarbeitung geschieht auf deinem Gerät.',
            'Es werden keine Bilder oder sensiblen Daten hochgeladen.',
            'Es werden nur anonyme Statistiken gespeichert.',
          ]
        : [
            'All processing happens on your device.',
            'No images or sensitive data are ever uploaded.',
            'Only anonymous statistics are stored.',
          ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const AppLogo(size: 80),
          const SizedBox(height: 24),
          Text(
            _de ? 'Datenschutzvereinbarung' : 'Privacy agreement',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle,
                      color: AppColors.accent, size: 22),
                  const SizedBox(width: 12),
                  Expanded(child: Text(point, style: const TextStyle(fontSize: 15))),
                ],
              ),
            ),
          const Spacer(),
          FilledButton.icon(
            icon: const Icon(Icons.verified_user),
            label: Text(_de ? 'Ich stimme zu' : 'I agree'),
            onPressed: _agreeAndFinish,
          ),
        ],
      ),
    );
  }
}

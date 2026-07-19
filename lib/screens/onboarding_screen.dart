import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart';
import '../theme.dart';
import '../widgets/app_logo.dart';
import '../widgets/gradient_background.dart';
import 'home_screen.dart';

/// The welcome flow shown the first time the app is opened:
/// 1. Logo + name and date of birth (Day / Month / Year selectors)
/// 2. A professional, GDPR/DSGVO-compliant privacy agreement
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

  int? _day;
  int? _month; // 1-12
  int? _year;
  int _page = 0;
  bool _agreed = false;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _profileComplete =>
      _nameController.text.trim().isNotEmpty &&
      _day != null &&
      _month != null &&
      _year != null;

  void _goToPrivacy() {
    if (!_profileComplete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.fillDetailsError)),
      );
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _agreeAndFinish() async {
    final dob = '$_day.$_month.$_year';
    await _settings.completeOnboarding(_nameController.text.trim(), dob);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildProgressDots(),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _buildProfilePage(),
                    _buildPrivacyPage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(2, (i) {
        final active = i == _page;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? AppColors.accent : Colors.white24,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  // ---- Page 1: profile -----------------------------------------------------

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 12),
          const Center(child: AppLogo(size: 150)),
          const SizedBox(height: 24),
          Text(
            S.welcomeTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            S.tagline,
            textAlign: TextAlign.center,
            style: const TextStyle(
                color: AppColors.accent, letterSpacing: 4, fontSize: 12),
          ),
          const SizedBox(height: 28),
          Text(S.profileIntro,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: S.nameLabel,
              prefixIcon: const Icon(Icons.person_outline),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          Text(S.dobLabel,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: AppColors.silver)),
          const SizedBox(height: 8),
          _buildDobSelectors(),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: _profileComplete ? _goToPrivacy : null,
            child: Text(S.continueLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildDobSelectors() {
    final now = DateTime.now();
    final daysInMonth = (_year != null && _month != null)
        ? DateTime(_year!, _month! + 1, 0).day
        : 31;

    return Row(
      children: [
        // Day
        Expanded(
          flex: 3,
          child: _dropdown<int>(
            hint: S.day,
            value: _day,
            items: [
              for (var d = 1; d <= daysInMonth; d++)
                DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: (v) => setState(() => _day = v),
          ),
        ),
        const SizedBox(width: 8),
        // Month
        Expanded(
          flex: 4,
          child: _dropdown<int>(
            hint: S.month,
            value: _month,
            items: [
              for (var m = 1; m <= 12; m++)
                DropdownMenuItem(value: m, child: Text(S.months[m - 1])),
            ],
            onChanged: (v) => setState(() => _month = v),
          ),
        ),
        const SizedBox(width: 8),
        // Year
        Expanded(
          flex: 3,
          child: _dropdown<int>(
            hint: S.year,
            value: _year,
            items: [
              for (var y = now.year; y >= now.year - 100; y--)
                DropdownMenuItem(value: y, child: Text('$y')),
            ],
            onChanged: (v) => setState(() => _year = v),
          ),
        ),
      ],
    );
  }

  Widget _dropdown<T>({
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      hint: Text(hint),
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      items: items,
      onChanged: onChanged,
    );
  }

  // ---- Page 2: privacy -----------------------------------------------------

  Widget _buildPrivacyPage() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.verified_user, color: AppColors.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(S.privacyTitle,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(S.privacySubtitle,
                    style: const TextStyle(color: AppColors.accent, fontSize: 13)),
                const SizedBox(height: 20),
                for (final section in S.privacySections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(section.$1,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.silver,
                                fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(section.$2,
                            style: const TextStyle(
                                color: AppColors.textMuted, height: 1.4)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Consent bar pinned at the bottom.
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() => _agreed = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.accent,
                title: Text(S.privacyConsent,
                    style: const TextStyle(fontSize: 13)),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                icon: const Icon(Icons.check),
                label: Text(S.iAgree),
                onPressed: _agreed ? _agreeAndFinish : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

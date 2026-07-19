import 'package:flutter/material.dart';

import '../theme.dart';

/// A subtle dark gradient used behind the main screens to give the app a
/// polished, professional feel (a hint of the logo's purple at the top).
class GradientBackground extends StatelessWidget {
  final Widget child;

  const GradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A1730), // deep purple-tinted top
            AppColors.background,
            Color(0xFF050506),
          ],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: child,
    );
  }
}

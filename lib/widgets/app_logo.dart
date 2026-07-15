import 'package:flutter/material.dart';

import '../theme.dart';

/// Shows the Black Eye logo.
///
/// If the logo image (assets/logo.png) has not been added yet, it falls back
/// to a simple eye icon so the app still looks right.
class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        'assets/logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      ),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(size * 0.22),
        border: Border.all(color: AppColors.silver, width: 2),
      ),
      child: Icon(Icons.remove_red_eye_outlined,
          size: size * 0.5, color: AppColors.silver),
    );
  }
}

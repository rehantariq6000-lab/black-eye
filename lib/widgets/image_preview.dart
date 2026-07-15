import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme.dart';
import 'app_logo.dart';

/// Shows the picked image in the middle of the screen.
///
/// Before anything is picked it shows a friendly placeholder. While the
/// app is working it shows a spinner. After scanning it shows either the
/// protected image or the original, depending on [showOriginal].
class ImagePreview extends StatelessWidget {
  final File? original;
  final File? masked;
  final bool showOriginal;
  final bool busy;

  const ImagePreview({
    super.key,
    required this.original,
    required this.masked,
    required this.showOriginal,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (busy) {
      return const Center(child: CircularProgressIndicator());
    }

    if (original == null) {
      return const _Placeholder();
    }

    // Show the original only if asked and we actually have a masked version.
    final fileToShow =
        (showOriginal || masked == null) ? original! : masked!;
    return Center(child: Image.file(fileToShow, fit: BoxFit.contain));
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLogo(size: 96),
          const SizedBox(height: 16),
          Text(
            S.pickImageHint,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

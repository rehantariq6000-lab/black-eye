import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../services/settings_service.dart';

/// Shows simple privacy statistics: how many files were scanned and how many
/// sensitive items were hidden. Only these numbers are stored, never the
/// confidential data itself.
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  final SettingsService _settings = SettingsService();

  int _imagesScanned = 0;
  int _itemsHidden = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final (images, items) = await _settings.loadStats();
    setState(() {
      _imagesScanned = images;
      _itemsHidden = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(S.privacyStats)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _StatCard(
                    icon: Icons.image_search,
                    value: _imagesScanned,
                    label: S.filesScanned,
                  ),
                  const SizedBox(height: 16),
                  _StatCard(
                    icon: Icons.visibility_off,
                    value: _itemsHidden,
                    label: S.itemsHiddenStat,
                  ),
                  const Spacer(),
                  Text(
                    S.statsNote,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _StatCard({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$value',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold)),
                Text(label, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

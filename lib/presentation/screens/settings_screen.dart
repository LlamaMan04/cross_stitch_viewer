import 'package:flutter/material.dart';

import '../../domain/repositories.dart';
import '../../app/test_patterns/extra_large_sample_pattern_fixture.dart';
import '../../app/test_patterns/large_sample_pattern_fixture.dart';
import '../../app/test_patterns/sample_pattern_fixture.dart';

/// Basic application settings and product information screen.
class SettingsScreen extends StatefulWidget {
  /// Creates the settings screen.
  const SettingsScreen({
    required this.patternDocuments,
    this.onSamplePatternsLoaded,
    super.key,
  });

  /// Repository receiving the explicitly requested sample pattern upserts.
  final PatternDocumentRepository patternDocuments;

  /// Notifies the navigation shell so its mounted library reloads.
  final VoidCallback? onSamplePatternsLoaded;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoadingSamples = false;

  Future<void> _loadSamplePatterns() async {
    setState(() => _isLoadingSamples = true);
    try {
      for (final document in [
        SamplePatternFixture.create(),
        LargeSamplePatternFixture.create(),
        ExtraLargeSamplePatternFixture.create(),
      ]) {
        await widget.patternDocuments.save(document);
      }
      widget.onSamplePatternsLoaded?.call();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Sample patterns loaded.')),
        );
    } finally {
      if (mounted) setState(() => _isLoadingSamples = false);
    }
  }

  /// Builds the current settings list.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About StitchScope'),
            subtitle: Text('A home for your cross-stitch patterns.'),
          ),
          ListTile(
            leading: const Icon(Icons.auto_awesome),
            title: const Text('Sample patterns'),
            subtitle: const Text(
              'Add the built-in sample patterns to your library.',
            ),
            trailing: FilledButton(
              key: const ValueKey('load-sample-patterns'),
              onPressed: _isLoadingSamples ? null : _loadSamplePatterns,
              child: _isLoadingSamples
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Load'),
            ),
          ),
        ],
      ),
    );
  }
}

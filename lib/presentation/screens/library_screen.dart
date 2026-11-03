import 'package:flutter/material.dart';

/// Empty-state library screen and entry point for future pattern imports.
class LibraryScreen extends StatelessWidget {
  /// Creates the pattern library screen.
  const LibraryScreen({super.key});

  /// Builds the library empty state and import affordances.
  @override
  Widget build(BuildContext context) {
    // Theme colors keep the empty state consistent with app-level theming.
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pattern Library'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: () => _showImportComingSoon(context),
              icon: const Icon(Icons.add),
              label: const Text('Import pattern'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: colors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.grid_on_rounded,
                    size: 48,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Your pattern library starts here',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'Import a cross-stitch pattern to view its grid, symbols, and thread details.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge
                      ?.copyWith(color: colors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => _showImportComingSoon(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Import a pattern'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows temporary feedback until pattern import is implemented.
  void _showImportComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Pattern importing is coming soon.')),
      );
  }
}

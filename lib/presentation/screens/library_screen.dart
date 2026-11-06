import 'package:flutter/material.dart';

import '../../domain/pattern_document.dart';
import '../../domain/repositories.dart';
import 'pattern_workspace_screen.dart';

/// Lists persisted patterns and upserts configured development fixtures.
class LibraryScreen extends StatefulWidget {
  /// Creates a pattern library screen over the supplied document repository.
  const LibraryScreen({
    required this.patternDocuments,
    required this.progress,
    this.seedDocuments = const [],
    this.seedDocument,
    super.key,
  });

  /// Repository providing document summaries and selected documents.
  final PatternDocumentRepository patternDocuments;

  /// Repository providing mutable viewport and render settings.
  final ProgressRepository progress;

  /// Documents used to repopulate the library when seeding is configured.
  final List<PatternDocument> seedDocuments;

  /// Legacy single-document seed accepted by focused tests and callers.
  final PatternDocument? seedDocument;

  /// Creates state that loads the library once while this screen remains mounted.
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

/// Manages the asynchronous library summary query and seed replacement.
class _LibraryScreenState extends State<LibraryScreen> {
  /// Pending library load retained across rebuilds.
  late Future<List<PatternSummary>> _summaries;

  @override
  void initState() {
    super.initState();
    _summaries = _loadSummaries();
  }

  /// Upserts configured seed documents without deleting their progress graphs.
  Future<List<PatternSummary>> _loadSummaries() async {
    final summaries = await widget.patternDocuments.listSummaries();
    final seeds = [...widget.seedDocuments];
    final seed = widget.seedDocument;
    if (seed != null) seeds.add(seed);
    if (seeds.isEmpty) return summaries;

    for (final seed in seeds) {
      await widget.patternDocuments.save(seed);
    }
    return widget.patternDocuments.listSummaries();
  }

  /// Requeries the library after an operation that changes its contents.
  void _reload() => setState(() => _summaries = _loadSummaries());

  /// Builds loading, empty, error, and populated library states.
  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder<List<PatternSummary>>(
        future: _summaries,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _LibraryError(onRetry: _reload, error: snapshot.error!);
          }
          final summaries = snapshot.requireData;
          // A seeded test pattern is a real library item, even when it is the
          // only item on a fresh run.
          if (summaries.isEmpty) {
            return _LibraryEmpty(
              onImport: () => _showImportComingSoon(context),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: summaries.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) => _PatternSummaryTile(
              summary: summaries[index],
              onOpen: () => _openWorkspace(summaries[index]),
            ),
          );
        },
      ),
    );
  }

  /// Opens the selected persisted document's placeholder workspace.
  void _openWorkspace(PatternSummary summary) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PatternWorkspaceScreen(
          documentId: summary.id,
          patternDocuments: widget.patternDocuments,
          progress: widget.progress,
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

/// Shows the current empty-library guidance and import affordance.
class _LibraryEmpty extends StatelessWidget {
  /// Creates an empty-library state with an import action.
  const _LibraryEmpty({required this.onImport});

  /// Callback used by the empty-state import button.
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
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
                onPressed: onImport,
                icon: const Icon(Icons.add),
                label: const Text('Import a pattern'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a recoverable library loading error.
class _LibraryError extends StatelessWidget {
  /// Creates an error state with a retry action.
  const _LibraryError({required this.onRetry, required this.error});

  /// Reload callback used by the retry button.
  final VoidCallback onRetry;

  /// Failure surfaced by the repository query.
  final Object error;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Unable to load your pattern library.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}

/// Displays one persisted pattern summary as a selectable library row.
class _PatternSummaryTile extends StatelessWidget {
  /// Creates a row that opens [summary] when selected.
  const _PatternSummaryTile({required this.summary, required this.onOpen});

  /// Display-ready document metadata.
  final PatternSummary summary;

  /// Callback used to open the selected document.
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      onTap: onOpen,
      leading: const Icon(Icons.grid_on_outlined),
      title: Text(summary.title),
      subtitle: Text('${summary.rows} rows × ${summary.columns} columns'),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

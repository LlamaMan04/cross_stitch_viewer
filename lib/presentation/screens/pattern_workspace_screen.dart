import 'package:flutter/material.dart';

import '../../domain/pattern_document.dart';
import '../../domain/repositories.dart';
import '../pattern_renderer/pattern_viewport.dart';

/// Loads and displays a read-only rendering of a persisted pattern document.
class PatternWorkspaceScreen extends StatelessWidget {
  /// Creates a workspace for the selected document.
  const PatternWorkspaceScreen({
    required this.documentId,
    required this.patternDocuments,
    super.key,
  });

  /// Stable identity of the document opened from the library.
  final String documentId;

  /// Repository used to load the selected normalized document.
  final PatternDocumentRepository patternDocuments;

  /// Builds the loading, missing-document, and pattern-rendering states.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pattern Workspace')),
      body: FutureBuilder<PatternDocument?>(
        future: patternDocuments.getById(documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          // A document can disappear after its library entry was opened.
          final document = snapshot.data;
          if (document == null) {
            return const Center(
              child: Text('This pattern is no longer available.'),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${document.grid.dimensions.rows} × '
                      '${document.grid.dimensions.columns}',
                    ),
                  ],
                ),
              ),
              Expanded(child: PatternRenderView(document: document)),
            ],
          );
        },
      ),
    );
  }
}

/// Places a normalized pattern document in the viewport rendering engine.
class PatternRenderView extends StatelessWidget {
  /// Creates a read-only viewport for [document].
  const PatternRenderView({required this.document, super.key});

  /// Pattern data rendered by the viewport.
  final PatternDocument document;

  /// Builds a bounded surface whose camera maps grid coordinates to pixels.
  @override
  Widget build(BuildContext context) {
    // The viewport surface follows the active application theme.
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: PatternViewport(document: document),
    );
  }
}

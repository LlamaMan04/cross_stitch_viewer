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
    return FutureBuilder<PatternDocument?>(
      future: patternDocuments.getById(documentId),
      builder: (context, snapshot) {
        // The loaded document drives both the app-bar title and viewport body.
        final document = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            // A shorter toolbar prioritizes vertical space for the renderer.
            toolbarHeight: 48,
            title: Text(
              document?.title ?? 'Pattern Workspace',
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (document != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${document.grid.dimensions.rows} × '
                      '${document.grid.dimensions.columns}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(snapshot.connectionState, document),
        );
      },
    );
  }

  /// Builds the workspace body once the document read has completed.
  Widget _buildBody(
    ConnectionState connectionState,
    PatternDocument? document,
  ) {
    if (connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (document == null) {
      return const Center(child: Text('This pattern is no longer available.'));
    }
    return PatternRenderView(document: document);
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

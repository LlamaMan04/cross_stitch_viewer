import 'package:flutter/material.dart';

import '../../domain/pattern_document.dart';
import '../../domain/repositories.dart';

/// Temporary document destination that establishes the workspace navigation path.
class PatternWorkspaceScreen extends StatelessWidget {
  /// Creates a workspace placeholder for the selected document.
  const PatternWorkspaceScreen({
    required this.documentId,
    required this.patternDocuments,
    super.key,
  });

  /// Stable identity of the document opened from the library.
  final String documentId;

  /// Repository used to load the selected normalized document.
  final PatternDocumentRepository patternDocuments;

  /// Builds the loading, missing-document, and placeholder workspace states.
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
          final document = snapshot.data;
          if (document == null) {
            return const Center(
              child: Text('This pattern is no longer available.'),
            );
          }
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.grid_on_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    document.title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${document.grid.dimensions.rows} rows × '
                    '${document.grid.dimensions.columns} columns',
                  ),
                  const SizedBox(height: 20),
                  const Text('Pattern rendering is the next workspace slice.'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

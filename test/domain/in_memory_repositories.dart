import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/domain/repositories.dart';

/// In-memory pattern repository used to exercise the repository contract in tests.
class InMemoryPatternDocumentRepository implements PatternDocumentRepository {
  /// Test documents keyed by their stable document IDs.
  final Map<String, PatternDocument> _documents = {};

  /// Validates and stores a document, replacing any prior value with the same ID.
  @override
  Future<void> save(PatternDocument document) async {
    document.validate();
    _documents[document.id] = document;
  }

  /// Returns the stored document associated with [id], if present.
  @override
  Future<PatternDocument?> getById(String id) async => _documents[id];

  /// Projects stored documents into lightweight library metadata.
  @override
  Future<List<PatternSummary>> listSummaries() async => [
    for (final document in _documents.values)
      PatternSummary(
        id: document.id,
        title: document.title,
        rows: document.grid.dimensions.rows,
        columns: document.grid.dimensions.columns,
      ),
  ];

  /// Removes the stored test document with [id].
  @override
  Future<void> delete(String id) async {
    _documents.remove(id);
  }
}

/// In-memory progress repository used to exercise the progress contract in tests.
class InMemoryProgressRepository implements ProgressRepository {
  /// Progress snapshots keyed by the associated pattern document ID.
  final Map<String, ProgressState> _progress = {};

  /// Returns saved progress for [documentId], if present.
  @override
  Future<ProgressState?> getForDocument(String documentId) async =>
      _progress[documentId];

  /// Validates and stores progress under its document ID.
  @override
  Future<void> save(ProgressState progress) async {
    progress.validate();
    _progress[progress.documentId] = progress;
  }

  /// Removes saved progress for [documentId].
  @override
  Future<void> deleteForDocument(String documentId) async {
    _progress.remove(documentId);
  }
}

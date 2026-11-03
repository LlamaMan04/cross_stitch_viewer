import 'pattern_document.dart';
import 'progress_models.dart';

/// Small display-ready document metadata used by library listings.
class PatternSummary {
  /// Creates a summary for one saved pattern.
  const PatternSummary({
    required this.id,
    required this.title,
    required this.rows,
    required this.columns,
  });

  /// Stable document identifier used to open or manage the pattern.
  final String id;

  /// Display title for the library entry.
  final String title;

  /// Number of grid rows in the document.
  final int rows;

  /// Number of grid columns in the document.
  final int columns;
}

/// Storage boundary for normalized pattern documents.
abstract interface class PatternDocumentRepository {
  /// Inserts or replaces [document] using its stable ID.
  Future<void> save(PatternDocument document);

  /// Loads a document by ID, or returns null when it is absent.
  Future<PatternDocument?> getById(String id);

  /// Returns lightweight summaries for all stored documents.
  Future<List<PatternSummary>> listSummaries();

  /// Removes a document by ID; deleting a missing ID is a no-op.
  Future<void> delete(String id);
}

/// Storage boundary for mutable user progress kept apart from source patterns.
abstract interface class ProgressRepository {
  /// Loads progress for a document, or returns null when none is saved.
  Future<ProgressState?> getForDocument(String documentId);

  /// Inserts or replaces progress for its associated document.
  Future<void> save(ProgressState progress);

  /// Removes progress for a document; deleting missing progress is a no-op.
  Future<void> deleteForDocument(String documentId);
}

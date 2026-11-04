import '../domain/repositories.dart';
import '../infrastructure/persistence/app_database.dart';
import '../infrastructure/persistence/drift_pattern_document_repository.dart';
import '../infrastructure/persistence/drift_progress_repository.dart';

/// Owns application-scoped services created for a production app run.
class AppDependencies {
  /// Creates dependencies over an already configured database.
  AppDependencies(this.database)
    : patternDocuments = DriftPatternDocumentRepository(database),
      progress = DriftProgressRepository(database);

  /// Opens the production local database and its repository adapters.
  factory AppDependencies.open() => AppDependencies(AppDatabase.open());

  /// Database shared by the application's persistence adapters.
  final AppDatabase database;

  /// Repository for normalized pattern documents.
  final PatternDocumentRepository patternDocuments;

  /// Repository for mutable pattern progress.
  final ProgressRepository progress;

  /// Closes the local database when the owning application shuts down.
  Future<void> close() => database.close();
}

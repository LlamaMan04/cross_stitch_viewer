import 'package:drift/drift.dart';

import 'database_connection.dart';
import 'database_migrations.dart';
import 'persistence_metadata.dart';
import 'schema/pattern_tables.dart';
import 'schema/progress_tables.dart';

part 'app_database.g.dart';

/// Owns the local SQLite schema and isolates Drift from domain-layer contracts.
@DriftDatabase(
  tables: [
    PersistenceMetadata,
    PatternDocuments,
    SourceMetadataEntries,
    LibraryMetadata,
    PatternThreads,
    PatternSymbols,
    PatternRegions,
    PatternCells,
    ParserDiagnostics,
    ProgressStates,
    CompletedCells,
    LocationMarkers,
    ViewportStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Creates a database over the supplied executor for production or tests.
  AppDatabase(super.executor);

  /// Opens the production database in the platform application-support directory.
  factory AppDatabase.open() => AppDatabase(openAppDatabaseConnection());

  /// Creates the first version of the operational persistence schema.
  @override
  int get schemaVersion => 1;

  /// Defines creation, upgrade, and connection configuration for the database.
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => migrator.createAll(),
      onUpgrade: migrateAppDatabase,
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }
}

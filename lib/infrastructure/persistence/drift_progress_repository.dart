import 'package:drift/drift.dart';

import '../../domain/progress_models.dart';
import '../../domain/repositories.dart';
import 'app_database.dart';
import 'progress_mapper.dart';

/// Stores mutable completion, markers, and viewport data independently.
class DriftProgressRepository implements ProgressRepository {
  /// Uses a database whose lifecycle is owned by the application.
  DriftProgressRepository(this.database);

  /// Database used for all progress queries and transactions.
  final AppDatabase database;

  @override
  Future<void> save(ProgressState progress) async {
    progress.validate();
    await database.transaction(() async {
      // The progress root remains attached to the same pattern document.
      await database
          .into(database.progressStates)
          .insertOnConflictUpdate(ProgressMapper.progress(progress));
      await (database.delete(
        database.completedCells,
      )..where((table) => table.documentId.equals(progress.documentId))).go();
      await (database.delete(
        database.locationMarkers,
      )..where((table) => table.documentId.equals(progress.documentId))).go();
      await (database.delete(
        database.viewportStates,
      )..where((table) => table.documentId.equals(progress.documentId))).go();
      await database.batch((batch) {
        batch.insertAll(
          database.completedCells,
          ProgressMapper.completedCells(progress),
        );
        batch.insertAll(
          database.locationMarkers,
          ProgressMapper.markers(progress),
        );
        final viewport = ProgressMapper.viewport(progress);
        if (viewport != null) batch.insert(database.viewportStates, viewport);
      });
      await (database.update(
        database.libraryMetadata,
      )..where((table) => table.documentId.equals(progress.documentId))).write(
        LibraryMetadataCompanion(lastModifiedAt: Value(DateTime.now().toUtc())),
      );
    });
  }

  @override
  Future<ProgressState?> getForDocument(
    String documentId,
  ) => database.transaction(() async {
    final root = await (database.select(
      database.progressStates,
    )..where((table) => table.documentId.equals(documentId))).getSingleOrNull();
    if (root == null) return null;
    final cells =
        await (database.select(database.completedCells)
              ..where((table) => table.documentId.equals(documentId))
              ..orderBy([
                (table) => OrderingTerm.asc(table.gridRow),
                (table) => OrderingTerm.asc(table.gridColumn),
              ]))
            .get();
    final markers =
        await (database.select(database.locationMarkers)
              ..where((table) => table.documentId.equals(documentId))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final viewport = await (database.select(
      database.viewportStates,
    )..where((table) => table.documentId.equals(documentId))).getSingleOrNull();
    return ProgressMapper.fromRows(
      progress: root,
      completedCells: cells,
      markers: markers,
      viewport: viewport,
    );
  });

  @override
  Future<void> deleteForDocument(String documentId) async {
    await (database.delete(
      database.progressStates,
    )..where((table) => table.documentId.equals(documentId))).go();
  }
}

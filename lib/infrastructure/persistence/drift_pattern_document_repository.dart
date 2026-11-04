import 'package:drift/drift.dart';

import '../../domain/pattern_document.dart';
import '../../domain/repositories.dart';
import 'app_database.dart';
import 'pattern_mapper.dart';

/// Stores normalized pattern documents in the local Drift database.
class DriftPatternDocumentRepository implements PatternDocumentRepository {
  /// Uses a database whose lifecycle is owned by the application.
  DriftPatternDocumentRepository(this.database);

  /// Database used for all document queries and transactions.
  final AppDatabase database;

  @override
  Future<void> save(PatternDocument document) async {
    document.validate();
    // Check encodability before changing any rows.
    final metadata = PatternMapper.metadata(document);
    await database.transaction(() async {
      final existing =
          await (database.select(database.libraryMetadata)
                ..where((table) => table.documentId.equals(document.id)))
              .getSingleOrNull();

      // Remove children first so the parent row and any progress survive.
      await (database.delete(
        database.patternCells,
      )..where((table) => table.documentId.equals(document.id))).go();
      await (database.delete(
        database.parserDiagnostics,
      )..where((table) => table.documentId.equals(document.id))).go();
      await (database.delete(
        database.patternSymbols,
      )..where((table) => table.documentId.equals(document.id))).go();
      await (database.delete(
        database.patternRegions,
      )..where((table) => table.documentId.equals(document.id))).go();
      await (database.delete(
        database.sourceMetadataEntries,
      )..where((table) => table.documentId.equals(document.id))).go();

      await database
          .into(database.patternDocuments)
          .insertOnConflictUpdate(PatternMapper.document(document));
      await database.batch((batch) {
        batch.insertAll(database.sourceMetadataEntries, metadata);
        batch.insertAll(
          database.patternSymbols,
          PatternMapper.symbols(document),
        );
        batch.insertAll(
          database.patternRegions,
          PatternMapper.regions(document),
        );
        batch.insertAll(database.patternCells, PatternMapper.cells(document));
        batch.insertAll(
          database.parserDiagnostics,
          PatternMapper.diagnostics(document),
        );
      });

      final now = DateTime.now().toUtc();
      if (existing == null) {
        await database
            .into(database.libraryMetadata)
            .insert(
              LibraryMetadataCompanion.insert(
                documentId: document.id,
                createdAt: now,
                importedAt: now,
                lastModifiedAt: now,
              ),
            );
      } else {
        await (database.update(database.libraryMetadata)
              ..where((table) => table.documentId.equals(document.id)))
            .write(LibraryMetadataCompanion(lastModifiedAt: Value(now)));
      }
    });
  }

  @override
  Future<PatternDocument?> getById(String id) => database.transaction(() async {
    final root = await (database.select(
      database.patternDocuments,
    )..where((table) => table.id.equals(id))).getSingleOrNull();
    if (root == null) return null;
    final metadata =
        await (database.select(database.sourceMetadataEntries)
              ..where((table) => table.documentId.equals(id))
              ..orderBy([(table) => OrderingTerm.asc(table.key)]))
            .get();
    final symbols =
        await (database.select(database.patternSymbols)
              ..where((table) => table.documentId.equals(id))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final regions =
        await (database.select(database.patternRegions)
              ..where((table) => table.documentId.equals(id))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final cells =
        await (database.select(database.patternCells)
              ..where((table) => table.documentId.equals(id))
              ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
            .get();
    final diagnostics =
        await (database.select(database.parserDiagnostics)
              ..where((table) => table.documentId.equals(id))
              ..orderBy([(table) => OrderingTerm.asc(table.diagnosticIndex)]))
            .get();
    return PatternMapper.fromRows(
      document: root,
      metadata: metadata,
      symbols: symbols,
      regions: regions,
      cells: cells,
      diagnostics: diagnostics,
    );
  });

  @override
  Future<List<PatternSummary>> listSummaries() async {
    final roots = await database.select(database.patternDocuments).get();
    final library = await database.select(database.libraryMetadata).get();
    final byId = {for (final row in library) row.documentId: row};
    roots.sort((a, b) {
      final aMetadata = byId[a.id];
      final bMetadata = byId[b.id];
      final aTime =
          aMetadata?.lastOpenedAt ??
          aMetadata?.importedAt ??
          DateTime.utc(1970);
      final bTime =
          bMetadata?.lastOpenedAt ??
          bMetadata?.importedAt ??
          DateTime.utc(1970);
      final byTime = bTime.compareTo(aTime);
      return byTime != 0 ? byTime : a.id.compareTo(b.id);
    });
    return [
      for (final row in roots)
        PatternSummary(
          id: row.id,
          title: byId[row.id]?.userTitle ?? row.title,
          rows: row.rowCount,
          columns: row.columnCount,
        ),
    ];
  }

  @override
  Future<void> delete(String id) async {
    await (database.delete(
      database.patternDocuments,
    )..where((table) => table.id.equals(id))).go();
  }
}

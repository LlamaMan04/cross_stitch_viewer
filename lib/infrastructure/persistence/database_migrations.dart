import 'package:drift/drift.dart';

import 'app_database.dart';

/// Applies ordered schema changes for databases created by earlier app versions.
Future<void> migrateAppDatabase(
  AppDatabase database,
  Migrator migrator,
  int from,
  int to,
) async {
  if (from < 2 && to >= 2) {
    // Version 1 metadata contained plain strings. JSON quoting retains them
    // when version 2 starts decoding the column as structured JSON.
    await database.customStatement(
      'UPDATE source_metadata_entries SET value = json_quote(value)',
    );
    await migrator.alterTable(
      TableMigration(
        database.locationMarkers,
        columnTransformer: {
          // Resolve legacy region-anchored markers to the region origin.
          database.locationMarkers.gridRow: const CustomExpression<int>(
            'coalesce(grid_row, (SELECT origin_row FROM pattern_regions '
            'WHERE pattern_regions.document_id = location_markers.document_id '
            'AND pattern_regions.id = location_markers.region_id))',
          ),
          database.locationMarkers.gridColumn: const CustomExpression<int>(
            'coalesce(grid_column, (SELECT origin_column FROM pattern_regions '
            'WHERE pattern_regions.document_id = location_markers.document_id '
            'AND pattern_regions.id = location_markers.region_id))',
          ),
        },
      ),
    );
  }
  if (from < 3 && to >= 3) {
    await migrator.alterTable(
      TableMigration(
        database.patternSymbols,
        newColumns: [
          database.patternSymbols.threadBrand,
          database.patternSymbols.threadCatalogNumber,
          database.patternSymbols.threadName,
          database.patternSymbols.threadColor,
          database.patternSymbols.threadConversionNotes,
          database.patternSymbols.threadEvidence,
        ],
        columnTransformer: {
          database.patternSymbols.threadId: const CustomExpression<String>(
            "coalesce(thread_id, 'unknown:' || id)",
          ),
          database.patternSymbols.threadBrand: const CustomExpression<String>(
            '(SELECT brand FROM pattern_threads WHERE '
            'pattern_threads.document_id = pattern_symbols.document_id '
            'AND pattern_threads.id = pattern_symbols.thread_id)',
          ),
          database.patternSymbols.threadCatalogNumber:
              const CustomExpression<String>(
                '(SELECT catalog_number FROM pattern_threads WHERE '
                'pattern_threads.document_id = pattern_symbols.document_id '
                'AND pattern_threads.id = pattern_symbols.thread_id)',
              ),
          database.patternSymbols.threadName: const CustomExpression<String>(
            '(SELECT name FROM pattern_threads WHERE '
            'pattern_threads.document_id = pattern_symbols.document_id '
            'AND pattern_threads.id = pattern_symbols.thread_id)',
          ),
          database.patternSymbols.threadColor: const CustomExpression<String>(
            "coalesce((SELECT color FROM pattern_threads WHERE "
            'pattern_threads.document_id = pattern_symbols.document_id '
            'AND pattern_threads.id = pattern_symbols.thread_id), \'#000000\')',
          ),
          database.patternSymbols.threadConversionNotes:
              const CustomExpression<String>(
                '(SELECT conversion_notes FROM pattern_threads WHERE '
                'pattern_threads.document_id = pattern_symbols.document_id '
                'AND pattern_threads.id = pattern_symbols.thread_id)',
              ),
          database
              .patternSymbols
              .threadEvidence: const CustomExpression<String>(
            "coalesce((SELECT evidence FROM pattern_threads WHERE "
            'pattern_threads.document_id = pattern_symbols.document_id '
            "AND pattern_threads.id = pattern_symbols.thread_id), 'inferred')",
          ),
        },
      ),
    );
    await migrator.alterTable(
      TableMigration(
        database.patternCells,
        newColumns: from < 2 ? [database.patternCells.sortOrder] : const [],
        columnTransformer: from < 2
            ? {
                database.patternCells.sortOrder: const CustomExpression<int>(
                  'row_number() OVER (PARTITION BY document_id '
                  'ORDER BY grid_row, grid_column) - 1',
                ),
              }
            : const {},
      ),
    );
    if (from < 2) {
      await migrator.alterTable(
        TableMigration(
          database.viewportStates,
          newColumns: [
            database.viewportStates.showCellColor,
            database.viewportStates.showSymbols,
            database.viewportStates.showGrid,
            database.viewportStates.cellColorOpacity,
            database.viewportStates.gridColor,
            database.viewportStates.showRegions,
          ],
        ),
      );
    }
    await database.customStatement('DROP TABLE pattern_threads');
  }
  if (from >= 2 && from < 4 && to >= 4) {
    await migrator.alterTable(
      TableMigration(
        database.viewportStates,
        newColumns: [
          database.viewportStates.showCellColor,
          database.viewportStates.showSymbols,
          database.viewportStates.showGrid,
          database.viewportStates.cellColorOpacity,
          database.viewportStates.gridColor,
          database.viewportStates.showRegions,
        ],
      ),
    );
  }
}

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
            database.viewportStates.selectionHighlightColor,
            database.viewportStates.showCompletedCellOverlay,
            database.viewportStates.completedCellColor,
            database.viewportStates.completedCellOpacity,
            database.viewportStates.includeCompletedCellsInSelection,
            database.viewportStates.showRegions,
          ],
        ),
      );
    }
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
  if (from >= 2 && from < 5 && to >= 5) {
    await migrator.alterTable(
      TableMigration(
        database.viewportStates,
        newColumns: [database.viewportStates.selectionHighlightColor],
      ),
    );
  }
  if (from >= 2 && from < 6 && to >= 6) {
    await migrator.alterTable(
      TableMigration(
        database.viewportStates,
        newColumns: [
          database.viewportStates.showCompletedCellOverlay,
          database.viewportStates.completedCellColor,
          database.viewportStates.completedCellOpacity,
          database.viewportStates.includeCompletedCellsInSelection,
        ],
      ),
    );
  }
  if (from < 9 && to >= 9) {
    final patternSymbolsExist =
        await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' "
              "AND name = 'pattern_symbols'",
            )
            .getSingleOrNull() !=
        null;
    // Some focused legacy fixtures contain only progress tables.
    if (!patternSymbolsExist) return;
    if (from >= 3) {
      await migrator.createTable(database.patternThreads);
      await database.customStatement(
        'WITH candidates AS ('
        'SELECT document_id, thread_id AS id, sort_order AS source_order, '
        'thread_brand AS brand, thread_catalog_number AS catalog_number, '
        'thread_name AS name, thread_color AS color, '
        'thread_conversion_notes AS conversion_notes, '
        'thread_evidence AS evidence FROM pattern_symbols '
        '${from >= 7 ? "UNION ALL SELECT document_id, thread_id AS id, 1000000 + sort_order AS source_order, thread_brand AS brand, thread_catalog_number AS catalog_number, thread_name AS name, thread_color AS color, thread_conversion_notes AS conversion_notes, thread_evidence AS evidence FROM pattern_backstitches " : ""}'
        '), ranked AS ('
        'SELECT *, row_number() OVER (PARTITION BY document_id '
        'ORDER BY source_order, id) - 1 AS thread_sort, '
        'row_number() OVER (PARTITION BY document_id, id '
        'ORDER BY source_order) AS duplicate_rank FROM candidates) '
        'INSERT INTO pattern_threads (document_id, id, sort_order, brand, '
        'catalog_number, name, color, conversion_notes, evidence) '
        'SELECT document_id, id, thread_sort, brand, catalog_number, name, '
        'color, conversion_notes, evidence FROM ranked '
        'WHERE duplicate_rank = 1',
      );
    }

    await migrator.alterTable(
      TableMigration(
        database.patternSymbols,
        newColumns: [
          database.patternSymbols.stitchType,
          database.patternSymbols.threadCount,
        ],
        columnTransformer: {
          database.patternSymbols.stitchType: CustomExpression<String>(
            "coalesce((SELECT stitch_type FROM pattern_cells WHERE "
            'pattern_cells.document_id = pattern_symbols.document_id '
            'AND pattern_cells.symbol_id = pattern_symbols.id '
            'ORDER BY ${from < 2 ? "grid_row, grid_column" : "sort_order"} '
            "LIMIT 1), 'full')",
          ),
          database.patternSymbols.threadCount: from >= 8
              ? const CustomExpression<int>(
                  '(SELECT thread_count FROM pattern_cells WHERE '
                  'pattern_cells.document_id = pattern_symbols.document_id '
                  'AND pattern_cells.symbol_id = pattern_symbols.id '
                  'ORDER BY sort_order LIMIT 1)',
                )
              : const CustomExpression<int>('NULL'),
        },
      ),
    );

    await migrator.createTable(database.patternBackstitchDefinitions);
    if (from >= 7) {
      await database.customStatement(
        'INSERT INTO pattern_backstitch_definitions '
        '(document_id, id, sort_order, thread_id, thread_count) '
        'SELECT document_id, '
        "'thread-' || hex(thread_id) || '-strands-' || "
        "coalesce(CAST(${from >= 8 ? "thread_count" : "NULL"} AS TEXT), 'default'), "
        'row_number() OVER (PARTITION BY document_id ORDER BY min(sort_order)) - 1, '
        'thread_id, ${from >= 8 ? "thread_count" : "NULL"} '
        'FROM pattern_backstitches GROUP BY document_id, thread_id, '
        '${from >= 8 ? "thread_count" : "NULL"}',
      );
      await migrator.alterTable(
        TableMigration(
          database.patternBackstitches,
          newColumns: [database.patternBackstitches.definitionId],
          columnTransformer: {
            database.patternBackstitches.definitionId: CustomExpression<String>(
              "'thread-' || hex(thread_id) || '-strands-' || "
              "coalesce(CAST(${from >= 8 ? "thread_count" : "NULL"} "
              "AS TEXT), 'default')",
            ),
          },
        ),
      );
    } else {
      await migrator.createTable(database.patternBackstitches);
    }

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
  }
}

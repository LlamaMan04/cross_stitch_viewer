import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/infrastructure/persistence/app_database.dart';
import 'package:stitch_scope/infrastructure/persistence/drift_pattern_document_repository.dart';
import 'package:stitch_scope/infrastructure/persistence/drift_progress_repository.dart';

/// Verifies the version 1 database can be opened with the current schema.
void main() {
  test(
    'upgrades legacy pattern and progress rows without losing data',
    () async {
      final legacy = sqlite3.openInMemory();
      _createVersionOneFixture(legacy);
      final database = AppDatabase(NativeDatabase.opened(legacy));
      addTearDown(database.close);

      final document = (await DriftPatternDocumentRepository(database)
          .getById('old'))!;
      final progress = (await DriftProgressRepository(database)
          .getForDocument('old'))!;

      expect(document.sourceMetadata['filename'], 'old.pdf');
      expect(document.symbols.single.thread.id, 'red');
      expect(document.symbols.single.thread.color, '#AABBCC');
      expect(document.grid.cells.single.coordinate.row, 1);
      expect(progress.markers.single.coordinate.row, 1);
      expect(progress.markers.single.coordinate.column, 2);
      expect(progress.viewport?.zoom, 2);
      expect(progress.viewport?.renderSettings, const PatternRenderSettings());
      expect(
        (await database.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        4,
      );
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );
}

/// Builds the changed portion of the original version 1 SQLite layout.
void _createVersionOneFixture(Database database) {
  database.execute('PRAGMA foreign_keys = ON');
  database.execute(
    'CREATE TABLE pattern_documents ('
    'id TEXT PRIMARY KEY, title TEXT NOT NULL, schema_version INTEGER NOT NULL, '
    'row_count INTEGER NOT NULL, column_count INTEGER NOT NULL, source_checksum TEXT)',
  );
  database.execute(
    'CREATE TABLE source_metadata_entries ('
    'document_id TEXT NOT NULL, key TEXT NOT NULL, value TEXT NOT NULL, '
    'PRIMARY KEY (document_id, key), FOREIGN KEY (document_id) '
    'REFERENCES pattern_documents(id) ON DELETE CASCADE)',
  );
  database.execute(
    'CREATE TABLE pattern_threads ('
    'document_id TEXT NOT NULL, id TEXT NOT NULL, sort_order INTEGER NOT NULL, '
    'brand TEXT, catalog_number TEXT, name TEXT, color TEXT NOT NULL, '
    'conversion_notes TEXT, evidence TEXT NOT NULL, '
    'PRIMARY KEY (document_id, id), FOREIGN KEY (document_id) '
    'REFERENCES pattern_documents(id) ON DELETE CASCADE)',
  );
  database.execute(
    'CREATE TABLE pattern_symbols ('
    'document_id TEXT NOT NULL, id TEXT NOT NULL, sort_order INTEGER NOT NULL, '
    'source_symbol TEXT NOT NULL, normalized_key TEXT NOT NULL, '
    'display_glyph TEXT NOT NULL, thread_id TEXT NOT NULL, legend_evidence TEXT, '
    'PRIMARY KEY (document_id, id), FOREIGN KEY (document_id) '
    'REFERENCES pattern_documents(id) ON DELETE CASCADE, '
    'FOREIGN KEY (document_id, thread_id) REFERENCES pattern_threads(document_id, id))',
  );
  database.execute(
    'CREATE TABLE pattern_regions ('
    'document_id TEXT NOT NULL, id TEXT NOT NULL, sort_order INTEGER NOT NULL, '
    'source_page INTEGER NOT NULL, origin_row INTEGER NOT NULL, '
    'origin_column INTEGER NOT NULL, row_count INTEGER NOT NULL, '
    'column_count INTEGER NOT NULL, label TEXT, PRIMARY KEY (document_id, id), '
    'FOREIGN KEY (document_id) REFERENCES pattern_documents(id) ON DELETE CASCADE)',
  );
  database.execute(
    'CREATE TABLE pattern_cells ('
    'document_id TEXT NOT NULL, grid_row INTEGER NOT NULL, '
    'grid_column INTEGER NOT NULL, symbol_id TEXT NOT NULL, '
    'stitch_type TEXT NOT NULL, confidence REAL, needs_review INTEGER NOT NULL, '
    'provenance_id TEXT, PRIMARY KEY (document_id, grid_row, grid_column), '
    'FOREIGN KEY (document_id) REFERENCES pattern_documents(id) ON DELETE CASCADE, '
    'FOREIGN KEY (document_id, symbol_id) REFERENCES pattern_symbols(document_id, id), '
    'FOREIGN KEY (document_id, provenance_id) REFERENCES pattern_regions(document_id, id))',
  );
  database.execute(
    'CREATE TABLE parser_diagnostics ('
    'document_id TEXT NOT NULL, diagnostic_index INTEGER NOT NULL, '
    'severity TEXT NOT NULL, stage TEXT NOT NULL, message TEXT NOT NULL, '
    'grid_row INTEGER, grid_column INTEGER, source_page INTEGER, '
    'region_id TEXT, confidence REAL, suggested_correction TEXT, '
    'PRIMARY KEY (document_id, diagnostic_index), '
    'FOREIGN KEY (document_id) REFERENCES pattern_documents(id) ON DELETE CASCADE)',
  );
  database.execute(
    'CREATE TABLE progress_states ('
    'document_id TEXT PRIMARY KEY, schema_version INTEGER NOT NULL, '
    'last_interaction_at INTEGER NOT NULL, FOREIGN KEY (document_id) '
    'REFERENCES pattern_documents(id) ON DELETE CASCADE)',
  );
  database.execute(
    'CREATE TABLE completed_cells ('
    'document_id TEXT NOT NULL, grid_row INTEGER NOT NULL, grid_column INTEGER NOT NULL, '
    'PRIMARY KEY (document_id, grid_row, grid_column), '
    'FOREIGN KEY (document_id) REFERENCES progress_states(document_id) ON DELETE CASCADE)',
  );
  database.execute(
    'CREATE TABLE location_markers ('
    'document_id TEXT NOT NULL, id TEXT NOT NULL, sort_order INTEGER NOT NULL, '
    'grid_row INTEGER, grid_column INTEGER, region_id TEXT, '
    'label TEXT NOT NULL, color TEXT NOT NULL, opacity REAL NOT NULL, '
    'visible INTEGER NOT NULL, note TEXT, PRIMARY KEY (document_id, id), '
    'FOREIGN KEY (document_id) REFERENCES progress_states(document_id) ON DELETE CASCADE, '
    'FOREIGN KEY (document_id, region_id) REFERENCES pattern_regions(document_id, id))',
  );
  database.execute(
    'CREATE TABLE viewport_states ('
    'document_id TEXT PRIMARY KEY, zoom REAL NOT NULL, pan_x REAL NOT NULL, '
    'pan_y REAL NOT NULL, anchor_row INTEGER NOT NULL, anchor_column INTEGER NOT NULL, '
    'visible_rows INTEGER, visible_columns INTEGER, highlighted_symbol_id TEXT, '
    'FOREIGN KEY (document_id) REFERENCES progress_states(document_id) ON DELETE CASCADE, '
    'FOREIGN KEY (document_id, highlighted_symbol_id) REFERENCES pattern_symbols(document_id, id))',
  );
  database.execute(
    'INSERT INTO pattern_documents VALUES '
    "('old', 'Legacy pattern', 1, 3, 4, NULL)",
  );
  database.execute(
    'INSERT INTO source_metadata_entries VALUES '
    "('old', 'filename', 'old.pdf')",
  );
  database.execute(
    'INSERT INTO pattern_threads VALUES '
    "('old', 'red', 0, NULL, NULL, NULL, '#AABBCC', NULL, 'explicit')",
  );
  database.execute(
    'INSERT INTO pattern_symbols VALUES '
    "('old', 'x', 0, 'X', 'x', 'X', 'red', NULL)",
  );
  database.execute(
    'INSERT INTO pattern_regions VALUES '
    "('old', 'page', 0, 0, 1, 2, 2, 2, NULL)",
  );
  database.execute(
    'INSERT INTO pattern_cells VALUES '
    "('old', 1, 2, 'x', 'full', NULL, 0, 'page')",
  );
  database.execute(
    'INSERT INTO progress_states VALUES '
    "('old', 1, 1793736000)",
  );
  database.execute(
    'INSERT INTO location_markers VALUES '
    "('old', 'm', 0, NULL, NULL, 'page', 'Here', '#AABBCC', 0.5, 1, NULL)",
  );
  database.execute(
    'INSERT INTO viewport_states VALUES '
    "('old', 2, 0, 0, 1, 2, NULL, NULL, 'x')",
  );
  database.execute('PRAGMA user_version = 1');
}

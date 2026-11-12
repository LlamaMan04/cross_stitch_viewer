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
      expect(document.symbols.single.threadId, 'red');
      expect(document.threads.single.color, '#AABBCC');
      expect(document.grid.cells.single.coordinate.row, 1);
      expect(progress.markers.single.coordinate.row, 1);
      expect(progress.markers.single.coordinate.column, 2);
      expect(progress.viewport?.zoom, 2);
      expect(progress.viewport?.renderSettings, const PatternRenderSettings());
      expect(
        (await database.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version'),
        9,
      );
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );

  test('adds completed-cell settings to version 5 viewport rows', () async {
    final legacy = sqlite3.openInMemory();
    _createVersionFiveViewportFixture(legacy);
    final database = AppDatabase(NativeDatabase.opened(legacy));
    addTearDown(database.close);

    final viewport = await database
        .customSelect(
          'SELECT show_completed_cell_overlay, completed_cell_color, '
          'completed_cell_opacity, include_completed_cells_in_selection '
          'FROM viewport_states',
        )
        .getSingle();

    expect(viewport.read<int>('show_completed_cell_overlay'), 1);
    expect(viewport.read<String>('completed_cell_color'), '#808080');
    expect(viewport.read<double>('completed_cell_opacity'), 0.55);
    expect(viewport.read<int>('include_completed_cells_in_selection'), 1);
    expect(
      (await database.customSelect('PRAGMA user_version').getSingle())
          .read<int>('user_version'),
      9,
    );
  });

  test('normalizes version 8 stitch and thread rows', () async {
    final legacy = sqlite3.openInMemory();
    _createVersionEightPatternFixture(legacy);
    final database = AppDatabase(NativeDatabase.opened(legacy));
    addTearDown(database.close);

    final thread = await database
        .customSelect('SELECT * FROM pattern_threads')
        .getSingle();
    final symbol = await database
        .customSelect('SELECT * FROM pattern_symbols')
        .getSingle();
    final definition = await database
        .customSelect('SELECT * FROM pattern_backstitch_definitions')
        .getSingle();
    final backstitch = await database
        .customSelect('SELECT * FROM pattern_backstitches')
        .getSingle();
    final cellColumns = await database
        .customSelect('PRAGMA table_info(pattern_cells)')
        .get();

    expect(thread.read<String>('id'), 'red');
    expect(thread.read<String>('color'), '#AABBCC');
    expect(symbol.read<String>('stitch_type'), 'half');
    expect(symbol.read<int>('thread_count'), 2);
    expect(definition.read<String>('thread_id'), 'red');
    expect(definition.read<int>('thread_count'), 1);
    expect(
      backstitch.read<String>('definition_id'),
      definition.read<String>('id'),
    );
    expect(
      cellColumns.map((row) => row.read<String>('name')),
      isNot(contains('stitch_type')),
    );
    expect(
      await database.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );
  });
}

/// Builds the version 8 embedded-thread layout immediately before normalization.
void _createVersionEightPatternFixture(Database database) {
  database.execute(
    'CREATE TABLE pattern_documents ('
    'id TEXT PRIMARY KEY, title TEXT NOT NULL, schema_version INTEGER NOT NULL, '
    'row_count INTEGER NOT NULL, column_count INTEGER NOT NULL, source_checksum TEXT)',
  );
  database.execute(
    'CREATE TABLE pattern_regions ('
    'document_id TEXT NOT NULL, id TEXT NOT NULL, sort_order INTEGER NOT NULL, '
    'source_page INTEGER NOT NULL, origin_row INTEGER NOT NULL, '
    'origin_column INTEGER NOT NULL, row_count INTEGER NOT NULL, '
    'column_count INTEGER NOT NULL, label TEXT, '
    'PRIMARY KEY (document_id, id))',
  );
  database.execute(
    'CREATE TABLE pattern_symbols ('
    'document_id TEXT NOT NULL, id TEXT NOT NULL, sort_order INTEGER NOT NULL, '
    'source_symbol TEXT NOT NULL, normalized_key TEXT NOT NULL, '
    'display_glyph TEXT NOT NULL, thread_id TEXT NOT NULL, thread_brand TEXT, '
    'thread_catalog_number TEXT, thread_name TEXT, thread_color TEXT NOT NULL, '
    'thread_conversion_notes TEXT, thread_evidence TEXT NOT NULL, '
    'legend_evidence TEXT, PRIMARY KEY (document_id, id))',
  );
  database.execute(
    'CREATE TABLE pattern_cells ('
    'document_id TEXT NOT NULL, sort_order INTEGER NOT NULL, '
    'grid_row INTEGER NOT NULL, grid_column INTEGER NOT NULL, '
    'symbol_id TEXT NOT NULL, stitch_type TEXT NOT NULL, thread_count INTEGER, '
    'confidence REAL, needs_review INTEGER NOT NULL, provenance_id TEXT, '
    'PRIMARY KEY (document_id, grid_row, grid_column))',
  );
  database.execute(
    'CREATE TABLE pattern_backstitches ('
    'document_id TEXT NOT NULL, id TEXT NOT NULL, sort_order INTEGER NOT NULL, '
    'start_row REAL NOT NULL, start_column REAL NOT NULL, '
    'end_row REAL NOT NULL, end_column REAL NOT NULL, thread_id TEXT NOT NULL, '
    'thread_brand TEXT, thread_catalog_number TEXT, thread_name TEXT, '
    'thread_color TEXT NOT NULL, thread_conversion_notes TEXT, '
    'thread_evidence TEXT NOT NULL, thread_count INTEGER, confidence REAL, '
    'needs_review INTEGER NOT NULL, provenance_id TEXT, '
    'PRIMARY KEY (document_id, id))',
  );
  database.execute(
    "INSERT INTO pattern_documents VALUES ('old', 'Old', 1, 2, 2, NULL)",
  );
  database.execute(
    "INSERT INTO pattern_regions VALUES ('old', 'page', 0, 0, 0, 0, 2, 2, NULL)",
  );
  database.execute(
    "INSERT INTO pattern_symbols VALUES ('old', 'x', 0, 'X', 'x', 'X', "
    "'red', 'DMC', '1', 'Red', '#AABBCC', NULL, 'explicit', NULL)",
  );
  database.execute(
    "INSERT INTO pattern_cells VALUES ('old', 0, 0, 0, 'x', 'half', 2, "
    "NULL, 0, 'page')",
  );
  database.execute(
    "INSERT INTO pattern_backstitches VALUES ('old', 'line', 0, 0, 0, 1, 1, "
    "'red', 'DMC', '1', 'Red', '#AABBCC', NULL, 'explicit', 1, NULL, 0, 'page')",
  );
  database.execute('PRAGMA user_version = 8');
}

/// Builds the version 5 viewport layout immediately preceding this migration.
void _createVersionFiveViewportFixture(Database database) {
  database.execute(
    'CREATE TABLE viewport_states ('
    'document_id TEXT PRIMARY KEY, zoom REAL NOT NULL, pan_x REAL NOT NULL, '
    'pan_y REAL NOT NULL, anchor_row INTEGER NOT NULL, anchor_column INTEGER NOT NULL, '
    'visible_rows INTEGER, visible_columns INTEGER, '
    'show_cell_color INTEGER NOT NULL DEFAULT 0, '
    'show_symbols INTEGER NOT NULL DEFAULT 1, show_grid INTEGER NOT NULL DEFAULT 1, '
    'cell_color_opacity REAL NOT NULL DEFAULT 0.22, '
    "grid_color TEXT NOT NULL DEFAULT '#000000', "
    "selection_highlight_color TEXT NOT NULL DEFAULT '#FFC107', "
    'show_regions INTEGER NOT NULL DEFAULT 0)',
  );
  database.execute(
    'INSERT INTO viewport_states ('
    'document_id, zoom, pan_x, pan_y, anchor_row, anchor_column'
    ") VALUES ('old', 2, 0, 0, 1, 2)",
  );
  database.execute('PRAGMA user_version = 5');
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

import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

/// Verifies the database boundary can create and configure the current schema.
void main() {
  test('creates the version 7 schema and enables foreign keys', () async {
    final database = openTestDatabase();
    addTearDown(database.close);

    expect(database.schemaVersion, 7);

    final foreignKeys = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();
    expect(foreignKeys.data['foreign_keys'], 1);

    final userVersion = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(userVersion.data['user_version'], 7);
  });

  test('creates every initial pattern and progress table', () async {
    final database = openTestDatabase();
    addTearDown(database.close);

    final tableRows = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final tableNames = tableRows.map((row) => row.read<String>('name')).toSet();

    expect(
      tableNames,
      containsAll(<String>{
        'persistence_metadata',
        'pattern_documents',
        'source_metadata_entries',
        'library_metadata',
        'pattern_symbols',
        'pattern_backstitches',
        'pattern_regions',
        'pattern_cells',
        'parser_diagnostics',
        'progress_states',
        'completed_cells',
        'location_markers',
        'viewport_states',
      }),
    );

    final indexRows = await database
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
        .get();
    final indexNames = indexRows.map((row) => row.read<String>('name')).toSet();

    expect(
      indexNames,
      containsAll(<String>{
        'pattern_documents_title',
        'pattern_documents_source_checksum',
        'library_metadata_last_opened',
        'library_metadata_last_modified',
        'pattern_symbols_document_thread',
        'pattern_backstitches_document_provenance',
        'pattern_regions_document_page',
        'pattern_cells_document_symbol',
      }),
    );

    final foreignKeyViolations = await database
        .customSelect('PRAGMA foreign_key_check')
        .get();
    expect(foreignKeyViolations, isEmpty);
  });

  test('stores one completion record per document coordinate', () async {
    final database = openTestDatabase();
    addTearDown(database.close);

    final columnRows = await database
        .customSelect('PRAGMA table_info(completed_cells)')
        .get();
    final columnNames = columnRows
        .map((row) => row.read<String>('name'))
        .toSet();

    expect(
      columnNames,
      equals(<String>{'document_id', 'grid_row', 'grid_column'}),
    );

    final primaryKeyColumns = columnRows
        .where((row) => row.read<int>('pk') > 0)
        .map((row) => row.read<String>('name'))
        .toList();
    expect(
      primaryKeyColumns,
      equals(<String>['document_id', 'grid_row', 'grid_column']),
    );
  });

  test('stores the viewport fields defined by the domain model', () async {
    final database = openTestDatabase();
    addTearDown(database.close);

    final columnRows = await database
        .customSelect('PRAGMA table_info(viewport_states)')
        .get();
    final columnNames = columnRows
        .map((row) => row.read<String>('name'))
        .toSet();

    expect(columnNames, isNot(contains('highlighted_symbol_id')));
    expect(
      columnNames,
      containsAll({
        'anchor_row',
        'anchor_column',
        'zoom',
        'show_cell_color',
        'show_symbols',
        'show_grid',
        'cell_color_opacity',
        'grid_color',
        'selection_highlight_color',
        'show_completed_cell_overlay',
        'completed_cell_color',
        'completed_cell_opacity',
        'include_completed_cells_in_selection',
        'show_regions',
      }),
    );
  });

  test(
    'stores library timestamps and an optional user-defined title',
    () async {
      final database = openTestDatabase();
      addTearDown(database.close);

      final columnRows = await database
          .customSelect('PRAGMA table_info(library_metadata)')
          .get();
      final columnNames = columnRows
          .map((row) => row.read<String>('name'))
          .toSet();

      expect(
        columnNames,
        containsAll(<String>{
          'document_id',
          'created_at',
          'imported_at',
          'last_opened_at',
          'last_modified_at',
          'user_title',
        }),
      );
    },
  );

  test('embeds complete thread definitions in each symbol', () async {
    final database = openTestDatabase();
    addTearDown(database.close);

    final symbols = await database
        .customSelect('PRAGMA table_info(pattern_symbols)')
        .get();
    final cells = await database
        .customSelect('PRAGMA table_info(pattern_cells)')
        .get();
    expect(
      symbols.map((row) => row.read<String>('name')),
      containsAll({
        'thread_id',
        'thread_brand',
        'thread_catalog_number',
        'thread_name',
        'thread_color',
        'thread_conversion_notes',
        'thread_evidence',
      }),
    );
    expect(
      cells.map((row) => row.read<String>('name')),
      contains('sort_order'),
    );
    expect(
      cells.map((row) => row.read<String>('name')),
      isNot(contains('thread_id')),
    );
  });

  test('uses coordinate-only markers from the domain contract', () async {
    final database = openTestDatabase();
    addTearDown(database.close);
    final columns = await database
        .customSelect('PRAGMA table_info(location_markers)')
        .get();
    final names = columns.map((row) => row.read<String>('name')).toSet();
    expect(names, isNot(contains('region_id')));
    expect(names, containsAll({'grid_row', 'grid_column'}));
    expect(
      columns
          .where(
            (row) =>
                {'grid_row', 'grid_column'}.contains(row.read<String>('name')),
          )
          .every((row) => row.read<int>('notnull') == 1),
      isTrue,
    );
  });

  test('stores backstitch geometry and thread fields', () async {
    final database = openTestDatabase();
    addTearDown(database.close);
    final columns = await database
        .customSelect('PRAGMA table_info(pattern_backstitches)')
        .get();
    expect(
      columns.map((row) => row.read<String>('name')),
      containsAll({
        'start_row',
        'start_column',
        'end_row',
        'end_column',
        'thread_id',
        'thread_color',
        'confidence',
        'needs_review',
        'provenance_id',
      }),
    );
  });
}

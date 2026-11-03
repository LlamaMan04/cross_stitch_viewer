import 'package:flutter_test/flutter_test.dart';

import '../../support/test_database.dart';

/// Verifies the database boundary can create and configure the first schema.
void main() {
  test('creates the version 1 schema and enables foreign keys', () async {
    final database = openTestDatabase();
    addTearDown(database.close);

    expect(database.schemaVersion, 1);

    final foreignKeys = await database
        .customSelect('PRAGMA foreign_keys')
        .getSingle();
    expect(foreignKeys.data['foreign_keys'], 1);

    final userVersion = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(userVersion.data['user_version'], 1);
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
        'pattern_threads',
        'pattern_symbols',
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

  test('stores an optional highlighted symbol with the viewport', () async {
    final database = openTestDatabase();
    addTearDown(database.close);

    final columnRows = await database
        .customSelect('PRAGMA table_info(viewport_states)')
        .get();
    final columnNames = columnRows
        .map((row) => row.read<String>('name'))
        .toSet();

    expect(columnNames, contains('highlighted_symbol_id'));
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
}

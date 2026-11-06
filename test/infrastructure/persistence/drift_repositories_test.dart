import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/pattern_definitions.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/pattern_provenance.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/infrastructure/persistence/drift_pattern_document_repository.dart';
import 'package:stitch_scope/infrastructure/persistence/drift_progress_repository.dart';

import '../../support/test_database.dart';

/// Exercises the two repository contracts against a real SQLite executor.
void main() {
  test('round trips every domain field in a pattern document', () async {
    final database = openTestDatabase();
    addTearDown(database.close);
    final repository = DriftPatternDocumentRepository(database);
    final original = _document();

    await repository.save(original);
    final loaded = (await repository.getById(original.id))!;

    expect(loaded.title, original.title);
    expect(loaded.schemaVersion, original.schemaVersion);
    expect(loaded.sourceChecksum, original.sourceChecksum);
    expect(loaded.sourceMetadata, original.sourceMetadata);
    expect(loaded.grid.dimensions.rows, 3);
    expect(loaded.grid.dimensions.columns, 4);
    expect(
      loaded.grid.cells.map((cell) => cell.coordinate),
      original.grid.cells.map((cell) => cell.coordinate),
    );
    expect(loaded.grid.cells.first.stitchType, StitchType.half);
    expect(loaded.grid.cells.first.confidence?.value, 0.4);
    expect(loaded.grid.cells.first.needsReview, isTrue);
    expect(loaded.grid.cells.first.provenanceId, 'page');
    expect(loaded.symbols.first.thread.id, 'blue');
    expect(loaded.symbols.first.legendEvidence, 'unresolved');
    expect(loaded.symbols.first.thread.evidence, ColorEvidence.inferred);
    expect(loaded.symbols.first.thread.conversionNotes, 'approximate');
    expect(loaded.regions.first.label, 'top');
    expect(loaded.diagnostics.first.coordinate, const GridCoordinate(0, 1));
    expect(loaded.diagnostics.first.confidence?.value, 0.7);
    expect(loaded.diagnostics.first.suggestedCorrection, 'Inspect PDF');
    expect((await repository.listSummaries()).single.title, original.title);
  });

  test('replacement removes stale pattern rows and retains progress', () async {
    final database = openTestDatabase();
    addTearDown(database.close);
    final documents = DriftPatternDocumentRepository(database);
    final progress = DriftProgressRepository(database);
    await documents.save(_document());
    await progress.save(_progress());

    await documents.save(
      PatternDocument(
        id: 'pattern',
        title: 'Updated',
        schemaVersion: 1,
        grid: PatternGrid(
          dimensions: const PatternDimensions(1, 1),
          cells: const [],
        ),
        symbols: const [],
      ),
    );

    final loaded = (await documents.getById('pattern'))!;
    expect(loaded.grid.cells, isEmpty);
    expect(loaded.sourceMetadata, isEmpty);
    expect((await progress.getForDocument('pattern'))!.markers, hasLength(1));
  });

  test(
    'round trips progress and clears removed children on replacement',
    () async {
      final database = openTestDatabase();
      addTearDown(database.close);
      final documents = DriftPatternDocumentRepository(database);
      final repository = DriftProgressRepository(database);
      await documents.save(_document());
      await repository.save(_progress());

      final loaded = (await repository.getForDocument('pattern'))!;
      expect(loaded.schemaVersion, 1);
      expect(loaded.completedCells, [const GridCoordinate(0, 1)]);
      expect(loaded.markers.single.note, 'Keep place');
      expect(loaded.markers.single.opacity, 0.5);
      expect(loaded.markers.single.visible, isFalse);
      expect(loaded.viewport?.zoom, 2.5);
      expect(loaded.viewport?.anchor, const GridCoordinate(0, 1));
      expect(loaded.viewport?.visibleRows, 2);
      expect(loaded.viewport?.renderSettings.showCellColor, isTrue);
      expect(loaded.viewport?.renderSettings.showSymbols, isFalse);
      expect(loaded.viewport?.renderSettings.showGrid, isFalse);
      expect(loaded.viewport?.renderSettings.cellColorOpacity, 0.45);
      expect(
        loaded.viewport?.renderSettings.gridColor,
        GridColorPreset.darkGray,
      );
      expect(loaded.viewport?.renderSettings.showRegions, isTrue);
      expect(loaded.lastInteractionAt, DateTime.utc(2026, 11, 3, 12));

      await repository.save(
        ProgressState(
          documentId: 'pattern',
          schemaVersion: 1,
          completedCells: const [],
          lastInteractionAt: DateTime.utc(2026, 11, 3, 13),
        ),
      );
      final replaced = (await repository.getForDocument('pattern'))!;
      expect(replaced.completedCells, isEmpty);
      expect(replaced.markers, isEmpty);
      expect(replaced.viewport, isNull);
    },
  );

  test('failed replacement rolls back both document and child rows', () async {
    final database = openTestDatabase();
    addTearDown(database.close);
    final repository = DriftPatternDocumentRepository(database);
    await repository.save(_document());

    final invalid = PatternDocument(
      id: 'pattern',
      title: 'Would replace',
      schemaVersion: 1,
      grid: PatternGrid(
        dimensions: const PatternDimensions(1, 1),
        cells: const [],
      ),
      symbols: const [
        SymbolDefinition(
          id: 'invalid',
          sourceSymbol: '',
          normalizedKey: 'x',
          displayGlyph: 'x',
          thread: ThreadDefinition(id: 'invalid', color: '#000000'),
        ),
      ],
    );
    await expectLater(repository.save(invalid), throwsA(isA<Exception>()));
    expect((await repository.getById('pattern'))!.title, 'Sampler');
    expect((await repository.getById('pattern'))!.grid.cells, hasLength(2));
  });

  test('rejects metadata that cannot be encoded as JSON', () async {
    final database = openTestDatabase();
    addTearDown(database.close);
    final repository = DriftPatternDocumentRepository(database);
    final invalid = PatternDocument(
      id: 'pattern',
      title: 'Unsupported metadata',
      schemaVersion: 1,
      grid: PatternGrid(
        dimensions: const PatternDimensions(1, 1),
        cells: const [],
      ),
      symbols: const [],
      sourceMetadata: const {'unsupported': Object()},
    );
    await expectLater(
      repository.save(invalid),
      throwsA(isA<JsonUnsupportedObjectError>()),
    );
    expect(await repository.getById('pattern'), isNull);
  });

  test(
    'document deletion cascades to progress; missing deletes are safe',
    () async {
      final database = openTestDatabase();
      addTearDown(database.close);
      final documents = DriftPatternDocumentRepository(database);
      final progress = DriftProgressRepository(database);
      expect(await documents.getById('missing'), isNull);
      expect(await progress.getForDocument('missing'), isNull);
      await documents.save(_document());
      await progress.save(_progress());
      await documents.delete('pattern');
      await documents.delete('pattern');
      await progress.deleteForDocument('pattern');
      expect(await documents.getById('pattern'), isNull);
      expect(await progress.getForDocument('pattern'), isNull);
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );

  test('progress cannot be saved without its pattern document', () async {
    final database = openTestDatabase();
    addTearDown(database.close);
    final repository = DriftProgressRepository(database);
    await expectLater(repository.save(_progress()), throwsA(isA<Exception>()));
    expect(await repository.getForDocument('pattern'), isNull);
  });
}

/// Builds a pattern with optional references and structured metadata.
PatternDocument _document() => PatternDocument(
  id: 'pattern',
  title: 'Sampler',
  schemaVersion: 1,
  grid: PatternGrid(
    dimensions: const PatternDimensions(3, 4),
    cells: const [
      StitchCell(
        coordinate: GridCoordinate(0, 1),
        symbolId: 'unknown',
        stitchType: StitchType.half,
        confidence: Confidence(0.4),
        needsReview: true,
        provenanceId: 'page',
      ),
      StitchCell(coordinate: GridCoordinate(2, 3), symbolId: 'unknown'),
    ],
  ),
  symbols: const [
    SymbolDefinition(
      id: 'unknown',
      sourceSymbol: '?',
      normalizedKey: '?',
      displayGlyph: '?',
      thread: ThreadDefinition(
        id: 'blue',
        color: '#123ABC',
        brand: 'DMC',
        catalogNumber: '1',
        name: 'Blue',
        conversionNotes: 'approximate',
        evidence: ColorEvidence.inferred,
      ),
      legendEvidence: 'unresolved',
    ),
  ],
  regions: const [
    PatternRegion(
      id: 'page',
      sourcePage: 0,
      origin: GridCoordinate(0, 0),
      rows: 2,
      columns: 4,
      label: 'top',
    ),
  ],
  sourceMetadata: const {
    'filename': 'sampler.pdf',
    'pages': 2,
    'flags': [true, null],
  },
  sourceChecksum: 'abc123',
  diagnostics: const [
    ParserDiagnostic(
      severity: DiagnosticSeverity.warning,
      stage: DiagnosticStage.symbols,
      message: 'Check symbol',
      coordinate: GridCoordinate(0, 1),
      sourcePage: 0,
      regionId: 'page',
      confidence: Confidence(0.7),
      suggestedCorrection: 'Inspect PDF',
    ),
  ],
);

/// Builds one mutable progress snapshot for persistence tests.
ProgressState _progress() => ProgressState(
  documentId: 'pattern',
  schemaVersion: 1,
  completedCells: const [GridCoordinate(0, 1)],
  markers: const [
    LocationMarker(
      id: 'marker',
      coordinate: GridCoordinate(0, 1),
      label: 'Here',
      color: '#AABBCC',
      opacity: 0.5,
      visible: false,
      note: 'Keep place',
    ),
  ],
  viewport: const ViewportState(
    zoom: 2.5,
    panX: -3,
    panY: 4,
    anchor: GridCoordinate(0, 1),
    visibleRows: 2,
    visibleColumns: 3,
    renderSettings: PatternRenderSettings(
      showCellColor: true,
      showSymbols: false,
      showGrid: false,
      cellColorOpacity: 0.45,
      gridColor: GridColorPreset.darkGray,
      showRegions: true,
    ),
  ),
  lastInteractionAt: DateTime.utc(2026, 11, 3, 12),
);

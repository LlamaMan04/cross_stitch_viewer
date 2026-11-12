import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/domain_error.dart';
import 'package:stitch_scope/domain/pattern_definitions.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/pattern_provenance.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/domain/value_objects.dart';

import 'in_memory_repositories.dart';

/// Exercises domain validation independently from persistence representation.
void main() {
  test('preserves sparse coordinates in a normalized document', () {
    final document = _sampleDocument();
    document.validate();
    expect(document.grid.cells, hasLength(2));
    expect(document.grid.cellAt(const GridCoordinate(0, 1)), isNull);
  });

  test('progress remains separate from pattern data', () {
    final progress = _sampleProgress();
    progress.validate();
    expect(progress.completedCells, [const GridCoordinate(0, 0)]);
  });

  test('document can be retrieved through the repository contract', () async {
    final document = _sampleDocument();
    final repository = InMemoryPatternDocumentRepository();
    await repository.save(document);
    expect((await repository.getById(document.id))?.title, document.title);
  });

  test('invalid dimensions and duplicate cells fail validation', () {
    expect(
      () => const PatternDimensions(0, 2).validate(),
      throwsA(isA<DocumentValidationException>()),
    );
    final document = PatternDocument(
      id: 'duplicate',
      title: 'Duplicate coordinates',
      schemaVersion: 1,
      grid: PatternGrid(
        dimensions: const PatternDimensions(1, 1),
        cells: [_cell(), _cell()],
      ),
      threads: const [ThreadDefinition(id: 'red', color: '#C0392B')],
      symbols: [_symbol()],
    );
    expect(document.validate, throwsA(isA<DocumentValidationException>()));
  });

  test('render settings use safe defaults and validate opacity', () {
    const defaults = PatternRenderSettings();
    expect(defaults.showSymbols, isTrue);
    expect(defaults.showGrid, isTrue);
    expect(defaults.showCellColor, isFalse);
    expect(defaults.showRegions, isFalse);
    expect(defaults.showTopRuler, isTrue);
    expect(defaults.showLeftRuler, isTrue);
    expect(defaults.showCompletedCellOverlay, isTrue);
    expect(defaults.includeCompletedCellsInSelection, isTrue);
    expect(defaults.gridColor, GridColorPreset.black);
    expect(
      defaults.selectionHighlightColor,
      SelectionHighlightColorPreset.amber,
    );
    expect(defaults.cellColorOpacity, 0.22);
    expect(defaults.completedCellColor, CompletedCellColorPreset.neutralGray);
    expect(defaults.completedCellOpacity, 0.55);

    expect(
      () => const PatternRenderSettings(cellColorOpacity: 1.1).validate(),
      throwsA(isA<DocumentValidationException>()),
    );
    expect(
      () => const PatternRenderSettings(completedCellOpacity: -0.1).validate(),
      throwsA(isA<DocumentValidationException>()),
    );
  });

  test(
    'source-region range queries cross tile boundaries without duplicates',
    () {
      final document = PatternDocument(
        id: 'regions',
        title: 'Regions',
        schemaVersion: 1,
        grid: PatternGrid(
          dimensions: const PatternDimensions(80, 80),
          cells: const [],
        ),
        threads: const [],
        symbols: const [],
        regions: const [
          PatternRegion(
            id: 'across-tiles',
            sourcePage: 0,
            origin: GridCoordinate(30, 30),
            rows: 8,
            columns: 8,
          ),
          PatternRegion(
            id: 'offscreen',
            sourcePage: 1,
            origin: GridCoordinate(60, 60),
            rows: 5,
            columns: 5,
          ),
        ],
      );

      final regions = document
          .regionsIntersecting(
            const GridBounds(
              startRow: 31,
              endRow: 34,
              startColumn: 31,
              endColumn: 34,
            ),
          )
          .toList();

      expect(regions.map((region) => region.id), ['across-tiles']);
    },
  );
}

/// Creates the representative source pattern used by the domain tests.
PatternDocument _sampleDocument() => PatternDocument(
  id: 'sample-pattern',
  title: 'Garden sampler',
  schemaVersion: 1,
  grid: PatternGrid(
    dimensions: const PatternDimensions(3, 4),
    cells: [
      _cell(),
      const StitchCell(
        coordinate: GridCoordinate(2, 2),
        symbolId: 'leaf',
        confidence: Confidence(0.62),
        needsReview: true,
        provenanceId: 'page-1-grid',
      ),
    ],
  ),
  threads: const [
    ThreadDefinition(id: 'red', color: '#C0392B'),
    ThreadDefinition(id: 'green', color: '#27864A'),
  ],
  symbols: [
    _symbol(),
    const SymbolDefinition(
      id: 'leaf',
      sourceSymbol: 'O',
      normalizedKey: 'o',
      displayGlyph: '○',
      threadId: 'green',
    ),
  ],
  regions: const [
    PatternRegion(
      id: 'page-0-grid',
      sourcePage: 0,
      origin: GridCoordinate(0, 0),
      rows: 2,
      columns: 4,
    ),
    PatternRegion(
      id: 'page-1-grid',
      sourcePage: 1,
      origin: GridCoordinate(2, 0),
      rows: 1,
      columns: 4,
    ),
  ],
  diagnostics: const [
    ParserDiagnostic(
      severity: DiagnosticSeverity.warning,
      stage: DiagnosticStage.symbols,
      message: 'Cell needs review',
    ),
  ],
);

/// Creates one valid populated cell for validation tests.
StitchCell _cell() => const StitchCell(
  coordinate: GridCoordinate(0, 0),
  symbolId: 'flower',
  provenanceId: 'page-0-grid',
);

/// Creates one valid symbol definition for validation tests.
SymbolDefinition _symbol() => const SymbolDefinition(
  id: 'flower',
  sourceSymbol: 'X',
  normalizedKey: 'x',
  displayGlyph: '×',
  threadId: 'red',
);

/// Creates mutable progress that refers to the representative source pattern.
ProgressState _sampleProgress() => ProgressState(
  documentId: 'sample-pattern',
  schemaVersion: 1,
  completedCells: const [GridCoordinate(0, 0)],
  lastInteractionAt: DateTime.utc(2026, 11, 2, 12),
);

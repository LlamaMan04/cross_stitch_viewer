import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_backstitch.dart';
import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/pattern_provenance.dart';
import '../../domain/value_objects.dart';

/// Supplies a small normalized document for the first-run library experience.
abstract final class SamplePatternFixture {
  /// Number of representative linear stitches in the sample document.
  static const int backstitchCount = 3;

  /// Creates the representative document saved when a new library is empty.
  static PatternDocument create() => PatternDocument(
    id: 'sample-garden-sampler',
    title: 'Garden Sampler',
    schemaVersion: 1,
    grid: PatternGrid(
      dimensions: const PatternDimensions(4, 5),
      cells: const [
        StitchCell(
          coordinate: GridCoordinate(0, 0),
          symbolId: 'flower',
          provenanceId: 'sample-grid',
        ),
        StitchCell(
          coordinate: GridCoordinate(1, 2),
          symbolId: 'leaf',
          provenanceId: 'sample-grid',
        ),
        StitchCell(
          coordinate: GridCoordinate(3, 4),
          symbolId: 'flower',
          confidence: Confidence(0.95),
          provenanceId: 'sample-grid',
        ),
      ],
    ),
    symbols: const [
      SymbolDefinition(
        id: 'flower',
        sourceSymbol: 'X',
        normalizedKey: 'x',
        displayGlyph: '✕',
        thread: ThreadDefinition(
          id: 'dmc-321',
          color: '#C72C41',
          brand: 'DMC',
          catalogNumber: '321',
          name: 'Red',
        ),
      ),
      SymbolDefinition(
        id: 'leaf',
        sourceSymbol: 'O',
        normalizedKey: 'o',
        displayGlyph: '○',
        thread: ThreadDefinition(
          id: 'dmc-704',
          color: '#5B8C3A',
          brand: 'DMC',
          catalogNumber: '704',
          name: 'Green',
        ),
      ),
    ],
    backstitches: const [
      BackstitchSegment(
        id: 'sample-flower-outline-top',
        start: BackstitchCoordinate(row: 0, column: 0),
        end: BackstitchCoordinate(row: 0, column: 1),
        thread: ThreadDefinition(
          id: 'dmc-321',
          color: '#C72C41',
          brand: 'DMC',
          catalogNumber: '321',
          name: 'Red',
        ),
        provenanceId: 'sample-grid',
      ),
      BackstitchSegment(
        id: 'sample-flower-outline-right',
        start: BackstitchCoordinate(row: 0, column: 1),
        end: BackstitchCoordinate(row: 1, column: 1),
        thread: ThreadDefinition(
          id: 'dmc-321',
          color: '#C72C41',
          brand: 'DMC',
          catalogNumber: '321',
          name: 'Red',
        ),
        provenanceId: 'sample-grid',
      ),
      BackstitchSegment(
        id: 'sample-leaf-vein',
        start: BackstitchCoordinate(row: 1, column: 2),
        end: BackstitchCoordinate(row: 2, column: 3),
        thread: ThreadDefinition(
          id: 'dmc-704',
          color: '#5B8C3A',
          brand: 'DMC',
          catalogNumber: '704',
          name: 'Green',
        ),
        provenanceId: 'sample-grid',
      ),
    ],
    regions: const [
      PatternRegion(
        id: 'sample-grid',
        sourcePage: 0,
        origin: GridCoordinate(0, 0),
        rows: 4,
        columns: 5,
        label: 'Sample grid',
      ),
    ],
    sourceMetadata: const {'origin': 'built-in sample'},
    diagnostics: const [
      ParserDiagnostic(
        severity: DiagnosticSeverity.info,
        stage: DiagnosticStage.validation,
        message: 'Built-in example document.',
      ),
    ],
  );
}

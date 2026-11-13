import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/pattern_provenance.dart';
import '../../domain/value_objects.dart';
import 'large_sample_pattern_fixture.dart';

/// Supplies a deterministic sparse document for renderer benchmark traces.
abstract final class SparseSamplePatternFixture {
  /// Number of source rows in the generated sparse pattern.
  static const int rows = 500;

  /// Number of source columns in the generated sparse pattern.
  static const int columns = 400;

  /// Spacing between populated source cells in row-major order.
  static const int populationStride = 10;

  /// Creates a 500-by-400 pattern with a fixed ten-percent population rate.
  static PatternDocument create() => PatternDocument(
    id: 'sample-sparse-test-pattern',
    title: 'Sparse Test Pattern',
    schemaVersion: 1,
    grid: PatternGrid(
      dimensions: const PatternDimensions(rows, columns),
      cells: _buildCells(),
    ),
    threads: LargeSamplePatternFixture.threads,
    symbols: LargeSamplePatternFixture.symbols,
    regions: const [
      PatternRegion(
        id: 'sparse-grid',
        sourcePage: 0,
        origin: GridCoordinate(0, 0),
        rows: rows,
        columns: columns,
        label: 'Sparse renderer benchmark grid',
      ),
    ],
    sourceMetadata: const {
      'origin': 'built-in sparse performance test fixture',
      'coverage': '10%',
    },
    diagnostics: const [
      ParserDiagnostic(
        severity: DiagnosticSeverity.info,
        stage: DiagnosticStage.validation,
        message: 'Deterministic sparse renderer benchmark fixture.',
      ),
    ],
  );

  /// Produces evenly distributed cells while preserving deterministic symbols.
  static Iterable<StitchCell> _buildCells() sync* {
    var populated = 0;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final linearIndex = row * columns + column;
        if (linearIndex % populationStride != 0) continue;
        yield StitchCell(
          coordinate: GridCoordinate(row, column),
          symbolId: LargeSamplePatternFixture
              .symbols[populated % LargeSamplePatternFixture.symbols.length]
              .id,
          provenanceId: 'sparse-grid',
        );
        populated++;
      }
    }
  }
}

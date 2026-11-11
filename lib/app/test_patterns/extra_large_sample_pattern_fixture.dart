import 'dart:math';

import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/pattern_provenance.dart';
import '../../domain/value_objects.dart';
import 'large_sample_pattern_fixture.dart';

/// Supplies a deterministic, randomly distributed pattern for large-scale tests.
abstract final class ExtraLargeSamplePatternFixture {
  /// Number of rows in the generated test pattern.
  static const int rows = 500;

  /// Number of columns in the generated test pattern.
  static const int columns = 400;

  /// Fixed pseudo-random seed that keeps the generated pattern reproducible.
  static const int randomSeed = 184729;

  /// Number of populated cells in the generated test pattern.
  static const int populatedCellCount = rows * columns;

  /// Creates a 500-by-400 pattern with randomly assigned symbol colors.
  static PatternDocument create() => PatternDocument(
    id: 'sample-extra-large-test-pattern',
    title: 'Extra Large Random Test Pattern',
    schemaVersion: 1,
    grid: PatternGrid(
      dimensions: const PatternDimensions(rows, columns),
      cells: _buildCells(),
    ),
    symbols: LargeSamplePatternFixture.symbols,
    regions: const [
      PatternRegion(
        id: 'extra-large-grid',
        sourcePage: 0,
        origin: GridCoordinate(0, 0),
        rows: rows,
        columns: columns,
        label: 'Extra large random test grid',
      ),
    ],
    sourceMetadata: const {
      'origin': 'built-in random performance test fixture',
      'randomSeed': '$randomSeed',
    },
    diagnostics: const [
      ParserDiagnostic(
        severity: DiagnosticSeverity.info,
        stage: DiagnosticStage.validation,
        message: 'Deterministic random extra-large-grid test fixture.',
      ),
    ],
  );

  /// Generates every cell with a reproducible random symbol assignment.
  static Iterable<StitchCell> _buildCells() sync* {
    // Seeded randomness preserves a realistic distribution across test runs.
    final random = Random(randomSeed);
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        // Each cell independently selects one of the fixture's thread colors.
        final symbolIndex = random.nextInt(
          LargeSamplePatternFixture.symbols.length,
        );
        yield StitchCell(
          coordinate: GridCoordinate(row, column),
          symbolId: LargeSamplePatternFixture.symbols[symbolIndex].id,
          provenanceId: 'extra-large-grid',
        );
      }
    }
  }
}

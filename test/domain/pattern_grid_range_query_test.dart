import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/value_objects.dart';

/// Verifies tile-backed half-open queries on sparse pattern grids.
void main() {
  test('returns only cells inside half-open bounds across tile edges', () {
    final grid = PatternGrid(
      dimensions: const PatternDimensions(80, 80),
      cells: const [
        StitchCell(coordinate: GridCoordinate(31, 31), symbolId: 'a'),
        StitchCell(coordinate: GridCoordinate(31, 32), symbolId: 'b'),
        StitchCell(coordinate: GridCoordinate(32, 31), symbolId: 'c'),
        StitchCell(coordinate: GridCoordinate(32, 32), symbolId: 'd'),
        StitchCell(coordinate: GridCoordinate(70, 70), symbolId: 'e'),
      ],
    );

    final cells = grid
        .cellsIntersecting(
          const GridBounds(
            startRow: 31,
            endRow: 33,
            startColumn: 31,
            endColumn: 33,
          ),
        )
        .toList();

    expect(cells.map((cell) => cell.symbolId).toSet(), {'a', 'b', 'c', 'd'});
  });

  test('clamps queries to dimensions and handles empty ranges', () {
    final grid = PatternGrid(
      dimensions: const PatternDimensions(2, 2),
      cells: const [
        StitchCell(coordinate: GridCoordinate(0, 0), symbolId: 'a'),
        StitchCell(coordinate: GridCoordinate(1, 1), symbolId: 'b'),
      ],
    );

    expect(
      grid.cellsIntersecting(
        const GridBounds(
          startRow: -10,
          endRow: 10,
          startColumn: -10,
          endColumn: 10,
        ),
      ),
      hasLength(2),
    );
    expect(
      grid.cellsIntersecting(
        const GridBounds(startRow: 1, endRow: 1, startColumn: 0, endColumn: 2),
      ),
      isEmpty,
    );
  });

  test('summarizes populated tiles without exposing their cell lists', () {
    final grid = PatternGrid(
      dimensions: const PatternDimensions(80, 80),
      cells: const [
        StitchCell(coordinate: GridCoordinate(0, 0), symbolId: 'a'),
        StitchCell(coordinate: GridCoordinate(1, 1), symbolId: 'a'),
        StitchCell(coordinate: GridCoordinate(2, 2), symbolId: 'b'),
        StitchCell(coordinate: GridCoordinate(40, 40), symbolId: 'c'),
      ],
    );

    final summaries = grid
        .tileSummariesIntersecting(
          const GridBounds(
            startRow: 0,
            endRow: 32,
            startColumn: 0,
            endColumn: 32,
          ),
        )
        .toList();

    expect(summaries, hasLength(1));
    expect(summaries.single.coordinate, const PatternTileCoordinate(0, 0));
    expect(summaries.single.populatedCellCount, 3);
    expect(summaries.single.symbolCounts, <String, int>{'a': 2, 'b': 1});
    expect(summaries.single.dominantSymbolId, 'a');
    expect(
      () => summaries.single.symbolCounts['a'] = 4,
      throwsUnsupportedError,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport/completed_cell_tile_index.dart';

/// Verifies tile-local lookup for mutable completion progress overlays.
void main() {
  test('returns only exact coordinates in intersecting source tiles', () {
    final index = CompletedCellTileIndex(<GridCoordinate>{
      const GridCoordinate(0, 0),
      const GridCoordinate(15, 15),
      const GridCoordinate(16, 16),
      const GridCoordinate(31, 31),
      const GridCoordinate(32, 32),
    });

    expect(
      index.coordinatesIntersecting(
        const GridBounds(
          startRow: 15,
          endRow: 17,
          startColumn: 15,
          endColumn: 17,
        ),
      ),
      unorderedEquals(<GridCoordinate>{
        const GridCoordinate(15, 15),
        const GridCoordinate(16, 16),
      }),
    );
  });

  test('does not retain mutations to the source coordinate set', () {
    final coordinates = <GridCoordinate>{const GridCoordinate(0, 0)};
    final index = CompletedCellTileIndex(coordinates);
    coordinates.add(const GridCoordinate(1, 1));

    expect(
      index.coordinatesIntersecting(
        const GridBounds(startRow: 0, endRow: 2, startColumn: 0, endColumn: 2),
      ),
      <GridCoordinate>[const GridCoordinate(0, 0)],
    );
  });
}

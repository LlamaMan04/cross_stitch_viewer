import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/extra_large_sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/value_objects.dart';

/// Verifies the dimensions, palette, and deterministic randomness of the fixture.
void main() {
  test('creates a reproducible 500 by 400 randomly colored pattern', () {
    // Creating twice verifies that the fixed seed reproduces the same cells.
    final firstDocument = ExtraLargeSamplePatternFixture.create();
    final secondDocument = ExtraLargeSamplePatternFixture.create();

    expect(firstDocument.grid.dimensions.rows, 500);
    expect(firstDocument.grid.dimensions.columns, 400);
    expect(
      firstDocument.grid.cells,
      hasLength(ExtraLargeSamplePatternFixture.populatedCellCount),
    );
    expect(firstDocument.symbols, hasLength(greaterThanOrEqualTo(10)));
    expect(
      firstDocument.symbols.map((symbol) => symbol.thread.color).toSet(),
      hasLength(greaterThanOrEqualTo(10)),
    );
    expect(
      firstDocument.grid.cells.map((cell) => cell.symbolId).toSet(),
      hasLength(greaterThanOrEqualTo(10)),
    );
    expect(
      firstDocument.grid.cellAt(const GridCoordinate(0, 0))?.symbolId,
      secondDocument.grid.cellAt(const GridCoordinate(0, 0))?.symbolId,
    );
    expect(
      firstDocument.grid.cellAt(const GridCoordinate(250, 200))?.symbolId,
      secondDocument.grid.cellAt(const GridCoordinate(250, 200))?.symbolId,
    );
    expect(
      firstDocument.grid.cellAt(const GridCoordinate(499, 399))?.symbolId,
      secondDocument.grid.cellAt(const GridCoordinate(499, 399))?.symbolId,
    );

    firstDocument.validate();
  });
}

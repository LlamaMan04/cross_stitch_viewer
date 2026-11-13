import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/sparse_sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/value_objects.dart';

/// Verifies the dimensions, coverage, and deterministic placement of the fixture.
void main() {
  test('creates a reproducible sparse 500 by 400 pattern', () {
    final firstDocument = SparseSamplePatternFixture.create();
    final secondDocument = SparseSamplePatternFixture.create();

    expect(firstDocument.grid.dimensions.rows, 500);
    expect(firstDocument.grid.dimensions.columns, 400);
    expect(firstDocument.grid.cells, hasLength(20000));
    expect(
      firstDocument.grid.cellAt(const GridCoordinate(0, 0))?.symbolId,
      secondDocument.grid.cellAt(const GridCoordinate(0, 0))?.symbolId,
    );
    expect(firstDocument.grid.cellAt(const GridCoordinate(0, 1)), isNull);
    expect(
      firstDocument.grid.cellAt(const GridCoordinate(499, 390)),
      isNotNull,
    );

    firstDocument.validate();
  });
}

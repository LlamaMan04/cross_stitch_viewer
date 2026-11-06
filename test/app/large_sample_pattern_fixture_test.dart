import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/value_objects.dart';

/// Verifies the dimensions, density, and palette of the large test fixture.
void main() {
  test('creates a 100 by 200 pattern with 95 percent coverage', () {
    final document = LargeSamplePatternFixture.create();

    expect(document.grid.dimensions.rows, 100);
    expect(document.grid.dimensions.columns, 200);
    expect(
      document.grid.cells,
      hasLength(LargeSamplePatternFixture.populatedCellCount),
    );
    expect(document.symbols, hasLength(12));
    expect(document.regions, hasLength(4));
    expect(
      document.regions.map((region) => region.id),
      containsAll(<String>{
        'large-top-left',
        'large-top-right',
        'large-bottom-left',
        'large-bottom-right',
      }),
    );
    expect(
      document.grid.cells.map((cell) => cell.symbolId).toSet(),
      hasLength(12),
    );
    expect(document.grid.cellAt(const GridCoordinate(0, 0)), isNull);
    expect(document.grid.cellAt(const GridCoordinate(0, 1)), isNotNull);
    expect(document.grid.cellAt(const GridCoordinate(99, 199)), isNotNull);
    expect(
      document.grid.cellAt(const GridCoordinate(0, 1))?.provenanceId,
      'large-top-left',
    );
    expect(
      document.grid.cellAt(const GridCoordinate(99, 199))?.provenanceId,
      'large-bottom-right',
    );

    document.validate();
  });
}

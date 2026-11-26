import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport/selected_symbol_tile_index.dart';

/// Verifies tile-local lookup for immutable selected-symbol overlays.
void main() {
  test('returns only selected-thread cells in intersecting source tiles', () {
    /// Representative immutable document containing multiple thread identities.
    final document = SamplePatternFixture.create();

    /// Document-derived index retained independently from active selection.
    final index = SelectedSymbolTileIndex(document);

    expect(
      index
          .cellsForThreadIntersecting(
            'dmc-321',
            const GridBounds(
              startRow: 0,
              endRow: 4,
              startColumn: 0,
              endColumn: 5,
            ),
          )
          .map((cell) => cell.coordinate),
      <GridCoordinate>[const GridCoordinate(0, 0), const GridCoordinate(3, 4)],
    );
  });

  test('filters exact bounds when matching cells share an edge tile', () {
    /// Representative immutable document used for a narrow tile-edge query.
    final document = SamplePatternFixture.create();

    /// Index that must not return another matching cell in the same source tile.
    final index = SelectedSymbolTileIndex(document);

    expect(
      index
          .cellsForThreadIntersecting(
            'dmc-321',
            const GridBounds(
              startRow: 3,
              endRow: 4,
              startColumn: 4,
              endColumn: 5,
            ),
          )
          .map((cell) => cell.coordinate),
      <GridCoordinate>[const GridCoordinate(3, 4)],
    );
  });

  test('returns no cells for an unselected thread identity', () {
    /// Representative immutable document containing no requested thread ID.
    final document = SamplePatternFixture.create();

    /// Index queried with a thread identity absent from the document.
    final index = SelectedSymbolTileIndex(document);

    expect(
      index.cellsForThreadIntersecting(
        'missing-thread',
        const GridBounds(
          startRow: 0,
          endRow: 16,
          startColumn: 0,
          endColumn: 16,
        ),
      ),
      isEmpty,
    );
  });
}

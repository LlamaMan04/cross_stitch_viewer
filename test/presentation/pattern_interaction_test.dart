import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_interaction.dart';

/// Verifies exact-cell completion selection independently of symbol identity.
void main() {
  test('toggles exact coordinates and clears the transient selection', () {
    final first = const GridCoordinate(1, 2);
    final second = const GridCoordinate(3, 4);

    final selectedFirst = CompletionCellSelection.empty().toggle(first);
    final selectedBoth = selectedFirst.toggle(second);
    final deselectedFirst = selectedBoth.toggle(first);

    expect(selectedFirst.coordinates, <GridCoordinate>{first});
    expect(selectedBoth.coordinates, <GridCoordinate>{first, second});
    expect(deselectedFirst.coordinates, <GridCoordinate>{second});
    expect(deselectedFirst.clear().isEmpty, isTrue);
  });
}

import '../../domain/value_objects.dart';

/// Active meaning assigned to a tap inside the pattern viewport.
enum PatternInteractionMode {
  /// Taps inspect the tapped cell's symbol while gestures navigate the view.
  browse,

  /// Taps select exact populated coordinates for completion editing.
  editCompletion,
}

/// Immutable exact-cell selection used while editing completion progress.
class CompletionCellSelection {
  /// Creates a selection from [coordinates] without exposing mutable state.
  CompletionCellSelection({Iterable<GridCoordinate> coordinates = const []})
    : coordinates = Set<GridCoordinate>.unmodifiable(coordinates);

  /// Creates an empty completion-cell selection.
  const CompletionCellSelection.empty()
    : coordinates = const <GridCoordinate>{};

  /// Exact grid coordinates currently selected for a completion action.
  final Set<GridCoordinate> coordinates;

  /// Whether no cell is currently selected.
  bool get isEmpty => coordinates.isEmpty;

  /// Number of exact cells currently selected.
  int get length => coordinates.length;

  /// Returns a selection with [coordinate] toggled independently of symbols.
  CompletionCellSelection toggle(GridCoordinate coordinate) {
    final updated = Set<GridCoordinate>.of(coordinates);
    if (!updated.remove(coordinate)) updated.add(coordinate);
    return CompletionCellSelection(coordinates: updated);
  }

  /// Returns a selection containing [coordinate] without removing prior cells.
  CompletionCellSelection add(GridCoordinate coordinate) =>
      CompletionCellSelection(
        coordinates: <GridCoordinate>{...coordinates, coordinate},
      );

  /// Returns an empty selection.
  CompletionCellSelection clear() => CompletionCellSelection.empty();
}

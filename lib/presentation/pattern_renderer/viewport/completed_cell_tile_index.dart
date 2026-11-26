import '../../../domain/pattern_grid.dart';
import '../../../domain/value_objects.dart';

/// Immutable completed-cell coordinates grouped by fixed source tile.
class CompletedCellTileIndex {
  /// Creates an index from [coordinates] without retaining mutable collections.
  CompletedCellTileIndex(Iterable<GridCoordinate> coordinates)
    : _coordinatesByTile = _groupCoordinates(coordinates);

  /// Coordinates grouped by their containing source tile.
  final Map<PatternTileCoordinate, Set<GridCoordinate>> _coordinatesByTile;

  /// Whether the index contains no completed coordinates.
  bool get isEmpty => _coordinatesByTile.isEmpty;

  /// Yields completed coordinates in tiles intersecting [bounds].
  ///
  /// Coordinates are additionally checked against the half-open bounds because
  /// tiles on the query edge can extend beyond the visible range.
  Iterable<GridCoordinate> coordinatesIntersecting(GridBounds bounds) sync* {
    if (bounds.isEmpty || isEmpty) return;
    final firstTileRow = bounds.startRow ~/ PatternGrid.tileSize;
    final lastTileRow = (bounds.endRow - 1) ~/ PatternGrid.tileSize;
    final firstTileColumn = bounds.startColumn ~/ PatternGrid.tileSize;
    final lastTileColumn = (bounds.endColumn - 1) ~/ PatternGrid.tileSize;
    for (var tileRow = firstTileRow; tileRow <= lastTileRow; tileRow++) {
      for (
        var tileColumn = firstTileColumn;
        tileColumn <= lastTileColumn;
        tileColumn++
      ) {
        final coordinates =
            _coordinatesByTile[PatternTileCoordinate(tileRow, tileColumn)];
        if (coordinates == null) continue;
        for (final coordinate in coordinates) {
          if (bounds.contains(coordinate)) yield coordinate;
        }
      }
    }
  }

  /// Groups source coordinates into immutable tile-local coordinate sets.
  static Map<PatternTileCoordinate, Set<GridCoordinate>> _groupCoordinates(
    Iterable<GridCoordinate> coordinates,
  ) {
    final mutableTiles = <PatternTileCoordinate, Set<GridCoordinate>>{};
    for (final coordinate in coordinates) {
      final tile = PatternGrid.tileCoordinateFor(coordinate);
      mutableTiles.putIfAbsent(tile, () => <GridCoordinate>{}).add(coordinate);
    }
    return Map<PatternTileCoordinate, Set<GridCoordinate>>.unmodifiable({
      for (final entry in mutableTiles.entries)
        entry.key: Set<GridCoordinate>.unmodifiable(entry.value),
    });
  }
}

import '../../../domain/pattern_document.dart';
import '../../../domain/pattern_grid.dart';

/// Immutable populated cells grouped by thread and fixed source tile.
///
/// The index belongs to one immutable [PatternDocument], allowing selection
/// changes to query existing document data without rebuilding spatial buckets.
class SelectedSymbolTileIndex {
  /// Creates a tile index for every populated cell in [document].
  SelectedSymbolTileIndex(PatternDocument document)
    : _cellsByThreadAndTile = _groupCells(document);

  /// Cells grouped first by thread identity, then by source tile.
  final Map<String, Map<PatternTileCoordinate, List<StitchCell>>>
  _cellsByThreadAndTile;

  /// Yields cells for [threadId] in source tiles intersecting [bounds].
  ///
  /// The final bounds check preserves exact half-open visibility at tile edges.
  Iterable<StitchCell> cellsForThreadIntersecting(
    String threadId,
    GridBounds bounds,
  ) sync* {
    /// Thread-specific tile buckets avoid inspecting unrelated symbols.
    final cellsByTile = _cellsByThreadAndTile[threadId];
    if (bounds.isEmpty || cellsByTile == null) return;

    /// First source-tile row touched by the half-open query bounds.
    final firstTileRow = bounds.startRow ~/ PatternGrid.tileSize;

    /// Last source-tile row touched by the half-open query bounds.
    final lastTileRow = (bounds.endRow - 1) ~/ PatternGrid.tileSize;

    /// First source-tile column touched by the half-open query bounds.
    final firstTileColumn = bounds.startColumn ~/ PatternGrid.tileSize;

    /// Last source-tile column touched by the half-open query bounds.
    final lastTileColumn = (bounds.endColumn - 1) ~/ PatternGrid.tileSize;
    for (var tileRow = firstTileRow; tileRow <= lastTileRow; tileRow++) {
      for (
        var tileColumn = firstTileColumn;
        tileColumn <= lastTileColumn;
        tileColumn++
      ) {
        /// Candidate cells from one matching thread and source tile.
        final tileCells =
            cellsByTile[PatternTileCoordinate(tileRow, tileColumn)];
        if (tileCells == null) continue;
        for (final cell in tileCells) {
          if (bounds.contains(cell.coordinate)) yield cell;
        }
      }
    }
  }

  /// Builds immutable thread and tile buckets from one normalized document.
  static Map<String, Map<PatternTileCoordinate, List<StitchCell>>> _groupCells(
    PatternDocument document,
  ) {
    /// Mutable buckets are used only while the immutable index is constructed.
    final mutableThreads =
        <String, Map<PatternTileCoordinate, List<StitchCell>>>{};
    for (final cell in document.grid.cells) {
      /// Every validated populated cell references one document symbol.
      final symbol = document.symbolById(cell.symbolId);
      if (symbol == null) continue;

      /// Fixed source tile containing the populated cell.
      final tile = PatternGrid.tileCoordinateFor(cell.coordinate);

      /// Tile buckets for the cell's selected-thread identity.
      final threadTiles = mutableThreads.putIfAbsent(
        symbol.threadId,
        () => <PatternTileCoordinate, List<StitchCell>>{},
      );

      /// Cells sharing the same thread and source tile.
      final tileCells = threadTiles.putIfAbsent(tile, () => <StitchCell>[]);
      tileCells.add(cell);
    }
    return Map<
      String,
      Map<PatternTileCoordinate, List<StitchCell>>
    >.unmodifiable({
      for (final threadEntry in mutableThreads.entries)
        threadEntry.key:
            Map<PatternTileCoordinate, List<StitchCell>>.unmodifiable({
              for (final tileEntry in threadEntry.value.entries)
                tileEntry.key: List<StitchCell>.unmodifiable(tileEntry.value),
            }),
    });
  }
}

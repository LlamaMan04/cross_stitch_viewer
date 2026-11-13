import 'package:flutter/widgets.dart';

import '../../domain/pattern_grid.dart';
import '../../domain/value_objects.dart';
import 'pattern_camera.dart';

/// Separates the document range painted now from the tile range warmed later.
class PatternViewportBounds {
  /// Creates immutable bounds calculated for one viewport camera snapshot.
  const PatternViewportBounds({
    required this.paintBounds,
    required this.prefetchBounds,
  });

  /// Default number of whole source tiles retained around the paint range.
  static const int defaultPrefetchTileDistance = 1;

  /// Document-clamped cells that the renderer may draw in this frame.
  final GridBounds paintBounds;

  /// Document-clamped, tile-aligned cells eligible for future cache warming.
  final GridBounds prefetchBounds;

  /// Calculates bounds for [camera] without allowing prefetching to enlarge
  /// the range actually painted.
  static PatternViewportBounds calculate({
    required PatternCamera camera,
    required Size viewportSize,
    required PatternDimensions dimensions,
    int paintOverscan = 1,
    int prefetchTileDistance = defaultPrefetchTileDistance,
  }) {
    assert(paintOverscan >= 0);
    assert(prefetchTileDistance >= 0);
    final paintBounds = camera.visibleBounds(
      viewportSize: viewportSize,
      dimensions: dimensions,
      overscan: paintOverscan,
    );
    if (paintBounds.isEmpty) {
      return PatternViewportBounds(
        paintBounds: paintBounds,
        prefetchBounds: paintBounds,
      );
    }

    final tileSize = PatternGrid.tileSize;
    final tileRows = (dimensions.rows + tileSize - 1) ~/ tileSize;
    final tileColumns = (dimensions.columns + tileSize - 1) ~/ tileSize;
    final firstTileRow = (paintBounds.startRow ~/ tileSize -
            prefetchTileDistance)
        .clamp(0, tileRows);
    final endTileRow =
        (((paintBounds.endRow - 1) ~/ tileSize) + 1 + prefetchTileDistance)
            .clamp(firstTileRow, tileRows);
    final firstTileColumn = (paintBounds.startColumn ~/ tileSize -
            prefetchTileDistance)
        .clamp(0, tileColumns);
    final endTileColumn = (((paintBounds.endColumn - 1) ~/ tileSize) +
            1 +
            prefetchTileDistance)
        .clamp(firstTileColumn, tileColumns);
    return PatternViewportBounds(
      paintBounds: paintBounds,
      prefetchBounds: GridBounds(
        startRow: firstTileRow * tileSize,
        endRow: (endTileRow * tileSize).clamp(0, dimensions.rows),
        startColumn: firstTileColumn * tileSize,
        endColumn: (endTileColumn * tileSize).clamp(0, dimensions.columns),
      ),
    );
  }
}

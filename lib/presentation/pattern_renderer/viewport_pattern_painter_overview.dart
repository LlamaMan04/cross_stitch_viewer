part of 'viewport_pattern_painter.dart';

/// Paints summary-density layers used at overview zoom levels.
extension _ViewportPatternPainterOverview on ViewportPatternPainter {
  /// Paints density plus dynamic tile accents without enumerating tile cells.
  int _paintOverviewTiles(Canvas canvas) {
    final levels = resolveOverviewRenderLevels(cellSize: camera.cellSize);
    final fineSummaries = List<PatternTileSummary>.unmodifiable(
      document.grid.overviewSummariesIntersecting(
        visibleBounds,
        levels.fineBlockSize,
      ),
    );
    final coarseSummaries = levels.blendsLevels
        ? List<PatternTileSummary>.unmodifiable(
            document.grid.overviewSummariesIntersecting(
              visibleBounds,
              levels.coarseBlockSize,
            ),
          )
        : fineSummaries;
    var drawCallCount = _paintOverviewDensityLayer(
      canvas,
      fineSummaries,
      1 - levels.coarseWeight,
    );
    if (levels.blendsLevels) {
      drawCallCount += _paintOverviewDensityLayer(
        canvas,
        coarseSummaries,
        levels.coarseWeight,
      );
    }
    drawCallCount += _paintOverviewAccents(
      canvas,
      fineSummaries,
      levels.fineBlockSize,
      1 - levels.coarseWeight,
    );
    if (levels.blendsLevels) {
      drawCallCount += _paintOverviewAccents(
        canvas,
        coarseSummaries,
        levels.coarseBlockSize,
        levels.coarseWeight,
      );
    }
    return drawCallCount;
  }

  /// Paints one summary resolution with the supplied cross-fade [opacity].
  int _paintOverviewDensityLayer(
    Canvas canvas,
    Iterable<PatternTileSummary> summaries,
    double opacity,
  ) {
    if (opacity <= 0) return 0;
    final positions = <Offset>[];
    final colors = <Color>[];
    for (final summary in summaries) {
      final tileRect = _tileRect(summary);
      final tileRows = math.min(
        summary.blockSize,
        document.grid.dimensions.rows -
            summary.coordinate.row * summary.blockSize,
      );
      final tileColumns = math.min(
        summary.blockSize,
        document.grid.dimensions.columns -
            summary.coordinate.column * summary.blockSize,
      );
      final density = summary.populatedCellCount / (tileRows * tileColumns);
      final averageColor = symbolRenderCache.weightedAverageColorFor(
        summary.symbolCounts,
      );
      final densityColor = settings.showCellColor && averageColor != null
          ? averageColor.withValues(
              alpha: settings.cellColorOpacity * density * opacity,
            )
          : _gridColor.withValues(alpha: 0.18 * density * opacity);
      _addOverviewRectVertices(positions, colors, tileRect, densityColor);
    }
    if (positions.isEmpty) return 0;
    canvas.drawVertices(
      ui.Vertices(ui.VertexMode.triangles, positions, colors: colors),
      ui.BlendMode.srcOver,
      _overviewDensityPaint,
    );
    return 1;
  }

  /// Appends two colored triangles that cover one overview summary rectangle.
  void _addOverviewRectVertices(
    List<Offset> positions,
    List<Color> colors,
    Rect rect,
    Color color,
  ) {
    positions
      ..add(rect.topLeft)
      ..add(rect.topRight)
      ..add(rect.bottomRight)
      ..add(rect.topLeft)
      ..add(rect.bottomRight)
      ..add(rect.bottomLeft);
    colors
      ..add(color)
      ..add(color)
      ..add(color)
      ..add(color)
      ..add(color)
      ..add(color);
  }

  /// Paints dynamic completion and pending-selection accents at one summary level.
  int _paintOverviewAccents(
    Canvas canvas,
    Iterable<PatternTileSummary> summaries,
    int blockSize,
    double opacity,
  ) {
    if (opacity <= 0) return 0;
    final pendingPaint = Paint()
      ..color = completionSelectionColor.withValues(alpha: 0.4 * opacity);
    final completedPaint = Paint()
      ..color = _completedOverlayColor.withValues(
        alpha: settings.completedCellOpacity * 0.45 * opacity,
      );
    final completedCoordinates =
        completedOverviewCoordinates[blockSize] ??
        const <PatternTileCoordinate>{};
    final pendingCoordinates =
        pendingOverviewCoordinates?[blockSize] ??
        completionSelection
            .map(
              (coordinate) => PatternTileCoordinate(
                coordinate.row ~/ blockSize,
                coordinate.column ~/ blockSize,
              ),
            )
            .toSet();
    final completedPath = Path();
    final pendingPath = Path();
    var hasCompletedTiles = false;
    var hasPendingTiles = false;
    for (final summary in summaries) {
      final tileRect = _tileRect(summary);
      if (settings.showCompletedCellOverlay &&
          completedCoordinates.contains(summary.coordinate)) {
        completedPath.addRect(tileRect);
        hasCompletedTiles = true;
      }
      if (pendingCoordinates.contains(summary.coordinate)) {
        pendingPath.addRect(tileRect);
        hasPendingTiles = true;
      }
    }
    var drawCallCount = 0;
    if (hasCompletedTiles) {
      canvas.drawPath(completedPath, completedPaint);
      drawCallCount++;
    }
    if (hasPendingTiles) {
      canvas.drawPath(pendingPath, pendingPaint);
      drawCallCount++;
    }
    return drawCallCount;
  }

  /// Calculates the full screen-space rectangle occupied by one summary.
  Rect _tileRect(PatternTileSummary summary) {
    final blockSize = summary.blockSize;
    final coordinate = summary.coordinate;
    final startRow = coordinate.row * blockSize;
    final startColumn = coordinate.column * blockSize;
    final endRow = math.min(
      startRow + blockSize,
      document.grid.dimensions.rows,
    );
    final endColumn = math.min(
      startColumn + blockSize,
      document.grid.dimensions.columns,
    );
    return Rect.fromLTWH(
      camera.origin.dx + startColumn * camera.cellSize,
      camera.origin.dy + startRow * camera.cellSize,
      (endColumn - startColumn) * camera.cellSize,
      (endRow - startRow) * camera.cellSize,
    );
  }
}

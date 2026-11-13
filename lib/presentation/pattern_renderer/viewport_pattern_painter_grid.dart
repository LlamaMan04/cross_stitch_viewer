part of 'viewport_pattern_painter.dart';

/// Paints the document background and visible grid rules.
extension _ViewportPatternPainterGrid on ViewportPatternPainter {
  /// Paints the document rectangle without iterating through empty cells.
  void _paintDocumentBackground(Canvas canvas) {
    // One rectangle represents both populated and empty document cells.
    final dimensions = document.grid.dimensions;
    final documentRect = Rect.fromLTWH(
      camera.origin.dx,
      camera.origin.dy,
      dimensions.columns * camera.cellSize,
      dimensions.rows * camera.cellSize,
    );
    canvas.drawRect(documentRect, Paint()..color = surfaceColor);
  }

  /// Paints only visible minor, ten-cell, and document-edge rules.
  _LayerBatchMetrics _paintGrid(Canvas canvas) {
    if (visibleBounds.isEmpty) return const _LayerBatchMetrics();
    _minorGridPaint.strokeWidth = math.min(1.0, camera.cellSize * 0.18);
    _majorGridPaint.strokeWidth = math.min(2.0, camera.cellSize * 0.3);
    _outsideGridPaint.strokeWidth = math.min(2.25, camera.cellSize * 0.38);
    // Visible endpoints bound both the horizontal and vertical rule segments.
    final dimensions = document.grid.dimensions;
    final left = camera.origin.dx + visibleBounds.startColumn * camera.cellSize;
    final right = camera.origin.dx + visibleBounds.endColumn * camera.cellSize;
    final top = camera.origin.dy + visibleBounds.startRow * camera.cellSize;
    final bottom = camera.origin.dy + visibleBounds.endRow * camera.cellSize;
    final minorPath = Path();
    final majorPath = Path();
    final outsidePath = Path();
    var minorCount = 0;
    var majorCount = 0;
    var outsideCount = 0;

    final overview = renderLod == RenderLod.overview;
    for (final row in _ruleCoordinates(
      visibleBounds.startRow,
      visibleBounds.endRow,
      overview,
      dimensions.rows,
    )) {
      final y = camera.origin.dy + row * camera.cellSize;
      final path = _rulePath(
        coordinate: row,
        documentExtent: dimensions.rows,
        minorPath: minorPath,
        majorPath: majorPath,
        outsidePath: outsidePath,
      );
      path
        ..moveTo(left, y)
        ..lineTo(right, y);
      if (identical(path, outsidePath)) {
        outsideCount++;
      } else if (identical(path, majorPath)) {
        majorCount++;
      } else {
        minorCount++;
      }
    }
    for (final column in _ruleCoordinates(
      visibleBounds.startColumn,
      visibleBounds.endColumn,
      overview,
      dimensions.columns,
    )) {
      final x = camera.origin.dx + column * camera.cellSize;
      final path = _rulePath(
        coordinate: column,
        documentExtent: dimensions.columns,
        minorPath: minorPath,
        majorPath: majorPath,
        outsidePath: outsidePath,
      );
      path
        ..moveTo(x, top)
        ..lineTo(x, bottom);
      if (identical(path, outsidePath)) {
        outsideCount++;
      } else if (identical(path, majorPath)) {
        majorCount++;
      } else {
        minorCount++;
      }
    }
    var drawCallCount = 0;
    if (minorCount > 0) {
      canvas.drawPath(minorPath, _minorGridPaint);
      drawCallCount++;
    }
    if (majorCount > 0) {
      canvas.drawPath(majorPath, _majorGridPaint);
      drawCallCount++;
    }
    if (outsideCount > 0) {
      canvas.drawPath(outsidePath, _outsideGridPaint);
      drawCallCount++;
    }
    return _LayerBatchMetrics(
      primitiveCount: minorCount + majorCount + outsideCount,
      drawCallCount: drawCallCount,
    );
  }

  /// Yields every visible rule or only ten-cell rules in overview mode.
  Iterable<int> _ruleCoordinates(
    int start,
    int end,
    bool majorOnly,
    int documentExtent,
  ) sync* {
    if (!majorOnly) {
      for (var coordinate = start; coordinate <= end; coordinate++) {
        yield coordinate;
      }
      return;
    }
    final firstMajor = ((start + 9) ~/ 10) * 10;
    for (var coordinate = firstMajor; coordinate <= end; coordinate += 10) {
      yield coordinate;
    }
    if (documentExtent >= start &&
        documentExtent <= end &&
        documentExtent % 10 != 0) {
      yield documentExtent;
    }
  }

  /// Selects the batched path for a rule at [coordinate].
  Path _rulePath({
    required int coordinate,
    required int documentExtent,
    required Path minorPath,
    required Path majorPath,
    required Path outsidePath,
  }) {
    final isOutside = coordinate == 0 || coordinate == documentExtent;
    final isMajor = coordinate % 10 == 0;
    if (isOutside) return outsidePath;
    if (isMajor) return majorPath;
    return minorPath;
  }
}

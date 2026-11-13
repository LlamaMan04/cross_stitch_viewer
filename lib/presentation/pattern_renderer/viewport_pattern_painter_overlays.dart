part of 'viewport_pattern_painter.dart';

/// Paints dynamic selections, progress, regions, and backstitches.
extension _ViewportPatternPainterOverlays on ViewportPatternPainter {
  /// Creates the shared stroke configuration for backstitch lines.
  Paint _backstitchPaint() => Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = backstitchStrokeWidth
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Paints beneath selected lines so their normal thread color stays visible.
  Paint _backstitchSelectionPaint() => Paint()
    ..color = _parseColor(settings.selectionHighlightColor.colorHex)
    ..style = PaintingStyle.stroke
    ..strokeWidth = backstitchStrokeWidth + 4
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  /// Paints viewport-relevant lines above grid and region outlines.
  int _paintBackstitches(Canvas canvas) {
    final lines = visibleBackstitches;
    if (lines.isEmpty) return 0;
    var drawCalls = 0;
    final selectedThreadId = selection.hasBackstitchSelection
        ? selection.threadId
        : null;
    if (selectedThreadId != null) {
      final highlightPaint = _backstitchSelectionPaint();
      for (final line in lines) {
        if (line.threadId != selectedThreadId) continue;
        final segment = line.segment;
        canvas.drawLine(
          camera.gridToScreen(
            row: segment.start.row,
            column: segment.start.column,
          ),
          camera.gridToScreen(row: segment.end.row, column: segment.end.column),
          highlightPaint,
        );
        drawCalls++;
      }
    }
    final paint = _backstitchPaint();
    for (final line in lines) {
      final segment = line.segment;
      paint.color = settings.showCellColor ? line.threadColor : Colors.black;
      canvas.drawLine(
        camera.gridToScreen(
          row: segment.start.row,
          column: segment.start.column,
        ),
        camera.gridToScreen(row: segment.end.row, column: segment.end.column),
        paint,
      );
    }
    return drawCalls + lines.length;
  }

  /// Paints a high-contrast theme-color overlay on selected exact cells.
  int _paintCompletionSelection(Canvas canvas) {
    if (completionSelection.isEmpty || renderLod == RenderLod.overview) {
      return 0;
    }
    final overlayPaint = Paint()..color = completionSelectionOverlayColor;
    var count = 0;
    for (final coordinate in completionSelection) {
      _dynamicOverlayCandidatesVisited++;
      if (!visibleBounds.contains(coordinate)) continue;
      final cell = document.grid.cellAt(coordinate);
      if (cell == null) continue;
      canvas.drawRect(_cellRect(cell), overlayPaint);
      count++;
    }
    _dynamicOverlayPrimitivesPainted += count;
    return count;
  }

  /// Paints a translucent accent and outline across selected visible cells.
  int _paintSelectedSymbol(Canvas canvas) {
    if (!selection.hasSelection || renderLod == RenderLod.overview) return 0;
    final highlightColor = _parseColor(
      settings.selectionHighlightColor.colorHex,
    );
    final fillPaint = Paint()..color = highlightColor.withValues(alpha: 0.22);
    final outlinePaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(2, camera.cellSize * 0.16);
    var count = 0;
    for (final cell in selectedVisibleCells) {
      final cellRect = _cellRect(cell);
      canvas.drawRect(cellRect, fillPaint);
      canvas.drawRect(
        cellRect.deflate(outlinePaint.strokeWidth / 2),
        outlinePaint,
      );
      count++;
    }
    _dynamicOverlayPrimitivesPainted += count * 2;
    return count;
  }

  /// Paints the configured neutral overlay on completed visible cells.
  int _paintCompletedCells(Canvas canvas) {
    if (completedCells.isEmpty || renderLod == RenderLod.overview) return 0;
    var count = 0;
    for (final cell in completedVisibleCells) {
      canvas.drawRect(_cellRect(cell), _completedOverlayPaint);
      count++;
    }
    _dynamicOverlayPrimitivesPainted += count;
    return count;
  }

  /// Paints outlines for source regions intersecting the visible grid range.
  int _paintRegions(Canvas canvas) {
    final paint = Paint()
      ..color = regionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    var count = 0;
    for (final region in document.regionsIntersecting(visibleBounds)) {
      final regionRect = Rect.fromLTWH(
        camera.origin.dx + region.origin.column * camera.cellSize,
        camera.origin.dy + region.origin.row * camera.cellSize,
        region.columns * camera.cellSize,
        region.rows * camera.cellSize,
      );
      canvas.drawRect(regionRect, paint);
      count++;
    }
    return count;
  }
}

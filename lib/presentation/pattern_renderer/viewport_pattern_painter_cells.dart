part of 'viewport_pattern_painter.dart';

/// Paints populated cell fills and symbol glyphs for the viewport painter.
extension _ViewportPatternPainterCells on ViewportPatternPainter {
  /// Paints configured thread-color fills for visible populated cells.
  _LayerBatchMetrics _paintCellFills(Canvas canvas) {
    if (!settings.showCellColor || renderLod == RenderLod.overview) {
      return const _LayerBatchMetrics();
    }
    return _paintCellFillsForCells(canvas, _visibleCells, _cellRect);
  }

  /// Batches thread-color fills for [cells] using caller-supplied rectangles.
  _LayerBatchMetrics _paintCellFillsForCells(
    Canvas canvas,
    Iterable<StitchCell> cells,
    Rect Function(StitchCell cell) rectForCell,
  ) {
    final batches = <int, _CellFillBatch>{};
    var fillCount = 0;
    for (final cell in cells) {
      final fillPaint = symbolRenderCache.fillPaintFor(
        cell.symbolId,
        settings.cellColorOpacity,
      );
      if (fillPaint == null) continue;
      final colorKey = fillPaint.color.toARGB32();
      final batch = batches.putIfAbsent(
        colorKey,
        () => _CellFillBatch(fillPaint),
      );
      batch.path.addRect(rectForCell(cell));
      fillCount++;
    }
    for (final batch in batches.values) {
      canvas.drawPath(batch.path, batch.paint);
    }
    return _LayerBatchMetrics(
      primitiveCount: fillCount,
      drawCallCount: batches.length,
    );
  }

  /// Paints glyphs after dynamic overlays so symbols remain legible.
  int _paintGlyphs(Canvas canvas) {
    if (!settings.showSymbols || renderLod != RenderLod.detail) return 0;
    return _paintGlyphsForCells(
      canvas,
      _visibleCells,
      _cellRect,
      camera.cellSize,
    );
  }

  /// Paints immutable glyphs for [cells] at the supplied recording scale.
  int _paintGlyphsForCells(
    Canvas canvas,
    Iterable<StitchCell> cells,
    Rect Function(StitchCell cell) rectForCell,
    double cellSize,
  ) {
    var count = 0;
    for (final cell in cells) {
      final metadata = symbolRenderCache.metadataFor(cell.symbolId);
      if (metadata == null) continue;
      _paintGlyph(
        canvas,
        rectForCell(cell),
        metadata.symbol,
        _staticCellBackground(metadata),
        cellSize,
      );
      count++;
    }
    return count;
  }

  /// Resolves the immutable background used for cached glyph contrast.
  Color _staticCellBackground(PatternSymbolRenderMetadata metadata) {
    var background = surfaceColor;
    if (settings.showCellColor) {
      background = Color.alphaBlend(
        metadata.threadColor.withValues(alpha: settings.cellColorOpacity),
        background,
      );
    }
    return background;
  }

  /// Calculates one cell's screen-space rectangle.
  Rect _cellRect(StitchCell cell) => Rect.fromLTWH(
    camera.origin.dx + cell.coordinate.column * camera.cellSize,
    camera.origin.dy + cell.coordinate.row * camera.cellSize,
    camera.cellSize,
    camera.cellSize,
  );

  /// Paints a centered symbol glyph with contrast against its thread color.
  void _paintGlyph(
    Canvas canvas,
    Rect rect,
    SymbolDefinition symbol,
    Color backgroundColor,
    double cellSize,
  ) {
    // Choose a non-color-dependent foreground contrast for each glyph.
    final foreground = backgroundColor.computeLuminance() > 0.45
        ? Colors.black87
        : Colors.white;
    // Text metrics are cached because many cells share the same symbol style.
    final textPainter = glyphLayoutCache.layoutFor(
      glyph: symbol.displayGlyph,
      foreground: foreground,
      fontSize: (cellSize * 0.58).clamp(12, 32),
    );
    textPainter.paint(
      canvas,
      rect.center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}

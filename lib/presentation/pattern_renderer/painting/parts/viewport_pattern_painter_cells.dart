part of '../viewport_pattern_painter.dart';

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
    final requestedFontSize = (cellSize * 0.58).clamp(12.0, 32.0);
    final glyphPictureCache = this.glyphPictureCache;
    if (glyphPictureCache == null) {
      _paintGlyphLayout(
        canvas,
        rect,
        symbol.displayGlyph,
        foreground,
        requestedFontSize,
      );
      return;
    }
    final fontSizeBucket = PatternGlyphPictureCache.quantizeFontSize(
      requestedFontSize,
    );
    final key = PatternGlyphPictureKey(
      glyph: symbol.displayGlyph,
      foreground: foreground,
      fontSizeBucket: fontSizeBucket,
      fontFamily: PatternGlyphLayoutCache.fontFamily,
      fontWeight: PatternGlyphLayoutCache.fontWeight.value,
      textDirection: PatternGlyphLayoutCache.textDirection,
      rendererGeneration: glyphRendererGeneration,
    );
    var lease = glyphPictureCache.acquire(key);
    lease ??= _recordGlyphPicture(
      cache: glyphPictureCache,
      key: key,
      fontSize: PatternGlyphPictureCache.fontSizeForBucket(fontSizeBucket),
    );
    if (lease == null) {
      _paintGlyphLayout(
        canvas,
        rect,
        symbol.displayGlyph,
        foreground,
        requestedFontSize,
      );
      return;
    }
    try {
      final glyphPicture = lease.glyphPicture;
      canvas.save();
      canvas.translate(
        rect.center.dx - glyphPicture.width / 2,
        rect.center.dy - glyphPicture.height / 2,
      );
      canvas.drawPicture(glyphPicture.picture);
      canvas.restore();
    } finally {
      lease.release();
    }
  }

  /// Records a layout into a reusable picture or disposes a rejected recording.
  PatternGlyphPictureLease? _recordGlyphPicture({
    required PatternGlyphPictureCache cache,
    required PatternGlyphPictureKey key,
    required double fontSize,
  }) {
    final textPainter = glyphLayoutCache.layoutFor(
      glyph: key.glyph,
      foreground: key.foreground,
      fontSize: fontSize,
    );
    final recorder = ui.PictureRecorder();
    final recordingCanvas = Canvas(recorder);
    textPainter.paint(recordingCanvas, Offset.zero);
    final picture = recorder.endRecording();
    final glyphPicture = PatternGlyphPicture(
      picture: picture,
      width: textPainter.width,
      height: textPainter.height,
      estimatedByteSize: 64 + picture.approximateBytesUsed,
    );
    final lease = cache.putAndAcquire(key, glyphPicture);
    if (lease == null) glyphPicture.dispose();
    return lease;
  }

  /// Paints an uncached layout when recording is unavailable or rejected.
  void _paintGlyphLayout(
    Canvas canvas,
    Rect rect,
    String glyph,
    Color foreground,
    double fontSize,
  ) {
    // Text metrics remain cached for direct fallback and cache recording.
    final textPainter = glyphLayoutCache.layoutFor(
      glyph: glyph,
      foreground: foreground,
      fontSize: fontSize,
    );
    textPainter.paint(
      canvas,
      rect.center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}

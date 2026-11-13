part of 'viewport_pattern_painter.dart';

/// Prepares, records, and replays cached static source tiles.
extension _ViewportPatternPainterTiles on ViewportPatternPainter {
  /// Resolves cached or direct static content for every visible source tile.
  _StaticTileFrame _prepareStaticTileFrame() {
    final cache = tilePictureCache!;
    final hasFillLayer =
        settings.showCellColor && renderLod != RenderLod.overview;
    final hasGlyphLayer = settings.showSymbols && renderLod == RenderLod.detail;
    if ((!hasFillLayer && !hasGlyphLayer) || visibleBounds.isEmpty) {
      return const _StaticTileFrame();
    }
    final query = visibleBounds.clampTo(document.grid.dimensions);
    if (query.isEmpty) return const _StaticTileFrame();

    final cellSizeBucket = PatternTilePictureCache.quantizeCellSize(
      camera.cellSize,
    );
    final style = PatternTilePictureStyle(
      showCellColor: settings.showCellColor,
      cellColorOpacity: settings.cellColorOpacity,
      showSymbols: settings.showSymbols,
      surfaceColor: surfaceColor,
    );
    final recorder = PatternStaticTileRecorder(
      document: document,
      cache: cache,
      renderLod: renderLod,
      cellSizeBucket: cellSizeBucket,
      style: style,
      recordPictures: _recordStaticTilePictures,
    );
    final contents = <_StaticTileContent>[];
    var cacheHitCount = 0;
    var cacheMissCount = 0;
    var cacheBypassCount = 0;
    var recordingsStarted = 0;
    var recordingsCompleted = 0;
    var recordingsRejected = 0;
    final firstTileRow = query.startRow ~/ PatternGrid.tileSize;
    final lastTileRow = (query.endRow - 1) ~/ PatternGrid.tileSize;
    final firstTileColumn = query.startColumn ~/ PatternGrid.tileSize;
    final lastTileColumn = (query.endColumn - 1) ~/ PatternGrid.tileSize;
    for (var tileRow = firstTileRow; tileRow <= lastTileRow; tileRow++) {
      for (
        var tileColumn = firstTileColumn;
        tileColumn <= lastTileColumn;
        tileColumn++
      ) {
        final coordinate = PatternTileCoordinate(tileRow, tileColumn);
        final resolution = recorder.resolve(coordinate);
        if (resolution.cacheHit) cacheHitCount++;
        if (resolution.cacheMiss) cacheMissCount++;
        if (resolution.cacheBypass) cacheBypassCount++;
        if (resolution.recordingStarted) recordingsStarted++;
        if (resolution.recordingCompleted) recordingsCompleted++;
        if (resolution.recordingRejected) recordingsRejected++;
        contents.add(
          _StaticTileContent.resolved(
            coordinate: coordinate,
            recordedCellSize: recorder.recordedCellSize,
            resolution: resolution,
          ),
        );
      }
    }
    return _StaticTileFrame(
      contents: contents,
      cacheHitCount: cacheHitCount,
      cacheMissCount: cacheMissCount,
      cacheBypassCount: cacheBypassCount,
      recordingsStarted: recordingsStarted,
      recordingsCompleted: recordingsCompleted,
      recordingsRejected: recordingsRejected,
    );
  }

  /// Records tile-local base and foreground pictures at one scale bucket.
  PatternTilePictures _recordStaticTilePictures({
    required PatternTileCoordinate coordinate,
    required double recordedCellSize,
    required List<StitchCell> cells,
  }) {
    ui.Picture? fillPicture;
    var fillMetrics = const _LayerBatchMetrics();
    if (settings.showCellColor) {
      final recorder = ui.PictureRecorder();
      final recordingCanvas = Canvas(recorder);
      fillMetrics = _paintCellFillsForCells(
        recordingCanvas,
        cells,
        (cell) => _tileLocalCellRect(cell, coordinate, recordedCellSize),
      );
      final recordedPicture = recorder.endRecording();
      if (fillMetrics.primitiveCount == 0) {
        recordedPicture.dispose();
      } else {
        fillPicture = recordedPicture;
      }
    }

    ui.Picture? glyphPicture;
    var glyphCount = 0;
    if (settings.showSymbols && renderLod == RenderLod.detail) {
      final recorder = ui.PictureRecorder();
      final recordingCanvas = Canvas(recorder);
      glyphCount = _paintGlyphsForCells(
        recordingCanvas,
        cells,
        (cell) => _tileLocalCellRect(cell, coordinate, recordedCellSize),
        recordedCellSize,
      );
      final recordedPicture = recorder.endRecording();
      if (glyphCount == 0) {
        recordedPicture.dispose();
      } else {
        glyphPicture = recordedPicture;
      }
    }

    final estimatedByteSize =
        128 +
        (fillPicture?.approximateBytesUsed ?? 0) +
        (glyphPicture?.approximateBytesUsed ?? 0);
    return PatternTilePictures(
      fillPicture: fillPicture,
      glyphPicture: glyphPicture,
      cellFillCount: fillMetrics.primitiveCount,
      cellFillSourceDrawCalls: fillMetrics.drawCallCount,
      glyphCount: glyphCount,
      estimatedByteSize: estimatedByteSize,
    );
  }

  /// Calculates a cell rectangle relative to its recorded tile origin.
  Rect _tileLocalCellRect(
    StitchCell cell,
    PatternTileCoordinate coordinate,
    double cellSize,
  ) => Rect.fromLTWH(
    (cell.coordinate.column - coordinate.column * PatternGrid.tileSize) *
        cellSize,
    (cell.coordinate.row - coordinate.row * PatternGrid.tileSize) * cellSize,
    cellSize,
    cellSize,
  );

  /// Replays one tile-local picture at the camera's exact scale and origin.
  void _drawTilePicture(
    Canvas canvas,
    ui.Picture picture,
    PatternTileCoordinate coordinate,
    double recordedCellSize,
  ) {
    canvas.save();
    canvas.translate(
      camera.origin.dx +
          coordinate.column * PatternGrid.tileSize * camera.cellSize,
      camera.origin.dy +
          coordinate.row * PatternGrid.tileSize * camera.cellSize,
    );
    final scale = camera.cellSize / recordedCellSize;
    canvas.scale(scale, scale);
    canvas.drawPicture(picture);
    canvas.restore();
  }
}

/// Static tile content resolved for one painter invocation.
class _StaticTileFrame {
  /// Creates a frame from cached, ephemeral, or direct tile content.
  const _StaticTileFrame({
    this.contents = const <_StaticTileContent>[],
    this.cacheHitCount = 0,
    this.cacheMissCount = 0,
    this.cacheBypassCount = 0,
    this.recordingsStarted = 0,
    this.recordingsCompleted = 0,
    this.recordingsRejected = 0,
  });

  /// Visible tile content retained for the duration of this paint frame.
  final List<_StaticTileContent> contents;

  /// Number of visible tiles replayed from retained cache entries.
  final int cacheHitCount;

  /// Number of visible tiles that required direct or newly recorded content.
  final int cacheMissCount;

  /// Number of visible tiles intentionally painted directly during zoom.
  final int cacheBypassCount;

  /// Number of static-tile recordings started during this frame.
  final int recordingsStarted;

  /// Number of recordings that reached a completed display list this frame.
  final int recordingsCompleted;

  /// Number of recordings rejected by the cache during this frame.
  final int recordingsRejected;

  /// Counts direct fill primitives submitted for the supplied [painter].
  int directCellFillCountFor(ViewportPatternPainter painter) {
    if (!painter.settings.showCellColor ||
        painter.renderLod == RenderLod.overview) {
      return 0;
    }
    return contents.fold(
      0,
      (count, content) => count + (content.cells?.length ?? 0),
    );
  }

  /// Counts direct glyph primitives submitted for the supplied [painter].
  int directGlyphPaintCountFor(ViewportPatternPainter painter) {
    if (!painter.settings.showSymbols ||
        painter.renderLod != RenderLod.detail) {
      return 0;
    }
    return contents.fold(
      0,
      (count, content) => count + (content.cells?.length ?? 0),
    );
  }

  /// Number of populated cells represented by this frame's visible tiles.
  int get visibleCellCount => contents.fold(
    0,
    (count, content) =>
        count +
        (content.pictures == null
            ? content.cells?.length ?? 0
            : math.max(
                content.pictures!.cellFillCount,
                content.pictures!.glyphCount,
              )),
  );

  /// Paints cached or direct thread-color fills below dynamic overlays.
  _LayerBatchMetrics paintFills(Canvas canvas, ViewportPatternPainter painter) {
    if (!painter.settings.showCellColor ||
        painter.renderLod == RenderLod.overview) {
      return const _LayerBatchMetrics();
    }
    var primitiveCount = 0;
    var drawCallCount = 0;
    for (final content in contents) {
      final pictures = content.pictures;
      if (pictures != null) {
        primitiveCount += pictures.cellFillCount;
        final picture = pictures.fillPicture;
        if (picture != null) {
          painter._drawTilePicture(
            canvas,
            picture,
            content.coordinate,
            content.recordedCellSize,
          );
          drawCallCount++;
        }
        continue;
      }
      final metrics = painter._paintCellFillsForCells(
        canvas,
        content.cells!,
        painter._cellRect,
      );
      primitiveCount += metrics.primitiveCount;
      drawCallCount += metrics.drawCallCount;
    }
    return _LayerBatchMetrics(
      primitiveCount: primitiveCount,
      drawCallCount: drawCallCount,
    );
  }

  /// Paints cached or direct glyphs above dynamic overlays.
  _LayerBatchMetrics paintGlyphs(
    Canvas canvas,
    ViewportPatternPainter painter,
  ) {
    if (!painter.settings.showSymbols ||
        painter.renderLod != RenderLod.detail) {
      return const _LayerBatchMetrics();
    }
    var primitiveCount = 0;
    var drawCallCount = 0;
    for (final content in contents) {
      final pictures = content.pictures;
      if (pictures != null) {
        primitiveCount += pictures.glyphCount;
        final picture = pictures.glyphPicture;
        if (picture != null) {
          painter._drawTilePicture(
            canvas,
            picture,
            content.coordinate,
            content.recordedCellSize,
          );
          drawCallCount++;
        }
        continue;
      }
      final glyphCount = painter._paintGlyphsForCells(
        canvas,
        content.cells!,
        painter._cellRect,
        painter.camera.cellSize,
      );
      primitiveCount += glyphCount;
      drawCallCount += glyphCount;
    }
    return _LayerBatchMetrics(
      primitiveCount: primitiveCount,
      drawCallCount: drawCallCount,
    );
  }

  /// Releases frame leases and ephemeral pictures after both layers paint.
  void release() {
    for (final content in contents) {
      content.release();
    }
  }
}

/// One visible tile represented by a lease, ephemeral pictures, or cells.
class _StaticTileContent {
  /// Creates tile content whose resolution owns every native resource.
  const _StaticTileContent.resolved({
    required this.coordinate,
    required this.recordedCellSize,
    required this.resolution,
  });

  /// Source tile coordinate used to place tile-local pictures.
  final PatternTileCoordinate coordinate;

  /// Quantized logical cell size used while recording tile-local pictures.
  final double recordedCellSize;

  /// Result supplying cached pictures, temporary pictures, or source cells.
  final PatternStaticTileResolution resolution;

  /// Source cells used when cache writes are suspended during interaction.
  List<StitchCell>? get cells => resolution.cells;

  /// Recorded pictures represented by this content, if any.
  PatternTilePictures? get pictures => resolution.pictures;

  /// Releases retained or ephemeral native resources after painting.
  void release() {
    resolution.release();
  }
}

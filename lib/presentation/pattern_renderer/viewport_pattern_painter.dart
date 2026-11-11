import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/progress_models.dart';
import '../../domain/value_objects.dart';
import 'pattern_camera.dart';
import 'pattern_glyph_layout_cache.dart';
import 'pattern_render_selection.dart';
import 'pattern_symbol_render_cache.dart';
import 'pattern_tile_picture_cache.dart';
import 'pattern_viewport_controller.dart';
import 'render_lod.dart';

/// Counts batched primitives and canvas calls for one renderer frame.
class PatternRenderBatchMetrics {
  /// Creates immutable measurements for the two batched static layers.
  const PatternRenderBatchMetrics({
    required this.cellFillCount,
    required this.cellFillDrawCalls,
    required this.gridRuleCount,
    required this.gridDrawCalls,
    required this.visibleCellCount,
    required this.glyphCount,
    required this.drawCallCount,
    this.tilePictureHits = 0,
    this.tilePictureMisses = 0,
    this.tilePictureCacheEntries = 0,
    this.tilePictureCacheBytes = 0,
    this.tilePictureEvictions = 0,
    this.tilePictureBypasses = 0,
  });

  /// Number of populated-cell rectangles included in fill paths.
  final int cellFillCount;

  /// Number of color-grouped fill paths submitted to the canvas.
  final int cellFillDrawCalls;

  /// Number of visible horizontal and vertical rules included in grid paths.
  final int gridRuleCount;

  /// Number of minor, major, or outside grid paths submitted to the canvas.
  final int gridDrawCalls;

  /// Number of populated cells materialized for this visible paint frame.
  final int visibleCellCount;

  /// Number of glyph layouts painted in this frame.
  final int glyphCount;

  /// Number of canvas draw calls issued by the measured renderer layers.
  final int drawCallCount;

  /// Number of static source tiles replayed from the picture cache.
  final int tilePictureHits;

  /// Number of static source tiles absent from the picture cache.
  final int tilePictureMisses;

  /// Number of tile entries retained after this paint frame.
  final int tilePictureCacheEntries;

  /// Estimated native display-list bytes retained after this paint frame.
  final int tilePictureCacheBytes;

  /// Number of budget-driven tile evictions over the cache lifetime.
  final int tilePictureEvictions;

  /// Number of tiles painted directly because zoom temporarily bypassed reuse.
  final int tilePictureBypasses;
}

/// Paints only the pattern cells and rules intersecting visible grid bounds.
class ViewportPatternPainter extends CustomPainter {
  /// Creates a painter from immutable document, camera, bounds, and theme data.
  ViewportPatternPainter({
    required this.document,
    required PatternCamera camera,
    required GridBounds visibleBounds,
    required this.settings,
    required this.selection,
    required this.completedCells,
    required this.completionSelection,
    required this.surfaceColor,
    required this.regionColor,
    required this.completionSelectionColor,
    required this.glyphLayoutCache,
    required this.symbolRenderCache,
    required RenderLod renderLod,
    required this.completedOverviewCoordinates,
    this.pendingOverviewCoordinates,
    this.onBatchMetrics,
    this.tilePictureCache,
    this.cameraController,
    this.viewportSize,
  }) : _staticGeometry = _StaticPaintGeometry(
         camera: camera,
         visibleBounds: visibleBounds,
         renderLod: renderLod,
       ),
       assert(
         (cameraController == null) == (viewportSize == null),
         'A notifier-driven painter requires its viewport size.',
       ),
       super(repaint: cameraController);

  /// Normalized source document rendered by this painter.
  final PatternDocument document;

  /// Geometry used when no notifier-driven controller is supplied.
  final _StaticPaintGeometry _staticGeometry;

  /// Optional notifier supplying camera values without widget rebuilds.
  final PatternViewportController? cameraController;

  /// Fixed paint-surface size used for notifier-driven visible bounds.
  final Size? viewportSize;

  /// Camera used for the current interaction or direct painter invocation.
  PatternCamera get camera =>
      cameraController?.camera ?? _staticGeometry.camera;

  /// Current half-open grid range derived from the active camera.
  GridBounds get visibleBounds {
    final dynamicViewportSize = viewportSize;
    if (cameraController == null || dynamicViewportSize == null) {
      return _staticGeometry.visibleBounds;
    }
    return camera.visibleBounds(
      viewportSize: dynamicViewportSize,
      dimensions: document.grid.dimensions,
    );
  }

  /// Persisted visual switches and colors for this paint pass.
  final PatternRenderSettings settings;

  /// Ephemeral symbol selection highlighted during this paint pass.
  final PatternRenderSelection selection;

  /// Completed grid coordinates used by dynamic cell overlays.
  final Set<GridCoordinate> completedCells;

  /// Exact coordinates selected for a pending completion action.
  final Set<GridCoordinate> completionSelection;

  /// Background color used for the viewport and empty cells.
  final Color surfaceColor;

  /// Theme color used for enabled source-region outlines.
  final Color regionColor;

  /// Primary application color used by completion-selection overlays.
  final Color completionSelectionColor;

  /// Shared glyph layouts retained across otherwise short-lived painters.
  final PatternGlyphLayoutCache glyphLayoutCache;

  /// Parsed symbol colors and fill paints shared across viewport painters.
  final PatternSymbolRenderCache symbolRenderCache;

  /// Shared bounded cache that survives short-lived painter delegates.
  final PatternTilePictureCache? tilePictureCache;

  /// Detail level retained by the camera controller across paint frames.
  RenderLod get renderLod =>
      cameraController?.renderLod ?? _staticGeometry.renderLod;

  /// Completed summary blocks indexed by every supported overview resolution.
  final Map<int, Set<PatternTileCoordinate>> completedOverviewCoordinates;

  /// Optional pre-indexed pending completion blocks by overview resolution.
  final Map<int, Set<PatternTileCoordinate>>? pendingOverviewCoordinates;

  /// Optional profiling hook called after the batched layers are painted.
  final ValueChanged<PatternRenderBatchMetrics>? onBatchMetrics;

  /// Completed-cell color and opacity resolved once for this paint delegate.
  late final Color _completedOverlayColor = _parseColor(
    settings.completedCellColor.colorHex,
  ).withValues(alpha: settings.completedCellOpacity);

  /// Paint reused for every completed-cell overlay in this delegate.
  late final Paint _completedOverlayPaint = Paint()
    ..color = _completedOverlayColor;

  /// Parsed grid color shared by every rule-class paint in this delegate.
  late final Color _gridColor = _parseColor(settings.gridColor.colorHex);

  /// Paint reused for the path containing every visible minor grid rule.
  late final Paint _minorGridPaint = Paint()
    ..color = _gridColor
    ..style = PaintingStyle.stroke;

  /// Paint reused for the path containing every visible ten-cell grid rule.
  late final Paint _majorGridPaint = Paint()
    ..color = _gridColor
    ..style = PaintingStyle.stroke;

  /// Paint reused for the path containing visible document-edge rules.
  late final Paint _outsideGridPaint = Paint()
    ..color = _gridColor
    ..style = PaintingStyle.stroke;

  /// Reused paint for overview density rectangles.
  late final Paint _overviewDensityPaint = Paint();

  /// Bounds associated with the current cached visible-cell snapshot.
  GridBounds? _cachedCellBounds;

  /// Populated cells cached for all layers in the current visible range.
  List<StitchCell>? _cachedVisibleCells;

  /// Visible cells materialized once and refreshed only when bounds change.
  List<StitchCell> get _visibleCells {
    final currentBounds = visibleBounds;
    if (_cachedCellBounds != currentBounds || _cachedVisibleCells == null) {
      _cachedCellBounds = currentBounds;
      _cachedVisibleCells = List<StitchCell>.unmodifiable(
        document.grid.cellsIntersecting(currentBounds),
      );
    }
    return _cachedVisibleCells!;
  }

  /// Completed populated cells intersecting the current visible bounds.
  Iterable<StitchCell> get completedVisibleCells sync* {
    for (final cell in _visibleCells) {
      if (completedCells.contains(cell.coordinate)) yield cell;
    }
  }

  /// Matching visible cells used by selection painting and focused tests.
  Iterable<StitchCell> get selectedVisibleCells sync* {
    final selectedSymbolId = selection.selectedSymbolId;
    if (selectedSymbolId == null) return;
    for (final cell in _visibleCells) {
      final isExcludedCompletedCell =
          !settings.includeCompletedCellsInSelection &&
          completedCells.contains(cell.coordinate);
      if (cell.symbolId == selectedSymbolId && !isExcludedCompletedCell) {
        yield cell;
      }
    }
  }

  /// Paints the visible document background, cells, glyphs, and grid rules.
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surfaceColor);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintDocumentBackground(canvas);
    var drawCallCount = 2;
    if (renderLod == RenderLod.overview) {
      drawCallCount += _paintOverviewTiles(canvas);
    }
    final staticTileFrame = tilePictureCache == null
        ? null
        : _prepareStaticTileFrame();
    try {
      final fillMetrics = staticTileFrame == null
          ? _paintCellFills(canvas)
          : staticTileFrame.paintFills(canvas, this);
      drawCallCount += fillMetrics.drawCallCount;
      final completedCount = settings.showCompletedCellOverlay
          ? _paintCompletedCells(canvas)
          : 0;
      drawCallCount += completedCount;
      final selectedCount = _paintSelectedSymbol(canvas);
      drawCallCount += selectedCount * 2;
      final completionSelectionCount = _paintCompletionSelection(canvas);
      drawCallCount += completionSelectionCount;
      final glyphMetrics = staticTileFrame == null
          ? _LayerBatchMetrics(
              primitiveCount: _paintGlyphs(canvas),
              drawCallCount:
                  renderLod == RenderLod.detail && settings.showSymbols
                  ? _cachedVisibleCells?.length ?? 0
                  : 0,
            )
          : staticTileFrame.paintGlyphs(canvas, this);
      drawCallCount += glyphMetrics.drawCallCount;
      final gridMetrics = settings.showGrid
          ? _paintGrid(canvas)
          : const _LayerBatchMetrics();
      drawCallCount += gridMetrics.drawCallCount;
      if (settings.showRegions) {
        drawCallCount += _paintRegions(canvas);
      }
      canvas.restore();
      onBatchMetrics?.call(
        PatternRenderBatchMetrics(
          cellFillCount: fillMetrics.primitiveCount,
          cellFillDrawCalls: fillMetrics.drawCallCount,
          gridRuleCount: gridMetrics.primitiveCount,
          gridDrawCalls: gridMetrics.drawCallCount,
          visibleCellCount: renderLod == RenderLod.overview
              ? 0
              : staticTileFrame?.visibleCellCount ??
                  _cachedVisibleCells?.length ??
                  0,
          glyphCount: glyphMetrics.primitiveCount,
          drawCallCount: drawCallCount,
          tilePictureHits: staticTileFrame?.cacheHitCount ?? 0,
          tilePictureMisses: staticTileFrame?.cacheMissCount ?? 0,
          tilePictureCacheEntries: tilePictureCache?.entryCount ?? 0,
          tilePictureCacheBytes: tilePictureCache?.estimatedBytes ?? 0,
          tilePictureEvictions: tilePictureCache?.evictionCount ?? 0,
          tilePictureBypasses: staticTileFrame?.cacheBypassCount ?? 0,
        ),
      );
    } finally {
      staticTileFrame?.release();
    }
  }

  /// Theme-derived color used to overlay exact completion-cell selections.
  Color get completionSelectionOverlayColor {
    final overlayOpacity = math.max(0.55, settings.completedCellOpacity);
    return completionSelectionColor.withValues(alpha: overlayOpacity);
  }

  /// Paints a high-contrast theme-color overlay on selected exact cells.
  int _paintCompletionSelection(Canvas canvas) {
    if (completionSelection.isEmpty || renderLod == RenderLod.overview) {
      return 0;
    }
    final overlayPaint = Paint()..color = completionSelectionOverlayColor;
    var count = 0;
    for (final coordinate in completionSelection) {
      if (!visibleBounds.contains(coordinate)) continue;
      final cell = document.grid.cellAt(coordinate);
      if (cell == null) continue;
      canvas.drawRect(_cellRect(cell), overlayPaint);
      count++;
    }
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
    return count;
  }

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
    final recordedCellSize = PatternTilePictureCache.cellSizeForBucket(
      cellSizeBucket,
    );
    final style = PatternTilePictureStyle(
      showCellColor: settings.showCellColor,
      cellColorOpacity: settings.cellColorOpacity,
      showSymbols: settings.showSymbols,
      surfaceColor: surfaceColor,
    );
    final contents = <_StaticTileContent>[];
    var cacheHitCount = 0;
    var cacheMissCount = 0;
    var cacheBypassCount = 0;
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
        final key = PatternTilePictureKey(
          documentIdentity: document,
          coordinate: coordinate,
          renderLod: renderLod,
          cellSizeBucket: cellSizeBucket,
          style: style,
        );
        final lease = cache.reuseEnabled ? cache.acquire(key) : null;
        if (lease != null) {
          cacheHitCount++;
          contents.add(
            _StaticTileContent.cached(
              coordinate: coordinate,
              recordedCellSize: recordedCellSize,
              lease: lease,
            ),
          );
          continue;
        }

        if (cache.reuseEnabled) {
          cacheMissCount++;
        } else {
          cacheBypassCount++;
        }
        final tileBounds = _tileBounds(coordinate);
        final tileCells = List<StitchCell>.unmodifiable(
          document.grid.cellsIntersecting(tileBounds),
        );
        if (!cache.writesEnabled || !cache.reuseEnabled) {
          contents.add(
            _StaticTileContent.direct(
              coordinate: coordinate,
              recordedCellSize: recordedCellSize,
              cells: tileCells,
            ),
          );
          continue;
        }

        final pictures = _recordStaticTilePictures(
          coordinate: coordinate,
          recordedCellSize: recordedCellSize,
          cells: tileCells,
        );
        final insertedLease = cache.putAndAcquire(key, pictures);
        contents.add(
          insertedLease == null
              ? _StaticTileContent.ephemeral(
                  coordinate: coordinate,
                  recordedCellSize: recordedCellSize,
                  pictures: pictures,
                )
              : _StaticTileContent.cached(
                  coordinate: coordinate,
                  recordedCellSize: recordedCellSize,
                  lease: insertedLease,
                ),
        );
      }
    }
    return _StaticTileFrame(
      contents: contents,
      cacheHitCount: cacheHitCount,
      cacheMissCount: cacheMissCount,
      cacheBypassCount: cacheBypassCount,
    );
  }

  /// Calculates document-clamped source bounds for one fixed spatial tile.
  GridBounds _tileBounds(PatternTileCoordinate coordinate) {
    final startRow = coordinate.row * PatternGrid.tileSize;
    final startColumn = coordinate.column * PatternGrid.tileSize;
    return GridBounds(
      startRow: startRow,
      endRow: math.min(
        startRow + PatternGrid.tileSize,
        document.grid.dimensions.rows,
      ),
      startColumn: startColumn,
      endColumn: math.min(
        startColumn + PatternGrid.tileSize,
        document.grid.dimensions.columns,
      ),
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
    var drawCallCount = 0;
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
      _overviewDensityPaint.color = densityColor;
      canvas.drawRect(tileRect, _overviewDensityPaint);
      drawCallCount++;
    }
    return drawCallCount;
  }

  /// Paints dynamic completion and selection accents at one summary level.
  int _paintOverviewAccents(
    Canvas canvas,
    Iterable<PatternTileSummary> summaries,
    int blockSize,
    double opacity,
  ) {
    if (opacity <= 0) return 0;
    final selectedSymbolId = selection.selectedSymbolId;
    final selectedColor = _parseColor(settings.selectionHighlightColor.colorHex)
        .withValues(alpha: opacity);
    final selectedPaint = Paint()
      ..color = selectedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(2, camera.cellSize * 2);
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
    var drawCallCount = 0;
    for (final summary in summaries) {
      final tileRect = _tileRect(summary);
      if (settings.showCompletedCellOverlay &&
          completedCoordinates.contains(summary.coordinate)) {
        canvas.drawRect(tileRect, completedPaint);
        drawCallCount++;
      }
      if (selectedSymbolId != null &&
          summary.symbolCounts.containsKey(selectedSymbolId)) {
        canvas.drawRect(
          tileRect.deflate(selectedPaint.strokeWidth / 2),
          selectedPaint,
        );
        drawCallCount++;
      }
      if (pendingCoordinates.contains(summary.coordinate)) {
        canvas.drawRect(tileRect, pendingPaint);
        drawCallCount++;
      }
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

  /// Converts a validated domain `#RRGGBB` value into an opaque Flutter color.
  Color _parseColor(String value) =>
      Color(int.parse('FF${value.substring(1)}', radix: 16));

  /// Repaints when any visible rendering input changes.
  @override
  bool shouldRepaint(ViewportPatternPainter oldDelegate) =>
      oldDelegate.document != document ||
      oldDelegate.cameraController != cameraController ||
      oldDelegate.camera != camera ||
      oldDelegate.visibleBounds != visibleBounds ||
      oldDelegate.settings != settings ||
      oldDelegate.selection != selection ||
      !setEquals(oldDelegate.completedCells, completedCells) ||
      !setEquals(oldDelegate.completionSelection, completionSelection) ||
      oldDelegate.renderLod != renderLod ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.regionColor != regionColor ||
      oldDelegate.completionSelectionColor != completionSelectionColor;
}

/// Accumulates same-color cell rectangles into one canvas path.
class _CellFillBatch {
  /// Creates a fill batch that will be submitted with [paint].
  _CellFillBatch(this.paint);

  /// Shared color and opacity used for every rectangle in [path].
  final Paint paint;

  /// Visible cell rectangles sharing [paint].
  final Path path = Path();
}

/// Reports primitive and canvas-call counts for one batched layer.
class _LayerBatchMetrics {
  /// Creates layer metrics, defaulting to an inactive layer.
  const _LayerBatchMetrics({this.primitiveCount = 0, this.drawCallCount = 0});

  /// Number of source rectangles or lines accumulated into paths.
  final int primitiveCount;

  /// Number of paths submitted to the canvas.
  final int drawCallCount;
}

/// Static tile content resolved for one painter invocation.
class _StaticTileFrame {
  /// Creates a frame from cached, ephemeral, or direct tile content.
  const _StaticTileFrame({
    this.contents = const <_StaticTileContent>[],
    this.cacheHitCount = 0,
    this.cacheMissCount = 0,
    this.cacheBypassCount = 0,
  });

  /// Visible tile content retained for the duration of this paint frame.
  final List<_StaticTileContent> contents;

  /// Number of visible tiles replayed from retained cache entries.
  final int cacheHitCount;

  /// Number of visible tiles that required direct or newly recorded content.
  final int cacheMissCount;

  /// Number of visible tiles intentionally painted directly during zoom.
  final int cacheBypassCount;

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
  /// Creates tile content protected by a cache [lease].
  const _StaticTileContent.cached({
    required this.coordinate,
    required this.recordedCellSize,
    required this._lease,
  }) : _ephemeralPictures = null,
       cells = null;

  /// Creates over-budget tile content disposed after this frame.
  const _StaticTileContent.ephemeral({
    required this.coordinate,
    required this.recordedCellSize,
    required PatternTilePictures pictures,
  }) : _lease = null,
       _ephemeralPictures = pictures,
       cells = null;

  /// Creates uncached tile content painted directly during camera activity.
  const _StaticTileContent.direct({
    required this.coordinate,
    required this.recordedCellSize,
    required this.cells,
  }) : _lease = null,
       _ephemeralPictures = null;

  /// Source tile coordinate used to place tile-local pictures.
  final PatternTileCoordinate coordinate;

  /// Quantized logical cell size used while recording tile-local pictures.
  final double recordedCellSize;

  /// Retained cache entry used by this frame, if available.
  final PatternTilePictureLease? _lease;

  /// Rejected over-budget pictures owned only by this frame.
  final PatternTilePictures? _ephemeralPictures;

  /// Source cells used when cache writes are suspended during interaction.
  final List<StitchCell>? cells;

  /// Recorded pictures represented by this content, if any.
  PatternTilePictures? get pictures => _lease?.pictures ?? _ephemeralPictures;

  /// Releases retained or ephemeral native resources after painting.
  void release() {
    _lease?.release();
    _ephemeralPictures?.dispose();
  }
}

/// Groups fixed geometry for direct, non-notifier painter use.
class _StaticPaintGeometry {
  /// Creates one immutable direct-paint geometry snapshot.
  const _StaticPaintGeometry({
    required this.camera,
    required this.visibleBounds,
    required this.renderLod,
  });

  /// Camera supplied when the painter was constructed.
  final PatternCamera camera;

  /// Half-open bounds supplied when the painter was constructed.
  final GridBounds visibleBounds;

  /// Detail level supplied when the painter was constructed.
  final RenderLod renderLod;
}

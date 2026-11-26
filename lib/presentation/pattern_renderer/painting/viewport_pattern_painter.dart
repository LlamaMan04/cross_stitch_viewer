import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../domain/pattern_definitions.dart';
import '../../../domain/pattern_document.dart';
import '../../../domain/pattern_grid.dart';
import '../../../domain/progress_models.dart';
import '../../../domain/value_objects.dart';
import '../cache/pattern_glyph_layout_cache.dart';
import '../cache/pattern_glyph_picture_cache.dart';
import '../cache/pattern_symbol_render_cache.dart';
import '../cache/pattern_tile_picture_cache.dart';
import '../tiles/pattern_static_frame_reuse.dart';
import '../tiles/pattern_static_tile_recorder.dart';
import '../tiles/pattern_tile_prefetch_coordinator.dart';
import '../viewport/pattern_camera.dart';
import '../viewport/completed_cell_tile_index.dart';
import '../viewport/pattern_render_selection.dart';
import '../viewport/pattern_viewport_bounds.dart';
import '../viewport/pattern_viewport_controller.dart';
import '../viewport/render_lod.dart';

part 'parts/viewport_pattern_painter_cells.dart';
part 'parts/viewport_pattern_painter_grid.dart';
part 'parts/viewport_pattern_painter_metrics.dart';
part 'parts/viewport_pattern_painter_overlays.dart';
part 'parts/viewport_pattern_painter_overview.dart';
part 'parts/viewport_pattern_painter_tiles.dart';

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
    CompletedCellTileIndex? completedCellTileIndex,
    required this.completionSelection,
    required this.surfaceColor,
    required this.regionColor,
    required this.completionSelectionColor,
    required this.glyphLayoutCache,
    this.glyphPictureCache,
    this.glyphRendererGeneration = 0,
    required this.symbolRenderCache,
    required RenderLod renderLod,
    required this.completedOverviewCoordinates,
    this.pendingOverviewCoordinates,
    this.onBatchMetrics,
    this.tilePictureCache,
    this.tilePrefetchCoordinator,
    this.cameraController,
    this.viewportSize,
    this.prefetchTileDistance =
        PatternViewportBounds.defaultPrefetchTileDistance,
    this.maximumSynchronousTileRecordingsDuringPan = 1,
    this.staticFrameReuse,
  }) : completedCellTileIndex =
           completedCellTileIndex ?? CompletedCellTileIndex(completedCells),
       _staticGeometry = _StaticPaintGeometry(
         camera: camera,
         visibleBounds: visibleBounds,
         renderLod: renderLod,
       ),
       assert(
         (cameraController == null) == (viewportSize == null),
         'A notifier-driven painter requires its viewport size.',
       ),
       assert(prefetchTileDistance >= 0),
       assert(maximumSynchronousTileRecordingsDuringPan >= 0),
       super(repaint: cameraController);

  /// Normalized source document rendered by this painter.
  final PatternDocument document;

  /// Geometry used when no notifier-driven controller is supplied.
  final _StaticPaintGeometry _staticGeometry;

  /// Optional notifier supplying camera values without widget rebuilds.
  final PatternViewportController? cameraController;

  /// Fixed paint-surface size used for notifier-driven visible bounds.
  final Size? viewportSize;

  /// Number of source tiles expanded around the paint range for cache warming.
  final int prefetchTileDistance;

  /// Maximum visible tile pictures recorded synchronously in one pan frame.
  ///
  /// Additional cache misses paint directly and are warmed after the frame.
  final int maximumSynchronousTileRecordingsDuringPan;

  /// Viewport-owned leases used to replay the prior static layer while panning.
  final PatternStaticFrameReuse? staticFrameReuse;

  /// Camera used for the current interaction or direct painter invocation.
  PatternCamera get camera =>
      cameraController?.camera ?? _staticGeometry.camera;

  /// Current document-clamped grid range that this painter may draw.
  GridBounds get paintBounds {
    final dynamicViewportSize = viewportSize;
    if (cameraController == null || dynamicViewportSize == null) {
      return _staticGeometry.visibleBounds;
    }
    return PatternViewportBounds.calculate(
      camera: camera,
      viewportSize: dynamicViewportSize,
      dimensions: document.grid.dimensions,
      prefetchTileDistance: prefetchTileDistance,
    ).paintBounds;
  }

  /// Current paint range retained for existing renderer consumers.
  GridBounds get visibleBounds => paintBounds;

  /// Persisted visual switches and colors for this paint pass.
  final PatternRenderSettings settings;

  /// Ephemeral symbol selection highlighted during this paint pass.
  final PatternRenderSelection selection;

  /// Completed grid coordinates used by dynamic cell overlays.
  final Set<GridCoordinate> completedCells;

  /// Tile-local completed coordinates used to avoid scanning visible stitches.
  final CompletedCellTileIndex completedCellTileIndex;

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

  /// Shared cache that owns recorded glyph display lists for Phase 2 replay.
  final PatternGlyphPictureCache? glyphPictureCache;

  /// Generation that distinguishes pictures recorded before a font change.
  final int glyphRendererGeneration;

  /// Parsed symbol colors and fill paints shared across viewport painters.
  final PatternSymbolRenderCache symbolRenderCache;

  /// Shared bounded cache that survives short-lived painter delegates.
  final PatternTilePictureCache? tilePictureCache;

  /// Viewport-owned coordinator that warms nearby static tile pictures.
  final PatternTilePrefetchCoordinator? tilePrefetchCoordinator;

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

  /// Opaque paint used with per-vertex colors for overview density batches.
  late final Paint _overviewDensityPaint = Paint()..color = Colors.white;

  /// Bounds associated with the current cached visible-cell snapshot.
  GridBounds? _cachedCellBounds;

  /// Populated cells cached for all layers in the current visible range.
  List<StitchCell>? _cachedVisibleCells;

  /// Dynamic-overlay candidates inspected while painting the current frame.
  int _dynamicOverlayCandidatesVisited = 0;

  /// Dynamic-overlay primitives submitted while painting the current frame.
  int _dynamicOverlayPrimitivesPainted = 0;

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

  /// Bounds associated with the current cached backstitch snapshot.
  GridBounds? _cachedBackstitchBounds;

  /// Immutable visible backstitches shared by all backstitch layers.
  List<BackstitchRenderMetadata>? _cachedBackstitches;

  /// Returns the current visible segment snapshot without scanning at overview.
  List<BackstitchRenderMetadata> get visibleBackstitches {
    if (renderLod == RenderLod.overview) return const [];
    final bounds = visibleBounds;
    if (_cachedBackstitchBounds != bounds || _cachedBackstitches == null) {
      _cachedBackstitchBounds = bounds;
      _cachedBackstitches = symbolRenderCache.backstitchesIntersecting(bounds);
    }
    return _cachedBackstitches!;
  }

  /// Minimum screen-space backstitch width, exceeding major grid rules.
  static const double minimumBackstitchStrokeWidth = 2.5;

  /// Maximum screen-space backstitch width at high zoom.
  static const double maximumBackstitchStrokeWidth = 6;

  /// Fraction of a cell used to size backstitch strokes.
  static const double backstitchStrokeScale = 0.1;

  /// Current bounded screen-space width of backstitch strokes.
  double get backstitchStrokeWidth => (camera.cellSize * backstitchStrokeScale)
      .clamp(minimumBackstitchStrokeWidth, maximumBackstitchStrokeWidth);

  /// Completed populated cells intersecting the current visible bounds.
  Iterable<StitchCell> get completedVisibleCells sync* {
    for (final coordinate in completedCellTileIndex.coordinatesIntersecting(
      visibleBounds,
    )) {
      _dynamicOverlayCandidatesVisited++;
      final cell = document.grid.cellAt(coordinate);
      if (cell != null) yield cell;
    }
  }

  /// Matching visible cells used by selection painting and focused tests.
  Iterable<StitchCell> get selectedVisibleCells sync* {
    if (renderLod == RenderLod.overview) return;
    final selectedThreadId = selection.hasSymbolSelection
        ? selection.threadId
        : null;
    if (selectedThreadId == null) return;
    for (final cell in _visibleCells) {
      _dynamicOverlayCandidatesVisited++;
      final isExcludedCompletedCell =
          !settings.includeCompletedCellsInSelection &&
          completedCells.contains(cell.coordinate);
      final metadata = symbolRenderCache.metadataFor(cell.symbolId);
      if (metadata?.threadId == selectedThreadId && !isExcludedCompletedCell) {
        yield cell;
      }
    }
  }

  /// Paints the visible document background, cells, glyphs, and grid rules.
  @override
  void paint(Canvas canvas, Size size) {
    _dynamicOverlayCandidatesVisited = 0;
    _dynamicOverlayPrimitivesPainted = 0;
    canvas.drawRect(Offset.zero & size, Paint()..color = surfaceColor);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintDocumentBackground(canvas);
    var drawCallCount = 2;
    if (renderLod == RenderLod.overview) {
      drawCallCount += _paintOverviewTiles(canvas);
    }
    final recorder = createStaticTileRecorder();
    final reuse = staticFrameReuse;
    final canReplayRetainedFrame =
        cameraController?.interactionState ==
            PatternViewportInteractionState.panning &&
        recorder != null &&
        reuse?.canReplay(recorder: recorder, camera: camera) == true;
    final retainedCoordinates = canReplayRetainedFrame
        ? reuse!.coordinatesIntersecting(visibleBounds)
        : const <PatternTileCoordinate>{};
    final staticTileFrame = tilePictureCache == null
        ? null
        : _prepareStaticTileFrame(excludedCoordinates: retainedCoordinates);
    try {
      final retainedFillCount = canReplayRetainedFrame
          ? reuse!.paintLayer(
              canvas: canvas,
              camera: camera,
              bounds: visibleBounds,
              dimensions: document.grid.dimensions,
              pictureFor: (pictures) => pictures.fillPicture,
              countFor: (pictures) => pictures.cellFillCount,
            )
          : 0;
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
      final retainedGlyphCount = canReplayRetainedFrame
          ? reuse!.paintLayer(
              canvas: canvas,
              camera: camera,
              bounds: visibleBounds,
              dimensions: document.grid.dimensions,
              pictureFor: (pictures) => pictures.glyphPicture,
              countFor: (pictures) => pictures.glyphCount,
            )
          : 0;
      drawCallCount += glyphMetrics.drawCallCount;
      final gridMetrics = settings.showGrid
          ? _paintGrid(canvas)
          : const _LayerBatchMetrics();
      drawCallCount += gridMetrics.drawCallCount;
      if (settings.showRegions) {
        drawCallCount += _paintRegions(canvas);
      }
      drawCallCount += _paintBackstitches(canvas);
      _submitTilePrefetch();
      canvas.restore();
      onBatchMetrics?.call(
        PatternRenderBatchMetrics(
          cellFillCount: fillMetrics.primitiveCount + retainedFillCount,
          cellFillDrawCalls: fillMetrics.drawCallCount,
          gridRuleCount: gridMetrics.primitiveCount,
          gridDrawCalls: gridMetrics.drawCallCount,
          visibleCellCount: renderLod == RenderLod.overview
              ? 0
              : staticTileFrame?.visibleCellCount ??
                    _cachedVisibleCells?.length ??
                    0,
          glyphCount: glyphMetrics.primitiveCount + retainedGlyphCount,
          drawCallCount: drawCallCount,
          tilePictureHits: staticTileFrame?.cacheHitCount ?? 0,
          tilePictureMisses: staticTileFrame?.cacheMissCount ?? 0,
          tilePictureCacheEntries: tilePictureCache?.entryCount ?? 0,
          tilePictureCacheBytes: tilePictureCache?.estimatedBytes ?? 0,
          tilePictureEvictions: tilePictureCache?.evictionCount ?? 0,
          glyphPictureCacheEntries: glyphPictureCache?.entryCount ?? 0,
          glyphPictureCacheBytes: glyphPictureCache?.estimatedBytes ?? 0,
          glyphPictureCacheHits: glyphPictureCache?.hitCount ?? 0,
          glyphPictureCacheMisses: glyphPictureCache?.missCount ?? 0,
          glyphPictureCacheEvictions: glyphPictureCache?.evictionCount ?? 0,
          tilePictureBypasses: staticTileFrame?.cacheBypassCount ?? 0,
          directCellFillCount:
              staticTileFrame?.directCellFillCountFor(this) ??
              fillMetrics.primitiveCount,
          directGlyphPaintCount:
              staticTileFrame?.directGlyphPaintCountFor(this) ??
              glyphMetrics.primitiveCount,
          tileRecordingsStarted: staticTileFrame?.recordingsStarted ?? 0,
          tileRecordingsCompleted: staticTileFrame?.recordingsCompleted ?? 0,
          tileRecordingsRejected: staticTileFrame?.recordingsRejected ?? 0,
          tileRecordingsQueued:
              tilePrefetchCoordinator?.queuedRequestCount ?? 0,
          prefetchRequests: tilePrefetchCoordinator?.requestCount ?? 0,
          prefetchedTiles: tilePrefetchCoordinator?.prefetchedTileCount ?? 0,
          cancelledPrefetchRequests:
              tilePrefetchCoordinator?.cancelledRequestCount ?? 0,
          stalePrefetchRequests:
              tilePrefetchCoordinator?.staleRequestCount ?? 0,
          dynamicOverlayCandidatesVisited: _dynamicOverlayCandidatesVisited,
          dynamicOverlayPrimitivesPainted: _dynamicOverlayPrimitivesPainted,
          gridPathsRecorded: gridMetrics.drawCallCount,
          cameraOriginX: camera.origin.dx,
          cameraOriginY: camera.origin.dy,
          cameraCellSize: camera.cellSize,
          renderLod: renderLod,
          interactionState:
              cameraController?.interactionState ??
              PatternViewportInteractionState.settled,
        ),
      );
      if (recorder != null &&
          cameraController?.interactionState ==
              PatternViewportInteractionState.settled) {
        reuse?.capture(
          coordinates: staticTileFrame?.coordinates ?? const [],
          recorder: recorder,
          camera: camera,
        );
      }
    } finally {
      staticTileFrame?.release();
    }
  }

  /// Theme-derived color used to overlay exact completion-cell selections.
  Color get completionSelectionOverlayColor {
    final overlayOpacity = math.max(0.55, settings.completedCellOpacity);
    return completionSelectionColor.withValues(alpha: overlayOpacity);
  }

  /// Converts a validated domain `#RRGGBB` value into an opaque Flutter color.
  Color _parseColor(String value) =>
      Color(int.parse('FF${value.substring(1)}', radix: 16));

  /// Defers nearby static tile recordings until after this frame is complete.
  void _submitTilePrefetch() {
    final coordinator = tilePrefetchCoordinator;
    final cache = tilePictureCache;
    final controller = cameraController;
    final size = viewportSize;
    final recorder = createStaticTileRecorder();
    if (coordinator == null ||
        cache == null ||
        controller == null ||
        size == null ||
        recorder == null) {
      return;
    }
    coordinator.submit(
      camera: camera,
      renderLod: renderLod,
      bounds: PatternViewportBounds.calculate(
        camera: camera,
        viewportSize: size,
        dimensions: document.grid.dimensions,
        prefetchTileDistance: prefetchTileDistance,
      ),
      revision: controller.cameraRevision,
      recorder: recorder,
      requestRepaint: controller.requestRepaint,
    );
  }

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
      oldDelegate.completionSelectionColor != completionSelectionColor ||
      oldDelegate.glyphRendererGeneration != glyphRendererGeneration;
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

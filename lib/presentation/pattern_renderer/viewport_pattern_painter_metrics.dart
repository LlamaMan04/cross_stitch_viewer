part of 'viewport_pattern_painter.dart';

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
    this.directCellFillCount = 0,
    this.directGlyphPaintCount = 0,
    this.tileRecordingsStarted = 0,
    this.tileRecordingsCompleted = 0,
    this.tileRecordingsRejected = 0,
    this.tileRecordingsQueued = 0,
    this.prefetchRequests = 0,
    this.prefetchedTiles = 0,
    this.cancelledPrefetchRequests = 0,
    this.stalePrefetchRequests = 0,
    this.dynamicOverlayCandidatesVisited = 0,
    this.dynamicOverlayPrimitivesPainted = 0,
    this.gridPathsRecorded = 0,
    this.gridPathsReplayed = 0,
    this.cameraOriginX = 0,
    this.cameraOriginY = 0,
    this.cameraCellSize = 0,
    this.renderLod = RenderLod.detail,
    this.interactionState = PatternViewportInteractionState.settled,
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

  /// Number of cell fills issued directly instead of replayed from a tile.
  final int directCellFillCount;

  /// Number of glyph paints issued directly instead of replayed from a tile.
  final int directGlyphPaintCount;

  /// Number of tile display-list recordings begun during this paint frame.
  final int tileRecordingsStarted;

  /// Number of tile display-list recordings completed during this paint frame.
  final int tileRecordingsCompleted;

  /// Number of completed recordings rejected by the tile cache budget.
  final int tileRecordingsRejected;

  /// Number of tile recordings deferred to a later frame.
  final int tileRecordingsQueued;

  /// Number of prefetch requests created during this paint frame.
  final int prefetchRequests;

  /// Number of prefetched tiles made available during this paint frame.
  final int prefetchedTiles;

  /// Number of prefetch requests cancelled during this paint frame.
  final int cancelledPrefetchRequests;

  /// Number of prefetch requests discarded because their camera revision aged.
  final int stalePrefetchRequests;

  /// Number of dynamic-overlay candidates inspected before visibility filtering.
  final int dynamicOverlayCandidatesVisited;

  /// Number of dynamic-overlay primitives submitted to the canvas.
  final int dynamicOverlayPrimitivesPainted;

  /// Number of grid paths assembled and recorded during this paint frame.
  final int gridPathsRecorded;

  /// Number of cached grid paths replayed during this paint frame.
  final int gridPathsReplayed;

  /// Horizontal screen-space origin of the camera for this frame.
  final double cameraOriginX;

  /// Vertical screen-space origin of the camera for this frame.
  final double cameraOriginY;

  /// Logical cell size used by the camera for this frame.
  final double cameraCellSize;

  /// Level of detail used by the renderer for this frame.
  final RenderLod renderLod;

  /// Whether this frame was settled, panning, or zooming.
  final PatternViewportInteractionState interactionState;

  /// Whether the frame was driven by an active pan or zoom gesture.
  bool get isInteractive =>
      interactionState != PatternViewportInteractionState.settled;
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

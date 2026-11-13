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

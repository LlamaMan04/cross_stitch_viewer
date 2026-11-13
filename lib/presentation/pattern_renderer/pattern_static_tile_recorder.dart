import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import 'pattern_tile_picture_cache.dart';
import 'render_lod.dart';

/// Records the static pictures for one source tile using painter-owned visuals.
typedef PatternStaticTilePictureRecorder = PatternTilePictures Function({
  required PatternTileCoordinate coordinate,
  required double recordedCellSize,
  required List<StitchCell> cells,
});

/// Identifies how a static tile was supplied to a paint or prefetch consumer.
enum PatternStaticTileResolutionSource {
  /// A retained cache entry supplied the tile pictures.
  cached,

  /// Source cells must be painted directly because caching is unavailable.
  direct,

  /// A new recorded picture is owned temporarily by this resolution.
  temporary,
}

/// Owns a static tile result until the paint or prefetch consumer releases it.
class PatternStaticTileResolution {
  /// Creates a resolution backed by one of a cache lease, cells, or pictures.
  PatternStaticTileResolution._({
    required this.source,
    this.lease,
    this.cells,
    this.temporaryPictures,
    required this.cacheHit,
    required this.cacheMiss,
    required this.cacheBypass,
    required this.recordingStarted,
    required this.recordingCompleted,
    required this.recordingRejected,
  });

  /// Origin of the static tile content.
  final PatternStaticTileResolutionSource source;

  /// Optional cache lease protecting retained pictures during painting.
  final PatternTilePictureLease? lease;

  /// Source cells used when no picture can be replayed.
  final List<StitchCell>? cells;

  /// Pictures rejected by the cache and owned until [release].
  final PatternTilePictures? temporaryPictures;

  /// Whether a retained cache entry supplied this result.
  final bool cacheHit;

  /// Whether an enabled cache had no matching retained entry.
  final bool cacheMiss;

  /// Whether cache reuse was deliberately bypassed for this result.
  final bool cacheBypass;

  /// Whether this result began recording a tile picture.
  final bool recordingStarted;

  /// Whether this result completed recording a tile picture.
  final bool recordingCompleted;

  /// Whether the completed picture exceeded the cache budget.
  final bool recordingRejected;

  /// Pictures available for replay, if this result was recorded or cached.
  PatternTilePictures? get pictures => lease?.pictures ?? temporaryPictures;

  /// Releases a cache lease or disposes temporary native pictures exactly once.
  void release() {
    lease?.release();
    temporaryPictures?.dispose();
  }
}

/// Shares cache-key creation, sparse lookup, and picture ownership for tiles.
class PatternStaticTileRecorder {
  /// Creates a resolver for one document, visual signature, detail level, and
  /// quantized cell-size bucket.
  PatternStaticTileRecorder({
    required this.document,
    required this.cache,
    required this.renderLod,
    required this.cellSizeBucket,
    required this.style,
    required this.recordPictures,
  }) : recordedCellSize = PatternTilePictureCache.cellSizeForBucket(
         cellSizeBucket,
       );

  /// Immutable document supplying source cells for every resolved tile.
  final PatternDocument document;

  /// Shared bounded cache that owns accepted static pictures.
  final PatternTilePictureCache cache;

  /// Detail level represented by the static pictures.
  final RenderLod renderLod;

  /// Quantized cell-size identity for cache keys and recording geometry.
  final int cellSizeBucket;

  /// Representative logical size used while recording tile-local pictures.
  final double recordedCellSize;

  /// Static visual inputs that affect recorded picture appearance.
  final PatternTilePictureStyle style;

  /// Painter-owned function that records the fill and glyph display lists.
  final PatternStaticTilePictureRecorder recordPictures;

  /// Creates the cache key for [coordinate] from this resolver's fixed inputs.
  PatternTilePictureKey keyFor(PatternTileCoordinate coordinate) =>
      PatternTilePictureKey(
        documentIdentity: document,
        coordinate: coordinate,
        renderLod: renderLod,
        cellSizeBucket: cellSizeBucket,
        style: style,
      );

  /// Calculates the document-clamped bounds occupied by [coordinate].
  GridBounds tileBoundsFor(PatternTileCoordinate coordinate) {
    final startRow = coordinate.row * PatternGrid.tileSize;
    final startColumn = coordinate.column * PatternGrid.tileSize;
    return GridBounds(
      startRow: startRow,
      endRow: (startRow + PatternGrid.tileSize).clamp(
        0,
        document.grid.dimensions.rows,
      ),
      startColumn: startColumn,
      endColumn: (startColumn + PatternGrid.tileSize).clamp(
        0,
        document.grid.dimensions.columns,
      ),
    );
  }

  /// Looks up populated source cells for [coordinate] without scanning others.
  List<StitchCell> cellsFor(PatternTileCoordinate coordinate) =>
      List<StitchCell>.unmodifiable(
        document.grid.cellsIntersecting(tileBoundsFor(coordinate)),
      );

  /// Returns cached, direct, or temporary tile content with safe ownership.
  PatternStaticTileResolution resolve(PatternTileCoordinate coordinate) {
    final key = keyFor(coordinate);
    final lease = cache.reuseEnabled ? cache.acquire(key) : null;
    if (lease != null) {
      return PatternStaticTileResolution._(
        source: PatternStaticTileResolutionSource.cached,
        lease: lease,
        cacheHit: true,
        cacheMiss: false,
        cacheBypass: false,
        recordingStarted: false,
        recordingCompleted: false,
        recordingRejected: false,
      );
    }

    final cells = cellsFor(coordinate);
    if (!cache.writesEnabled || !cache.reuseEnabled) {
      return PatternStaticTileResolution._(
        source: PatternStaticTileResolutionSource.direct,
        cells: cells,
        cacheHit: false,
        cacheMiss: cache.reuseEnabled,
        cacheBypass: !cache.reuseEnabled,
        recordingStarted: false,
        recordingCompleted: false,
        recordingRejected: false,
      );
    }

    final pictures = recordPictures(
      coordinate: coordinate,
      recordedCellSize: recordedCellSize,
      cells: cells,
    );
    final insertedLease = cache.putAndAcquire(key, pictures);
    if (insertedLease != null) {
      return PatternStaticTileResolution._(
        source: PatternStaticTileResolutionSource.cached,
        lease: insertedLease,
        cacheHit: false,
        cacheMiss: true,
        cacheBypass: false,
        recordingStarted: true,
        recordingCompleted: true,
        recordingRejected: false,
      );
    }
    return PatternStaticTileResolution._(
      source: PatternStaticTileResolutionSource.temporary,
      temporaryPictures: pictures,
      cacheHit: false,
      cacheMiss: true,
      cacheBypass: false,
      recordingStarted: true,
      recordingCompleted: true,
      recordingRejected: true,
    );
  }
}

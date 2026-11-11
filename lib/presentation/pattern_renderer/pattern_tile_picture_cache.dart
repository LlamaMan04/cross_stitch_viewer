import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/pattern_grid.dart';
import 'render_lod.dart';

/// Static renderer settings that affect recorded tile pictures.
class PatternTilePictureStyle {
  /// Creates the immutable visual signature for one cached tile.
  const PatternTilePictureStyle({
    required this.showCellColor,
    required this.cellColorOpacity,
    required this.showSymbols,
    required this.surfaceColor,
  });

  /// Whether thread-color fills are recorded in the tile base picture.
  final bool showCellColor;

  /// Opacity applied to thread-color fills in the tile base picture.
  final double cellColorOpacity;

  /// Whether detail-level glyphs are recorded in the foreground picture.
  final bool showSymbols;

  /// Background color used to choose a contrasting glyph foreground.
  final Color surfaceColor;

  /// Compares every visual input that changes static tile output.
  @override
  bool operator ==(Object other) =>
      other is PatternTilePictureStyle &&
      showCellColor == other.showCellColor &&
      cellColorOpacity == other.cellColorOpacity &&
      showSymbols == other.showSymbols &&
      surfaceColor == other.surfaceColor;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode =>
      Object.hash(showCellColor, cellColorOpacity, showSymbols, surfaceColor);
}

/// Stable identity for one recorded static tile representation.
class PatternTilePictureKey {
  /// Creates a key from document, tile, detail, scale, and style inputs.
  const PatternTilePictureKey({
    required this.documentIdentity,
    required this.coordinate,
    required this.renderLod,
    required this.cellSizeBucket,
    required this.style,
  });

  /// Immutable document instance that owns the tile source data.
  final Object documentIdentity;

  /// Fixed 16-by-16 source tile represented by this key.
  final PatternTileCoordinate coordinate;

  /// Renderer detail level represented by the recorded pictures.
  final RenderLod renderLod;

  /// Quantized quarter-pixel cell-size identity.
  final int cellSizeBucket;

  /// Static visual settings represented by the recorded pictures.
  final PatternTilePictureStyle style;

  /// Compares cache inputs while retaining document identity semantics.
  @override
  bool operator ==(Object other) =>
      other is PatternTilePictureKey &&
      identical(documentIdentity, other.documentIdentity) &&
      coordinate == other.coordinate &&
      renderLod == other.renderLod &&
      cellSizeBucket == other.cellSizeBucket &&
      style == other.style;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode => Object.hash(
    identityHashCode(documentIdentity),
    coordinate,
    renderLod,
    cellSizeBucket,
    style,
  );
}

/// Recorded base and foreground pictures for one immutable source tile.
class PatternTilePictures {
  /// Creates a cache entry and transfers picture ownership to this object.
  PatternTilePictures({
    required this.fillPicture,
    required this.glyphPicture,
    required this.cellFillCount,
    required this.cellFillSourceDrawCalls,
    required this.glyphCount,
    required this.estimatedByteSize,
  }) : assert(estimatedByteSize > 0);

  /// Optional thread-color fill picture painted below dynamic overlays.
  final ui.Picture? fillPicture;

  /// Optional glyph picture painted above dynamic overlays.
  final ui.Picture? glyphPicture;

  /// Number of populated-cell fills represented by [fillPicture].
  final int cellFillCount;

  /// Number of color-grouped source paths recorded in [fillPicture].
  final int cellFillSourceDrawCalls;

  /// Number of glyphs represented by [glyphPicture].
  final int glyphCount;

  /// Engine-reported approximate display-list bytes plus entry overhead.
  final int estimatedByteSize;

  /// Number of active frame leases protecting this entry from disposal.
  int _activeLeaseCount = 0;

  /// Whether the cache requested disposal while a frame still held a lease.
  bool _disposeRequested = false;

  /// Whether the native pictures owned by this entry were already disposed.
  bool _isDisposed = false;

  /// Retains this entry until the current paint frame releases its lease.
  void _retain() {
    assert(!_isDisposed);
    _activeLeaseCount++;
  }

  /// Releases one frame lease and performs deferred native disposal.
  void _release() {
    assert(_activeLeaseCount > 0);
    _activeLeaseCount--;
    if (_activeLeaseCount == 0 && _disposeRequested) _disposePictures();
  }

  /// Releases native pictures immediately or after active frames finish.
  void dispose() {
    if (_isDisposed || _disposeRequested) return;
    _disposeRequested = true;
    if (_activeLeaseCount == 0) _disposePictures();
  }

  /// Disposes both native display lists exactly once.
  void _disposePictures() {
    if (_isDisposed) return;
    fillPicture?.dispose();
    glyphPicture?.dispose();
    _isDisposed = true;
  }
}

/// Frame-scoped access to pictures that may be evicted during the same paint.
class PatternTilePictureLease {
  /// Creates a retained lease for [pictures].
  PatternTilePictureLease._(this.pictures) {
    pictures._retain();
  }

  /// Pictures protected from disposal until [release] is called.
  final PatternTilePictures pictures;

  /// Whether this lease already relinquished its retained entry.
  bool _isReleased = false;

  /// Relinquishes the frame's claim on the cached native pictures.
  void release() {
    if (_isReleased) return;
    _isReleased = true;
    pictures._release();
  }
}

/// Bounded least-recently-used cache for immutable tile display lists.
class PatternTilePictureCache {
  /// Creates a cache constrained by an approximate display-list byte budget.
  PatternTilePictureCache({this.maximumEstimatedBytes = 24 * 1024 * 1024})
    : assert(maximumEstimatedBytes > 0);

  /// Maximum estimated native display-list bytes retained by the cache.
  final int maximumEstimatedBytes;

  /// Entries ordered from least to most recently used.
  final LinkedHashMap<PatternTilePictureKey, PatternTilePictures> _entries =
      LinkedHashMap<PatternTilePictureKey, PatternTilePictures>();

  /// Total estimated display-list bytes retained by [_entries].
  int _estimatedBytes = 0;

  /// Number of successful lookups observed over this cache's lifetime.
  int _hitCount = 0;

  /// Number of unsuccessful lookups observed over this cache's lifetime.
  int _missCount = 0;

  /// Number of least-recently-used entries removed to satisfy the budget.
  int _evictionCount = 0;

  /// Whether settled paint frames may record and insert missing pictures.
  bool _writesEnabled = true;

  /// Whether paint frames may replay retained pictures instead of direct cells.
  bool _reuseEnabled = true;

  /// Number of retained tile entries.
  int get entryCount => _entries.length;

  /// Estimated native display-list bytes retained by all entries.
  int get estimatedBytes => _estimatedBytes;

  /// Total successful lookup count used by diagnostics and tests.
  int get hitCount => _hitCount;

  /// Total unsuccessful lookup count used by diagnostics and tests.
  int get missCount => _missCount;

  /// Total budget-driven eviction count used by diagnostics and tests.
  int get evictionCount => _evictionCount;

  /// Whether cache misses may be recorded during the current frame.
  bool get writesEnabled => _writesEnabled;

  /// Whether paint frames may reuse retained pictures during the current frame.
  bool get reuseEnabled => _reuseEnabled;

  /// Converts a positive logical cell size into a quarter-pixel cache bucket.
  static int quantizeCellSize(double cellSize) {
    assert(cellSize > 0 && cellSize.isFinite);
    return (cellSize * 4).round().clamp(1, 1 << 30);
  }

  /// Returns the representative logical cell size for [cellSizeBucket].
  static double cellSizeForBucket(int cellSizeBucket) {
    assert(cellSizeBucket > 0);
    return cellSizeBucket / 4;
  }

  /// Acquires and promotes a cached entry, or records one cache miss.
  PatternTilePictureLease? acquire(PatternTilePictureKey key) {
    final pictures = _entries.remove(key);
    if (pictures == null) {
      _missCount++;
      return null;
    }
    _entries[key] = pictures;
    _hitCount++;
    return PatternTilePictureLease._(pictures);
  }

  /// Inserts and acquires [pictures], or rejects an over-budget entry.
  PatternTilePictureLease? putAndAcquire(
    PatternTilePictureKey key,
    PatternTilePictures pictures,
  ) {
    if (pictures.estimatedByteSize > maximumEstimatedBytes) return null;
    final replaced = _entries.remove(key);
    if (replaced != null) {
      _estimatedBytes -= replaced.estimatedByteSize;
      replaced.dispose();
    }
    _entries[key] = pictures;
    _estimatedBytes += pictures.estimatedByteSize;
    final lease = PatternTilePictureLease._(pictures);
    _evictToBudget();
    return lease;
  }

  /// Prevents cache recording while camera gestures need inexpensive misses.
  void suspendWrites() {
    _writesEnabled = false;
  }

  /// Allows a settling repaint to populate tiles missed during interaction.
  void resumeWrites() {
    _writesEnabled = true;
  }

  /// Prevents stale picture replay while an exact-scale zoom is in progress.
  void suspendReuse() {
    _reuseEnabled = false;
  }

  /// Allows settled pan or zoom frames to replay matching tile pictures again.
  void resumeReuse() {
    _reuseEnabled = true;
  }

  /// Removes every entry and releases its native display lists.
  void clear() {
    for (final pictures in _entries.values) {
      pictures.dispose();
    }
    _entries.clear();
    _estimatedBytes = 0;
  }

  /// Releases all retained entries when the owning viewport is disposed.
  void dispose() {
    clear();
  }

  /// Evicts least-recently-used entries until the byte budget is satisfied.
  void _evictToBudget() {
    while (_estimatedBytes > maximumEstimatedBytes && _entries.isNotEmpty) {
      final oldestKey = _entries.keys.first;
      final oldestPictures = _entries.remove(oldestKey)!;
      _estimatedBytes -= oldestPictures.estimatedByteSize;
      _evictionCount++;
      oldestPictures.dispose();
    }
  }
}

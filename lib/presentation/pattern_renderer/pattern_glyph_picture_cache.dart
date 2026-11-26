import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Identifies one recorded glyph appearance independently of its tile location.
class PatternGlyphPictureKey {
  /// Creates a key from every text input that changes glyph pixels or layout.
  const PatternGlyphPictureKey({
    required this.glyph,
    required this.foreground,
    required this.fontSizeBucket,
    required this.fontFamily,
    required this.fontWeight,
    required this.textDirection,
    required this.rendererGeneration,
  });

  /// Text displayed by the recorded picture.
  final String glyph;

  /// Resolved foreground color used to record the glyph.
  final Color foreground;

  /// Quantized font-size identity for the recorded glyph.
  final int fontSizeBucket;

  /// Optional text family used when the glyph was laid out.
  final String? fontFamily;

  /// Numeric font-weight value used when the glyph was laid out.
  final int fontWeight;

  /// Reading direction used to lay out the glyph.
  final TextDirection textDirection;

  /// Viewport-managed generation invalidated when font rendering changes.
  final int rendererGeneration;

  /// Compares every visual and layout input represented by this key.
  @override
  bool operator ==(Object other) =>
      other is PatternGlyphPictureKey &&
      glyph == other.glyph &&
      foreground == other.foreground &&
      fontSizeBucket == other.fontSizeBucket &&
      fontFamily == other.fontFamily &&
      fontWeight == other.fontWeight &&
      textDirection == other.textDirection &&
      rendererGeneration == other.rendererGeneration;

  /// Produces a hash code consistent with [operator ==].
  @override
  int get hashCode => Object.hash(
    glyph,
    foreground,
    fontSizeBucket,
    fontFamily,
    fontWeight,
    textDirection,
    rendererGeneration,
  );
}

/// Owns one recorded glyph picture and its replay measurements.
class PatternGlyphPicture {
  /// Takes ownership of [picture] and records its replay metadata.
  PatternGlyphPicture({
    required this.picture,
    required this.width,
    required this.height,
    required this.estimatedByteSize,
  }) : assert(width >= 0),
       assert(height >= 0),
       assert(estimatedByteSize > 0);

  /// Native display list replayed at a cell center.
  final ui.Picture picture;

  /// Measured glyph width used to center the replayed picture.
  final double width;

  /// Measured glyph height used to center the replayed picture.
  final double height;

  /// Engine-reported display-list bytes plus entry overhead.
  final int estimatedByteSize;

  /// Number of active leases that prevent immediate picture disposal.
  int _activeLeaseCount = 0;

  /// Whether disposal must wait for outstanding leases.
  bool _disposeRequested = false;

  /// Whether the owned native picture has already been disposed.
  bool _isDisposed = false;

  /// Retains this picture until its frame-scoped lease is released.
  void _retain() {
    assert(!_isDisposed);
    _activeLeaseCount++;
  }

  /// Releases one lease and completes any deferred picture disposal.
  void _release() {
    assert(_activeLeaseCount > 0);
    _activeLeaseCount--;
    if (_activeLeaseCount == 0 && _disposeRequested) _disposePicture();
  }

  /// Releases the picture immediately or after outstanding leases finish.
  void dispose() {
    if (_isDisposed || _disposeRequested) return;
    _disposeRequested = true;
    if (_activeLeaseCount == 0) _disposePicture();
  }

  /// Disposes the owned picture exactly once.
  void _disposePicture() {
    if (_isDisposed) return;
    picture.dispose();
    _isDisposed = true;
  }
}

/// Protects a glyph picture from eviction-driven disposal during one frame.
class PatternGlyphPictureLease {
  /// Retains [glyphPicture] until [release] is called.
  PatternGlyphPictureLease._(this.glyphPicture) {
    glyphPicture._retain();
  }

  /// Picture and measurements protected by this lease.
  final PatternGlyphPicture glyphPicture;

  /// Whether this lease has already relinquished its entry.
  bool _isReleased = false;

  /// Relinquishes this frame's claim on the retained picture.
  void release() {
    if (_isReleased) return;
    _isReleased = true;
    glyphPicture._release();
  }
}

/// Bounds reusable glyph display lists with LRU eviction and leased ownership.
class PatternGlyphPictureCache {
  /// Creates a cache constrained by both entry count and display-list bytes.
  PatternGlyphPictureCache({
    this.maximumEntries = 256,
    this.maximumEstimatedBytes = 4 * 1024 * 1024,
  }) : assert(maximumEntries > 0),
       assert(maximumEstimatedBytes > 0);

  /// Maximum number of glyph pictures retained regardless of memory cost.
  final int maximumEntries;

  /// Maximum estimated native display-list bytes retained by the cache.
  final int maximumEstimatedBytes;

  /// Entries ordered from least to most recently used.
  final LinkedHashMap<PatternGlyphPictureKey, PatternGlyphPicture> _entries =
      LinkedHashMap<PatternGlyphPictureKey, PatternGlyphPicture>();

  /// Total estimated bytes retained by [_entries].
  int _estimatedBytes = 0;

  /// Number of successful cache lookups.
  int _hitCount = 0;

  /// Number of unsuccessful cache lookups.
  int _missCount = 0;

  /// Number of least-recently-used entries evicted to satisfy a budget.
  int _evictionCount = 0;

  /// Number of glyph pictures currently retained.
  int get entryCount => _entries.length;

  /// Estimated native display-list bytes retained by all entries.
  int get estimatedBytes => _estimatedBytes;

  /// Total successful lookup count used by diagnostics and tests.
  int get hitCount => _hitCount;

  /// Total unsuccessful lookup count used by diagnostics and tests.
  int get missCount => _missCount;

  /// Total budget-driven eviction count used by diagnostics and tests.
  int get evictionCount => _evictionCount;

  /// Converts a positive logical font size into a quarter-pixel cache bucket.
  static int quantizeFontSize(double fontSize) {
    assert(fontSize > 0 && fontSize.isFinite);
    return (fontSize * 4).round().clamp(1, 1 << 30);
  }

  /// Returns the representative logical font size for [fontSizeBucket].
  static double fontSizeForBucket(int fontSizeBucket) {
    assert(fontSizeBucket > 0);
    return fontSizeBucket / 4;
  }

  /// Acquires and promotes a cached glyph picture, or records a cache miss.
  PatternGlyphPictureLease? acquire(PatternGlyphPictureKey key) {
    final glyphPicture = _entries.remove(key);
    if (glyphPicture == null) {
      _missCount++;
      return null;
    }
    _entries[key] = glyphPicture;
    _hitCount++;
    return PatternGlyphPictureLease._(glyphPicture);
  }

  /// Inserts and acquires [glyphPicture], rejecting entries over the byte budget.
  ///
  /// The caller retains ownership of a rejected picture and must dispose it.
  PatternGlyphPictureLease? putAndAcquire(
    PatternGlyphPictureKey key,
    PatternGlyphPicture glyphPicture,
  ) {
    if (glyphPicture.estimatedByteSize > maximumEstimatedBytes) return null;
    final replaced = _entries.remove(key);
    if (replaced != null) {
      _estimatedBytes -= replaced.estimatedByteSize;
      replaced.dispose();
    }
    _entries[key] = glyphPicture;
    _estimatedBytes += glyphPicture.estimatedByteSize;
    final lease = PatternGlyphPictureLease._(glyphPicture);
    _evictToBudget();
    return lease;
  }

  /// Removes all cached entries and defers native disposal for active leases.
  void clear() {
    for (final glyphPicture in _entries.values) {
      glyphPicture.dispose();
    }
    _entries.clear();
    _estimatedBytes = 0;
  }

  /// Releases every retained glyph picture when the owning viewport is disposed.
  void dispose() {
    clear();
  }

  /// Removes least-recently-used entries until both configured budgets hold.
  void _evictToBudget() {
    while ((_entries.length > maximumEntries ||
            _estimatedBytes > maximumEstimatedBytes) &&
        _entries.isNotEmpty) {
      final oldestKey = _entries.keys.first;
      final oldestPicture = _entries.remove(oldestKey)!;
      _estimatedBytes -= oldestPicture.estimatedByteSize;
      _evictionCount++;
      oldestPicture.dispose();
    }
  }
}

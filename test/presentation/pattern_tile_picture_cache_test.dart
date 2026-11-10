import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_tile_picture_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/render_lod.dart';

/// Verifies bounded reuse and interaction controls for tile display lists.
void main() {
  test('quantizes nearby cell sizes into stable quarter-pixel buckets', () {
    expect(PatternTilePictureCache.quantizeCellSize(12.01), 48);
    expect(PatternTilePictureCache.quantizeCellSize(12.11), 48);
    expect(PatternTilePictureCache.quantizeCellSize(12.14), 49);
    expect(PatternTilePictureCache.cellSizeForBucket(49), 12.25);
  });

  test('promotes hits and evicts the least-recently-used entry', () {
    final documentIdentity = Object();
    final cache = PatternTilePictureCache(maximumEstimatedBytes: 200);
    addTearDown(cache.dispose);
    final firstKey = _key(documentIdentity, 0);
    final secondKey = _key(documentIdentity, 1);
    final thirdKey = _key(documentIdentity, 2);

    cache.putAndAcquire(firstKey, _pictures(100))!.release();
    cache.putAndAcquire(secondKey, _pictures(100))!.release();
    cache.acquire(firstKey)!.release();
    cache.putAndAcquire(thirdKey, _pictures(100))!.release();

    expect(cache.entryCount, 2);
    expect(cache.estimatedBytes, 200);
    expect(cache.evictionCount, 1);
    expect(cache.acquire(secondKey), isNull);
    final retainedLease = cache.acquire(firstKey);
    expect(retainedLease, isNotNull);
    retainedLease!.release();
  });

  test('rejects one entry larger than the configured memory budget', () {
    final cache = PatternTilePictureCache(maximumEstimatedBytes: 99);
    addTearDown(cache.dispose);
    final pictures = _pictures(100);
    addTearDown(pictures.dispose);

    final lease = cache.putAndAcquire(_key(Object(), 0), pictures);

    expect(lease, isNull);
    expect(cache.entryCount, 0);
    expect(cache.estimatedBytes, 0);
  });

  test('suspends writes independently from retained cache reads', () {
    final cache = PatternTilePictureCache();
    addTearDown(cache.dispose);
    final key = _key(Object(), 0);
    cache.putAndAcquire(key, _pictures(100))!.release();

    cache.suspendWrites();
    final retainedLease = cache.acquire(key);

    expect(cache.writesEnabled, isFalse);
    expect(retainedLease, isNotNull);
    retainedLease!.release();
    cache.resumeWrites();
    expect(cache.writesEnabled, isTrue);
  });

  test('separates document, scale, detail, and style cache identities', () {
    final documentIdentity = Object();
    final cache = PatternTilePictureCache();
    addTearDown(cache.dispose);
    final originalKey = _key(documentIdentity, 0);
    cache.putAndAcquire(originalKey, _pictures(100))!.release();
    final changedScaleKey = PatternTilePictureKey(
      documentIdentity: documentIdentity,
      coordinate: const PatternTileCoordinate(0, 0),
      renderLod: RenderLod.detail,
      cellSizeBucket: 49,
      style: originalKey.style,
    );
    final changedLodKey = PatternTilePictureKey(
      documentIdentity: documentIdentity,
      coordinate: const PatternTileCoordinate(0, 0),
      renderLod: RenderLod.grid,
      cellSizeBucket: 48,
      style: originalKey.style,
    );
    final changedStyleKey = PatternTilePictureKey(
      documentIdentity: documentIdentity,
      coordinate: const PatternTileCoordinate(0, 0),
      renderLod: RenderLod.detail,
      cellSizeBucket: 48,
      style: const PatternTilePictureStyle(
        showCellColor: false,
        cellColorOpacity: 0.22,
        showSymbols: true,
        surfaceColor: Colors.white,
      ),
    );

    expect(cache.acquire(changedScaleKey), isNull);
    expect(cache.acquire(changedLodKey), isNull);
    expect(cache.acquire(changedStyleKey), isNull);
    expect(cache.acquire(_key(Object(), 0)), isNull);
  });

  test('clears retained memory when viewport inputs are invalidated', () {
    final cache = PatternTilePictureCache();
    addTearDown(cache.dispose);
    final key = _key(Object(), 0);
    cache.putAndAcquire(key, _pictures(100))!.release();

    cache.clear();

    expect(cache.entryCount, 0);
    expect(cache.estimatedBytes, 0);
    expect(cache.acquire(key), isNull);
  });
}

/// Creates one representative cache key for a tile column.
PatternTilePictureKey _key(Object documentIdentity, int tileColumn) =>
    PatternTilePictureKey(
      documentIdentity: documentIdentity,
      coordinate: PatternTileCoordinate(0, tileColumn),
      renderLod: RenderLod.detail,
      cellSizeBucket: 48,
      style: const PatternTilePictureStyle(
        showCellColor: true,
        cellColorOpacity: 0.22,
        showSymbols: true,
        surfaceColor: Colors.white,
      ),
    );

/// Creates a minimal native picture with a caller-controlled memory estimate.
PatternTilePictures _pictures(int estimatedByteSize) {
  final recorder = PictureRecorder();
  Canvas(recorder)
      .drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = Colors.black);
  return PatternTilePictures(
    fillPicture: recorder.endRecording(),
    glyphPicture: null,
    cellFillCount: 1,
    cellFillSourceDrawCalls: 1,
    glyphCount: 0,
    estimatedByteSize: estimatedByteSize,
  );
}

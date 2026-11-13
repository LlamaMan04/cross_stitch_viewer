import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_static_tile_recorder.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_tile_picture_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/render_lod.dart';

/// Verifies shared lookup, recording, caching, and ownership of static tiles.
void main() {
  test('creates stable keys and reuses a recorded tile lease', () {
    final document = SamplePatternFixture.create();
    final cache = PatternTilePictureCache();
    addTearDown(cache.dispose);
    var recordingCount = 0;
    final recorder = PatternStaticTileRecorder(
      document: document,
      cache: cache,
      renderLod: RenderLod.detail,
      cellSizeBucket: 80,
      style: const PatternTilePictureStyle(
        showCellColor: true,
        cellColorOpacity: 0.22,
        showSymbols: true,
        surfaceColor: Colors.white,
      ),
      recordPictures:
          ({required coordinate, required recordedCellSize, required cells}) {
            recordingCount++;
            expect(coordinate, const PatternTileCoordinate(0, 0));
            expect(recordedCellSize, 20);
            expect(cells, isNotEmpty);
            return _pictures();
          },
    );

    final key = recorder.keyFor(const PatternTileCoordinate(0, 0));
    final first = recorder.resolve(const PatternTileCoordinate(0, 0));

    expect(key.documentIdentity, same(document));
    expect(key.coordinate, const PatternTileCoordinate(0, 0));
    expect(first.cacheMiss, isTrue);
    expect(first.cacheHit, isFalse);
    expect(first.recordingCompleted, isTrue);
    expect(first.pictures, isNotNull);
    first.release();

    final second = recorder.resolve(const PatternTileCoordinate(0, 0));

    expect(recordingCount, 1);
    expect(second.cacheHit, isTrue);
    expect(second.recordingStarted, isFalse);
    second.release();
  });

  test('uses a direct source-cell result while cache writes are suspended', () {
    final document = SamplePatternFixture.create();
    final cache = PatternTilePictureCache();
    addTearDown(cache.dispose);
    cache.suspendWrites();
    var recordingCount = 0;
    final recorder = PatternStaticTileRecorder(
      document: document,
      cache: cache,
      renderLod: RenderLod.detail,
      cellSizeBucket: 80,
      style: const PatternTilePictureStyle(
        showCellColor: true,
        cellColorOpacity: 0.22,
        showSymbols: true,
        surfaceColor: Colors.white,
      ),
      recordPictures:
          ({required coordinate, required recordedCellSize, required cells}) {
            recordingCount++;
            return _pictures();
          },
    );

    final result = recorder.resolve(const PatternTileCoordinate(0, 0));

    expect(result.source, PatternStaticTileResolutionSource.direct);
    expect(result.cells, isNotEmpty);
    expect(result.pictures, isNull);
    expect(result.cacheMiss, isTrue);
    expect(recordingCount, 0);
    result.release();
  });

  test('returns a releasable temporary picture when the cache rejects it', () {
    final document = SamplePatternFixture.create();
    final cache = PatternTilePictureCache(maximumEstimatedBytes: 1);
    addTearDown(cache.dispose);
    final recorder = PatternStaticTileRecorder(
      document: document,
      cache: cache,
      renderLod: RenderLod.detail,
      cellSizeBucket: 80,
      style: const PatternTilePictureStyle(
        showCellColor: true,
        cellColorOpacity: 0.22,
        showSymbols: true,
        surfaceColor: Colors.white,
      ),
      recordPictures: ({
        required coordinate,
        required recordedCellSize,
        required cells,
      }) => _pictures(estimatedByteSize: 2),
    );

    final result = recorder.resolve(const PatternTileCoordinate(0, 0));

    expect(result.source, PatternStaticTileResolutionSource.temporary);
    expect(result.recordingRejected, isTrue);
    expect(result.pictures, isNotNull);
    result.release();
    result.release();
  });
}

/// Creates one small native fill picture for recorder ownership tests.
PatternTilePictures _pictures({int estimatedByteSize = 1}) {
  final pictureRecorder = PictureRecorder();
  Canvas(pictureRecorder)
      .drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = Colors.black);
  return PatternTilePictures(
    fillPicture: pictureRecorder.endRecording(),
    glyphPicture: null,
    cellFillCount: 1,
    cellFillSourceDrawCalls: 1,
    glyphCount: 0,
    estimatedByteSize: estimatedByteSize,
  );
}

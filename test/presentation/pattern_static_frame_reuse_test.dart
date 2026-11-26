import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_camera.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_static_frame_reuse.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_static_tile_recorder.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_tile_picture_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/render_lod.dart';

/// Verifies translated static-frame reuse and its cache-lease ownership.
void main() {
  test('retains only overlapping tiles and rejects changed static inputs', () {
    final document = SamplePatternFixture.create();
    final cache = PatternTilePictureCache();
    final recorder = _recorder(document, cache);
    final reuse = PatternStaticFrameReuse();
    addTearDown(cache.dispose);

    expect(recorder.warm(const PatternTileCoordinate(0, 0)), isTrue);
    reuse.capture(
      coordinates: const <PatternTileCoordinate>[PatternTileCoordinate(0, 0)],
      recorder: recorder,
      camera: const PatternCamera(cellSize: 20, origin: Offset.zero),
    );

    expect(reuse.hasRetainedFrame, isTrue);
    expect(reuse.retainedTileCount, 1);
    expect(
      reuse.coordinatesIntersecting(
        const GridBounds(startRow: 0, endRow: 1, startColumn: 0, endColumn: 1),
      ),
      <PatternTileCoordinate>{const PatternTileCoordinate(0, 0)},
    );
    expect(
      reuse.coordinatesIntersecting(
        const GridBounds(
          startRow: PatternGrid.tileSize,
          endRow: PatternGrid.tileSize + 1,
          startColumn: 0,
          endColumn: 1,
        ),
      ),
      isEmpty,
    );
    expect(
      reuse.canReplay(
        recorder: recorder,
        camera: const PatternCamera(cellSize: 20, origin: Offset(40, 0)),
      ),
      isTrue,
    );
    expect(
      reuse.canReplay(
        recorder: recorder,
        camera: const PatternCamera(cellSize: 21, origin: Offset.zero),
      ),
      isFalse,
    );
  });

  test('releases retained leases after cache eviction or replacement', () {
    final document = SamplePatternFixture.create();
    final cache = PatternTilePictureCache();
    final recorder = _recorder(document, cache);
    final reuse = PatternStaticFrameReuse();
    addTearDown(cache.dispose);

    recorder.warm(const PatternTileCoordinate(0, 0));
    reuse.capture(
      coordinates: const <PatternTileCoordinate>[PatternTileCoordinate(0, 0)],
      recorder: recorder,
      camera: const PatternCamera(cellSize: 20, origin: Offset.zero),
    );
    cache.clear();

    reuse.clear();
    reuse.clear();

    expect(reuse.hasRetainedFrame, isFalse);
    expect(reuse.retainedTileCount, 0);
  });
}

/// Builds a lightweight recorder whose accepted pictures are safe for cache tests.
PatternStaticTileRecorder _recorder(
  PatternDocument document,
  PatternTilePictureCache cache,
) => PatternStaticTileRecorder(
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
  }) => _pictures(),
);

/// Creates one minimal paired static-picture entry for retained-frame tests.
PatternTilePictures _pictures() {
  final fillRecorder = PictureRecorder();
  Canvas(fillRecorder)
      .drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = Colors.black);
  final glyphRecorder = PictureRecorder();
  Canvas(glyphRecorder)
      .drawRect(const Rect.fromLTWH(0, 0, 1, 1), Paint()..color = Colors.black);
  return PatternTilePictures(
    fillPicture: fillRecorder.endRecording(),
    glyphPicture: glyphRecorder.endRecording(),
    cellFillCount: 1,
    cellFillSourceDrawCalls: 1,
    glyphCount: 1,
    estimatedByteSize: 100,
  );
}

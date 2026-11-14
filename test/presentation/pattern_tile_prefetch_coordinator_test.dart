import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_camera.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_static_tile_recorder.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_tile_picture_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_tile_prefetch_coordinator.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_viewport_bounds.dart';
import 'package:stitch_scope/presentation/pattern_renderer/render_lod.dart';

/// Verifies bounded, duplicate-free, revision-aware tile cache warming.
void main() {
  test('suppresses duplicate requests and records at most the frame limit', () {
    final callbacks = <FrameCallback>[];
    final cache = PatternTilePictureCache();
    addTearDown(cache.dispose);
    final coordinator = PatternTilePrefetchCoordinator(
      maximumTilesPerFrame: 1,
      scheduleFrame: callbacks.add,
    );
    addTearDown(coordinator.dispose);
    var recordings = 0;
    final recorder = _recorder(cache, () => recordings++);
    final bounds = _bounds();

    coordinator.submit(
      camera: _camera(),
      renderLod: RenderLod.detail,
      bounds: bounds,
      revision: 1,
      recorder: recorder,
      requestRepaint: () {},
    );
    coordinator.submit(
      camera: _camera(),
      renderLod: RenderLod.detail,
      bounds: bounds,
      revision: 1,
      recorder: recorder,
      requestRepaint: () {},
    );

    expect(coordinator.requestCount, coordinator.queuedRequestCount);
    expect(coordinator.queuedRequestCount, greaterThan(1));
    callbacks.removeAt(0)(Duration.zero);
    expect(recordings, 1);
    expect(coordinator.prefetchedTileCount, 1);
    expect(coordinator.queuedRequestCount, greaterThan(0));
  });

  test('cancels obsolete camera revisions before they can record', () {
    final callbacks = <FrameCallback>[];
    final cache = PatternTilePictureCache();
    addTearDown(cache.dispose);
    final coordinator = PatternTilePrefetchCoordinator(
      scheduleFrame: callbacks.add,
    );
    addTearDown(coordinator.dispose);
    var recordings = 0;
    final recorder = _recorder(cache, () => recordings++);

    coordinator.submit(
      camera: _camera(),
      renderLod: RenderLod.detail,
      bounds: _bounds(),
      revision: 1,
      recorder: recorder,
      requestRepaint: () {},
    );
    coordinator.submit(
      camera: _camera(origin: const Offset(-32, 0)),
      renderLod: RenderLod.detail,
      bounds: _bounds(startColumn: 16),
      revision: 2,
      recorder: recorder,
      requestRepaint: () {},
    );

    expect(coordinator.cancelledRequestCount, greaterThan(0));
    callbacks.removeAt(0)(Duration.zero);
    expect(recordings, lessThanOrEqualTo(coordinator.maximumTilesPerFrame));
  });
}

/// Builds a shared-recorder equivalent with inexpensive native test pictures.
PatternStaticTileRecorder _recorder(
  PatternTilePictureCache cache,
  VoidCallback onRecord,
) {
  final document = LargeSamplePatternFixture.create();
  return PatternStaticTileRecorder(
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
          onRecord();
          final pictureRecorder = PictureRecorder();
          Canvas(pictureRecorder).drawRect(
            const Rect.fromLTWH(0, 0, 1, 1),
            Paint()..color = Colors.black,
          );
          return PatternTilePictures(
            fillPicture: pictureRecorder.endRecording(),
            glyphPicture: null,
            cellFillCount: 1,
            cellFillSourceDrawCalls: 1,
            glyphCount: 0,
            estimatedByteSize: 1,
          );
        },
  );
}

/// Produces a tile-aligned cache-warming range spanning multiple tiles.
PatternViewportBounds _bounds({int startColumn = 0}) => PatternViewportBounds(
  paintBounds: GridBounds(
    startRow: 0,
    endRow: PatternGrid.tileSize,
    startColumn: startColumn,
    endColumn: startColumn + PatternGrid.tileSize,
  ),
  prefetchBounds: GridBounds(
    startRow: 0,
    endRow: PatternGrid.tileSize * 2,
    startColumn: startColumn,
    endColumn: startColumn + PatternGrid.tileSize * 2,
  ),
);

/// Creates a fixed-scale camera whose origin can express pan direction.
PatternCamera _camera({Offset origin = Offset.zero}) =>
    PatternCamera(cellSize: 20, origin: origin);

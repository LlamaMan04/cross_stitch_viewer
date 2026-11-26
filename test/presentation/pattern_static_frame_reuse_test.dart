import 'dart:ui';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/value_objects.dart';
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
    expect(
      reuse.canReplay(
        recorder: _recorder(SamplePatternFixture.create(), cache),
        camera: const PatternCamera(cellSize: 20, origin: Offset.zero),
      ),
      isFalse,
    );
    expect(
      reuse.canReplay(
        recorder: _recorder(document, cache, renderLod: RenderLod.grid),
        camera: const PatternCamera(cellSize: 20, origin: Offset.zero),
      ),
      isFalse,
    );
    expect(
      reuse.canReplay(
        recorder: _recorder(
          document,
          cache,
          style: const PatternTilePictureStyle(
            showCellColor: true,
            cellColorOpacity: 0.22,
            showSymbols: true,
            surfaceColor: Colors.black,
          ),
        ),
        camera: const PatternCamera(cellSize: 20, origin: Offset.zero),
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

  test(
    'clips translated retained pictures to the active document extent',
    () async {
      final document = SamplePatternFixture.create();
      final cache = PatternTilePictureCache();
      final recorder = _recorder(
        document,
        cache,
        recordPictures: ({
          required coordinate,
          required recordedCellSize,
          required cells,
        }) => _oversizedFillPictures(),
      );
      final reuse = PatternStaticFrameReuse();
      addTearDown(cache.dispose);

      recorder.warm(const PatternTileCoordinate(0, 0));
      reuse.capture(
        coordinates: const <PatternTileCoordinate>[PatternTileCoordinate(0, 0)],
        recorder: recorder,
        camera: const PatternCamera(cellSize: 20, origin: Offset.zero),
      );
      final pictureRecorder = PictureRecorder();
      final paintedCount = reuse.paintLayer(
        canvas: Canvas(pictureRecorder),
        camera: const PatternCamera(cellSize: 20, origin: Offset(10, 0)),
        bounds: const GridBounds(
          startRow: 0,
          endRow: 1,
          startColumn: 0,
          endColumn: 1,
        ),
        dimensions: const PatternDimensions(1, 1),
        pictureFor: (pictures) => pictures.fillPicture,
        countFor: (pictures) => pictures.cellFillCount,
      );
      final picture = pictureRecorder.endRecording();
      final image = await picture.toImage(40, 20);
      final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);

      expect(paintedCount, 1);
      expect(_alphaAt(bytes!, x: 5, y: 10, width: 40), 0);
      expect(_alphaAt(bytes, x: 15, y: 10, width: 40), 255);
      expect(_alphaAt(bytes, x: 35, y: 10, width: 40), 0);

      image.dispose();
      picture.dispose();
      reuse.clear();
    },
  );
}

/// Builds a lightweight recorder whose accepted pictures are safe for cache tests.
PatternStaticTileRecorder _recorder(
  PatternDocument document,
  PatternTilePictureCache cache, {
  RenderLod renderLod = RenderLod.detail,
  PatternTilePictureStyle style = const PatternTilePictureStyle(
    showCellColor: true,
    cellColorOpacity: 0.22,
    showSymbols: true,
    surfaceColor: Colors.white,
  ),
  PatternStaticTilePictureRecorder? recordPictures,
}) => PatternStaticTileRecorder(
  document: document,
  cache: cache,
  renderLod: renderLod,
  cellSizeBucket: 80,
  style: style,
  recordPictures:
      recordPictures ??
      ({required coordinate, required recordedCellSize, required cells}) =>
          _pictures(),
);

/// Reads the alpha channel of one raw RGBA pixel for clipping assertions.
int _alphaAt(
  ByteData bytes, {
  required int x,
  required int y,
  required int width,
}) => bytes.getUint8((y * width + x) * 4 + 3);

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

/// Creates an intentionally oversized fill to expose missing document clips.
PatternTilePictures _oversizedFillPictures() {
  final fillRecorder = PictureRecorder();
  Canvas(fillRecorder).drawRect(
    const Rect.fromLTWH(-100, -100, 200, 200),
    Paint()..color = Colors.black,
  );
  return PatternTilePictures(
    fillPicture: fillRecorder.endRecording(),
    glyphPicture: null,
    cellFillCount: 1,
    cellFillSourceDrawCalls: 1,
    glyphCount: 0,
    estimatedByteSize: 100,
  );
}

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport/pattern_camera.dart';
import 'package:stitch_scope/presentation/pattern_renderer/cache/pattern_glyph_layout_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/cache/pattern_glyph_picture_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport/pattern_render_selection.dart';
import 'package:stitch_scope/presentation/pattern_renderer/cache/pattern_symbol_render_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/tiles/pattern_tile_prefetch_coordinator.dart';
import 'package:stitch_scope/presentation/pattern_renderer/cache/pattern_tile_picture_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport/pattern_viewport_controller.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport/render_lod.dart';
import 'package:stitch_scope/presentation/pattern_renderer/painting/viewport_pattern_painter.dart';

/// Verifies that renderer layers share one visible-cell spatial query.
void main() {
  test('reuses one visible-cell snapshot across every enabled layer', () {
    final fixture = _createCountingDocument();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    addTearDown(glyphLayoutCache.dispose);
    final painter = ViewportPatternPainter(
      document: fixture.document,
      camera: const PatternCamera(cellSize: 40, origin: Offset.zero),
      visibleBounds: const GridBounds(
        startRow: 0,
        endRow: 4,
        startColumn: 0,
        endColumn: 5,
      ),
      settings: const PatternRenderSettings(showCellColor: true),
      selection: const PatternRenderSelection(
        threadId: 'dmc-321',
        selectedSymbolId: 'flower',
      ),
      completedCells: <GridCoordinate>{const GridCoordinate(0, 0)},
      completionSelection: <GridCoordinate>{const GridCoordinate(1, 2)},
      surfaceColor: Colors.white,
      regionColor: Colors.blue,
      completionSelectionColor: Colors.teal,
      glyphLayoutCache: glyphLayoutCache,
      symbolRenderCache: PatternSymbolRenderCache(fixture.document),
      renderLod: RenderLod.detail,
      completedOverviewCoordinates: const <int, Set<PatternTileCoordinate>>{},
    );
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    painter.paint(canvas, const Size(400, 300));
    final picture = recorder.endRecording();
    picture.dispose();

    expect(fixture.grid.queryCount, 1);
  });

  test('does not query cells when overview layers need no cell data', () {
    final fixture = _createCountingDocument();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    addTearDown(glyphLayoutCache.dispose);
    final painter = ViewportPatternPainter(
      document: fixture.document,
      camera: const PatternCamera(cellSize: 5, origin: Offset.zero),
      visibleBounds: const GridBounds(
        startRow: 0,
        endRow: 4,
        startColumn: 0,
        endColumn: 5,
      ),
      settings: const PatternRenderSettings(),
      selection: const PatternRenderSelection(),
      completedCells: const <GridCoordinate>{},
      completionSelection: const <GridCoordinate>{},
      surfaceColor: Colors.white,
      regionColor: Colors.blue,
      completionSelectionColor: Colors.teal,
      glyphLayoutCache: glyphLayoutCache,
      symbolRenderCache: PatternSymbolRenderCache(fixture.document),
      renderLod: RenderLod.grid,
      completedOverviewCoordinates: const <int, Set<PatternTileCoordinate>>{},
    );
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    painter.paint(canvas, const Size(400, 300));
    final picture = recorder.endRecording();
    picture.dispose();

    expect(fixture.grid.queryCount, 0);
    expect(fixture.grid.tileSummaryQueryCount, 0);
  });

  test('overview queries summaries without enumerating visible cells', () {
    final fixture = _createCountingDocument();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    addTearDown(glyphLayoutCache.dispose);
    final painter = ViewportPatternPainter(
      document: fixture.document,
      camera: const PatternCamera(cellSize: 2, origin: Offset.zero),
      visibleBounds: const GridBounds(
        startRow: 0,
        endRow: 4,
        startColumn: 0,
        endColumn: 5,
      ),
      settings: const PatternRenderSettings(showCellColor: true),
      selection: const PatternRenderSelection(
        threadId: 'dmc-321',
        selectedSymbolId: 'flower',
      ),
      completedCells: <GridCoordinate>{const GridCoordinate(0, 0)},
      completionSelection: <GridCoordinate>{const GridCoordinate(1, 2)},
      surfaceColor: Colors.white,
      regionColor: Colors.blue,
      completionSelectionColor: Colors.teal,
      glyphLayoutCache: glyphLayoutCache,
      symbolRenderCache: PatternSymbolRenderCache(fixture.document),
      renderLod: RenderLod.overview,
      completedOverviewCoordinates: <int, Set<PatternTileCoordinate>>{
        4: <PatternTileCoordinate>{const PatternTileCoordinate(0, 0)},
      },
    );
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    painter.paint(canvas, const Size(400, 300));
    final picture = recorder.endRecording();
    picture.dispose();

    expect(fixture.grid.queryCount, 0);
    expect(fixture.grid.tileSummaryQueryCount, 2);
  });

  test('batches dense overview density and accent layers', () {
    final document = LargeSamplePatternFixture.create();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    addTearDown(glyphLayoutCache.dispose);
    PatternRenderBatchMetrics? metrics;
    final painter = ViewportPatternPainter(
      document: document,
      camera: const PatternCamera(cellSize: 0.5, origin: Offset.zero),
      visibleBounds: const GridBounds(
        startRow: 0,
        endRow: LargeSamplePatternFixture.rows,
        startColumn: 0,
        endColumn: LargeSamplePatternFixture.columns,
      ),
      settings: const PatternRenderSettings(
        showCellColor: true,
        showGrid: false,
      ),
      selection: const PatternRenderSelection(
        threadId: 'dmc-321',
        selectedSymbolId: 'large-red',
      ),
      completedCells: <GridCoordinate>{const GridCoordinate(0, 1)},
      completionSelection: <GridCoordinate>{const GridCoordinate(0, 2)},
      surfaceColor: Colors.white,
      regionColor: Colors.blue,
      completionSelectionColor: Colors.teal,
      glyphLayoutCache: glyphLayoutCache,
      symbolRenderCache: PatternSymbolRenderCache(document),
      renderLod: RenderLod.overview,
      completedOverviewCoordinates: <int, Set<PatternTileCoordinate>>{
        32: <PatternTileCoordinate>{const PatternTileCoordinate(0, 0)},
      },
      pendingOverviewCoordinates: <int, Set<PatternTileCoordinate>>{
        32: <PatternTileCoordinate>{const PatternTileCoordinate(0, 0)},
      },
      onBatchMetrics: (value) => metrics = value,
    );
    final recorder = PictureRecorder();

    painter.paint(Canvas(recorder), const Size(100, 50));
    recorder.endRecording().dispose();

    final summaryCount = document.grid
        .overviewSummariesIntersecting(
          const GridBounds(
            startRow: 0,
            endRow: LargeSamplePatternFixture.rows,
            startColumn: 0,
            endColumn: LargeSamplePatternFixture.columns,
          ),
          32,
        )
        .length;
    expect(summaryCount, greaterThan(10));
    expect(metrics?.drawCallCount, lessThan(summaryCount));
  });

  test('batches cell fills by color and grid rules by class', () {
    final fixture = _createCountingDocument();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    addTearDown(glyphLayoutCache.dispose);
    PatternRenderBatchMetrics? metrics;
    final painter = ViewportPatternPainter(
      document: fixture.document,
      camera: const PatternCamera(cellSize: 40, origin: Offset.zero),
      visibleBounds: const GridBounds(
        startRow: 0,
        endRow: 4,
        startColumn: 0,
        endColumn: 5,
      ),
      settings: const PatternRenderSettings(showCellColor: true),
      selection: const PatternRenderSelection(),
      completedCells: const <GridCoordinate>{},
      completionSelection: const <GridCoordinate>{},
      surfaceColor: Colors.white,
      regionColor: Colors.blue,
      completionSelectionColor: Colors.teal,
      glyphLayoutCache: glyphLayoutCache,
      symbolRenderCache: PatternSymbolRenderCache(fixture.document),
      renderLod: RenderLod.grid,
      completedOverviewCoordinates: const <int, Set<PatternTileCoordinate>>{},
      onBatchMetrics: (value) => metrics = value,
    );
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder);

    painter.paint(canvas, const Size(400, 300));
    final picture = recorder.endRecording();
    picture.dispose();

    expect(metrics?.cellFillCount, 3);
    expect(metrics?.cellFillDrawCalls, 2);
    expect(metrics?.directCellFillCount, 3);
    expect(metrics?.gridRuleCount, 11);
    expect(metrics?.gridDrawCalls, 2);
    expect(metrics?.gridPathsRecorded, 2);
    expect(metrics?.visibleCellCount, 3);
    expect(metrics?.glyphCount, 0);
    expect(metrics?.directGlyphPaintCount, 0);
    expect(metrics?.tileRecordingsStarted, 0);
    expect(metrics?.tileRecordingsCompleted, 0);
    expect(metrics?.tileRecordingsRejected, 0);
    expect(metrics?.prefetchRequests, 0);
    expect(metrics?.dynamicOverlayCandidatesVisited, 0);
    expect(metrics?.dynamicOverlayPrimitivesPainted, 0);
    expect(metrics?.isInteractive, isFalse);
    expect(metrics?.drawCallCount, greaterThanOrEqualTo(4));
  });

  test('batches only completed coordinates in visible source tiles', () {
    final fixture = _createCountingDocument();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    addTearDown(glyphLayoutCache.dispose);
    PatternRenderBatchMetrics? metrics;
    final painter = ViewportPatternPainter(
      document: fixture.document,
      camera: const PatternCamera(cellSize: 40, origin: Offset.zero),
      visibleBounds: const GridBounds(
        startRow: 0,
        endRow: 4,
        startColumn: 0,
        endColumn: 5,
      ),
      settings: const PatternRenderSettings(showCellColor: true),
      selection: const PatternRenderSelection(),
      completedCells: <GridCoordinate>{
        const GridCoordinate(0, 0),
        const GridCoordinate(3, 4),
        const GridCoordinate(16, 16),
      },
      completionSelection: const <GridCoordinate>{},
      surfaceColor: Colors.white,
      regionColor: Colors.blue,
      completionSelectionColor: Colors.teal,
      glyphLayoutCache: glyphLayoutCache,
      symbolRenderCache: PatternSymbolRenderCache(fixture.document),
      renderLod: RenderLod.detail,
      completedOverviewCoordinates: const <int, Set<PatternTileCoordinate>>{},
      onBatchMetrics: (value) => metrics = value,
    );
    final recorder = PictureRecorder();

    painter.paint(Canvas(recorder), const Size(400, 300));
    recorder.endRecording().dispose();

    expect(metrics?.dynamicOverlayCandidatesVisited, 2);
    expect(metrics?.dynamicOverlayPrimitivesPainted, 1);
  });

  test('reuses static tile pictures while the camera origin changes', () {
    final fixture = _createCountingDocument();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    final tilePictureCache = PatternTilePictureCache();
    addTearDown(glyphLayoutCache.dispose);
    addTearDown(tilePictureCache.dispose);
    PatternRenderBatchMetrics? secondMetrics;

    _paintCachedFixture(
      fixture: fixture,
      glyphLayoutCache: glyphLayoutCache,
      tilePictureCache: tilePictureCache,
      camera: const PatternCamera(cellSize: 8, origin: Offset.zero),
    );
    _paintCachedFixture(
      fixture: fixture,
      glyphLayoutCache: glyphLayoutCache,
      tilePictureCache: tilePictureCache,
      camera: const PatternCamera(cellSize: 8, origin: Offset(-4, -2)),
      onBatchMetrics: (metrics) => secondMetrics = metrics,
    );

    expect(fixture.grid.queryCount, 1);
    expect(tilePictureCache.entryCount, 1);
    expect(secondMetrics?.tilePictureHits, 1);
    expect(secondMetrics?.tilePictureMisses, 0);
  });

  test('replays glyph pictures for direct detail tile misses', () {
    final fixture = _createCountingDocument();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    final glyphPictureCache = PatternGlyphPictureCache();
    final tilePictureCache = PatternTilePictureCache()..suspendWrites();
    addTearDown(glyphLayoutCache.dispose);
    addTearDown(glyphPictureCache.dispose);
    addTearDown(tilePictureCache.dispose);
    PatternRenderBatchMetrics? secondMetrics;

    _paintCachedFixture(
      fixture: fixture,
      glyphLayoutCache: glyphLayoutCache,
      glyphPictureCache: glyphPictureCache,
      tilePictureCache: tilePictureCache,
      camera: const PatternCamera(cellSize: 40, origin: Offset.zero),
      renderLod: RenderLod.detail,
    );
    final missesAfterFirstPaint = glyphPictureCache.missCount;
    _paintCachedFixture(
      fixture: fixture,
      glyphLayoutCache: glyphLayoutCache,
      glyphPictureCache: glyphPictureCache,
      tilePictureCache: tilePictureCache,
      camera: const PatternCamera(cellSize: 40, origin: Offset.zero),
      renderLod: RenderLod.detail,
      onBatchMetrics: (value) => secondMetrics = value,
    );

    expect(glyphPictureCache.entryCount, greaterThan(0));
    expect(missesAfterFirstPaint, greaterThan(0));
    expect(glyphPictureCache.hitCount, greaterThan(0));
    expect(
      secondMetrics?.glyphPictureCacheEntries,
      glyphPictureCache.entryCount,
    );
    expect(secondMetrics?.glyphPictureCacheHits, glyphPictureCache.hitCount);
  });

  test('records static tile glyphs by replaying cached glyph pictures', () {
    final fixture = _createCountingDocument();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    final glyphPictureCache = PatternGlyphPictureCache();
    final tilePictureCache = PatternTilePictureCache();
    addTearDown(glyphLayoutCache.dispose);
    addTearDown(glyphPictureCache.dispose);
    addTearDown(tilePictureCache.dispose);

    _paintCachedFixture(
      fixture: fixture,
      glyphLayoutCache: glyphLayoutCache,
      glyphPictureCache: glyphPictureCache,
      tilePictureCache: tilePictureCache,
      camera: const PatternCamera(cellSize: 40, origin: Offset.zero),
      renderLod: RenderLod.detail,
    );

    expect(tilePictureCache.entryCount, 1);
    expect(glyphPictureCache.entryCount, greaterThan(0));
    expect(glyphPictureCache.hitCount, greaterThan(0));
  });

  test(
    'falls back to TextPainter when glyph pictures exceed their byte budget',
    () {
      final fixture = _createCountingDocument();
      final glyphLayoutCache = PatternGlyphLayoutCache();
      final glyphPictureCache = PatternGlyphPictureCache(
        maximumEstimatedBytes: 1,
      );
      final tilePictureCache = PatternTilePictureCache()..suspendWrites();
      PatternRenderBatchMetrics? metrics;
      addTearDown(glyphLayoutCache.dispose);
      addTearDown(glyphPictureCache.dispose);
      addTearDown(tilePictureCache.dispose);

      _paintCachedFixture(
        fixture: fixture,
        glyphLayoutCache: glyphLayoutCache,
        glyphPictureCache: glyphPictureCache,
        tilePictureCache: tilePictureCache,
        camera: const PatternCamera(cellSize: 40, origin: Offset.zero),
        renderLod: RenderLod.detail,
        onBatchMetrics: (value) => metrics = value,
      );

      expect(glyphPictureCache.entryCount, 0);
      expect(metrics?.glyphCount, greaterThan(0));
    },
  );

  test('caps synchronous recordings during a pan and queues direct misses', () {
    final document = LargeSamplePatternFixture.create();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    final tilePictureCache = PatternTilePictureCache();
    final callbacks = <FrameCallback>[];
    final tilePrefetchCoordinator = PatternTilePrefetchCoordinator(
      maximumTilesPerFrame: 1,
      scheduleFrame: callbacks.add,
    );
    final cameraController = PatternViewportController(
      camera: const PatternCamera(cellSize: 20, origin: Offset(-20, -20)),
    )..beginPanning();
    addTearDown(glyphLayoutCache.dispose);
    addTearDown(tilePictureCache.dispose);
    addTearDown(tilePrefetchCoordinator.dispose);
    addTearDown(cameraController.dispose);
    PatternRenderBatchMetrics? metrics;
    final painter = ViewportPatternPainter(
      document: document,
      camera: cameraController.camera,
      visibleBounds: const GridBounds(
        startRow: 0,
        endRow: LargeSamplePatternFixture.rows,
        startColumn: 0,
        endColumn: LargeSamplePatternFixture.columns,
      ),
      settings: const PatternRenderSettings(
        showCellColor: true,
        showGrid: false,
      ),
      selection: const PatternRenderSelection(),
      completedCells: const <GridCoordinate>{},
      completionSelection: const <GridCoordinate>{},
      surfaceColor: Colors.white,
      regionColor: Colors.blue,
      completionSelectionColor: Colors.teal,
      glyphLayoutCache: glyphLayoutCache,
      symbolRenderCache: PatternSymbolRenderCache(document),
      tilePictureCache: tilePictureCache,
      tilePrefetchCoordinator: tilePrefetchCoordinator,
      cameraController: cameraController,
      viewportSize: const Size(700, 400),
      maximumSynchronousTileRecordingsDuringPan: 1,
      renderLod: RenderLod.detail,
      completedOverviewCoordinates: const <int, Set<PatternTileCoordinate>>{},
      onBatchMetrics: (value) => metrics = value,
    );
    final pictureRecorder = PictureRecorder();

    painter.paint(Canvas(pictureRecorder), const Size(700, 400));
    pictureRecorder.endRecording().dispose();

    expect(metrics?.interactionState, PatternViewportInteractionState.panning);
    expect(metrics?.tileRecordingsStarted, 1);
    expect(metrics?.directCellFillCount, greaterThan(0));
    expect(tilePictureCache.entryCount, 1);
    expect(tilePrefetchCoordinator.queuedRequestCount, greaterThan(0));
    expect(callbacks, isNotEmpty);

    callbacks.removeAt(0)(Duration.zero);

    expect(tilePrefetchCoordinator.prefetchedTileCount, 1);
    expect(tilePictureCache.entryCount, 2);
  });

  test('honors a disabled prefetch expansion when warming tiles', () {
    final document = LargeSamplePatternFixture.create();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    final tilePictureCache = PatternTilePictureCache();
    final callbacks = <FrameCallback>[];
    final tilePrefetchCoordinator = PatternTilePrefetchCoordinator(
      scheduleFrame: callbacks.add,
    );
    final cameraController = PatternViewportController(
      camera: const PatternCamera(cellSize: 20, origin: Offset.zero),
    );
    addTearDown(glyphLayoutCache.dispose);
    addTearDown(tilePictureCache.dispose);
    addTearDown(tilePrefetchCoordinator.dispose);
    addTearDown(cameraController.dispose);
    final painter = ViewportPatternPainter(
      document: document,
      camera: cameraController.camera,
      visibleBounds: const GridBounds(
        startRow: 0,
        endRow: 1,
        startColumn: 0,
        endColumn: 1,
      ),
      settings: const PatternRenderSettings(showCellColor: true),
      selection: const PatternRenderSelection(),
      completedCells: const <GridCoordinate>{},
      completionSelection: const <GridCoordinate>{},
      surfaceColor: Colors.white,
      regionColor: Colors.blue,
      completionSelectionColor: Colors.teal,
      glyphLayoutCache: glyphLayoutCache,
      symbolRenderCache: PatternSymbolRenderCache(document),
      tilePictureCache: tilePictureCache,
      tilePrefetchCoordinator: tilePrefetchCoordinator,
      cameraController: cameraController,
      viewportSize: const Size(100, 100),
      prefetchTileDistance: 0,
      renderLod: RenderLod.detail,
      completedOverviewCoordinates: const <int, Set<PatternTileCoordinate>>{},
    );
    final pictureRecorder = PictureRecorder();

    painter.paint(Canvas(pictureRecorder), const Size(100, 100));
    pictureRecorder.endRecording().dispose();

    expect(tilePictureCache.entryCount, 1);
    expect(tilePrefetchCoordinator.queuedRequestCount, 0);
    expect(callbacks, isEmpty);
  });

  test(
    'paints cache misses directly during interaction and warms afterward',
    () {
      final fixture = _createCountingDocument();
      final glyphLayoutCache = PatternGlyphLayoutCache();
      final tilePictureCache = PatternTilePictureCache()..suspendWrites();
      addTearDown(glyphLayoutCache.dispose);
      addTearDown(tilePictureCache.dispose);

      _paintCachedFixture(
        fixture: fixture,
        glyphLayoutCache: glyphLayoutCache,
        tilePictureCache: tilePictureCache,
        camera: const PatternCamera(cellSize: 8, origin: Offset.zero),
      );

      expect(tilePictureCache.entryCount, 0);
      expect(fixture.grid.queryCount, 1);

      tilePictureCache.resumeWrites();
      _paintCachedFixture(
        fixture: fixture,
        glyphLayoutCache: glyphLayoutCache,
        tilePictureCache: tilePictureCache,
        camera: const PatternCamera(cellSize: 8, origin: Offset.zero),
      );

      expect(tilePictureCache.entryCount, 1);
      expect(fixture.grid.queryCount, 2);
    },
  );

  test('discards retained tile pictures for every active zoom frame', () {
    final fixture = _createCountingDocument();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    final tilePictureCache = PatternTilePictureCache();
    addTearDown(glyphLayoutCache.dispose);
    addTearDown(tilePictureCache.dispose);
    PatternRenderBatchMetrics? zoomMetrics;
    PatternRenderBatchMetrics? settledMetrics;

    _paintCachedFixture(
      fixture: fixture,
      glyphLayoutCache: glyphLayoutCache,
      tilePictureCache: tilePictureCache,
      camera: const PatternCamera(cellSize: 8, origin: Offset.zero),
    );
    tilePictureCache
      ..suspendWrites()
      ..suspendReuse()
      ..clear();
    _paintCachedFixture(
      fixture: fixture,
      glyphLayoutCache: glyphLayoutCache,
      tilePictureCache: tilePictureCache,
      camera: const PatternCamera(cellSize: 8, origin: Offset(-4, -2)),
      onBatchMetrics: (metrics) => zoomMetrics = metrics,
    );

    expect(tilePictureCache.entryCount, 0);
    expect(fixture.grid.queryCount, 2);
    expect(zoomMetrics?.tilePictureHits, 0);
    expect(zoomMetrics?.tilePictureMisses, 0);
    expect(zoomMetrics?.tilePictureBypasses, 1);

    tilePictureCache
      ..resumeWrites()
      ..resumeReuse();
    _paintCachedFixture(
      fixture: fixture,
      glyphLayoutCache: glyphLayoutCache,
      tilePictureCache: tilePictureCache,
      camera: const PatternCamera(cellSize: 8, origin: Offset(-4, -2)),
      onBatchMetrics: (metrics) => settledMetrics = metrics,
    );

    expect(fixture.grid.queryCount, 3);
    expect(settledMetrics?.tilePictureHits, 0);
    expect(settledMetrics?.tilePictureMisses, 1);
    expect(settledMetrics?.tilePictureBypasses, 0);
    expect(tilePictureCache.entryCount, 1);
  });

  for (final interaction in <String, void Function(PatternTilePictureCache)>{
    'pan cache miss': (cache) => cache.suspendWrites(),
    'zoom cache bypass': (cache) => cache
      ..suspendWrites()
      ..suspendReuse(),
  }.entries) {
    test('keeps cell colors disabled during ${interaction.key}', () {
      final fixture = _createCountingDocument();
      final glyphLayoutCache = PatternGlyphLayoutCache();
      final tilePictureCache = PatternTilePictureCache();
      addTearDown(glyphLayoutCache.dispose);
      addTearDown(tilePictureCache.dispose);
      PatternRenderBatchMetrics? metrics;
      interaction.value(tilePictureCache);

      _paintCachedFixture(
        fixture: fixture,
        glyphLayoutCache: glyphLayoutCache,
        tilePictureCache: tilePictureCache,
        camera: const PatternCamera(cellSize: 16, origin: Offset.zero),
        settings: const PatternRenderSettings(showCellColor: false),
        renderLod: RenderLod.detail,
        onBatchMetrics: (value) => metrics = value,
      );

      expect(metrics?.cellFillCount, 0);
      expect(metrics?.cellFillDrawCalls, 0);
    });
  }

  for (final interaction in <String, void Function(PatternTilePictureCache)>{
    'pan cache miss': (cache) => cache.suspendWrites(),
    'zoom cache bypass': (cache) => cache
      ..suspendWrites()
      ..suspendReuse(),
  }.entries) {
    test('keeps symbols disabled during ${interaction.key}', () {
      final fixture = _createCountingDocument();
      final glyphLayoutCache = PatternGlyphLayoutCache();
      final tilePictureCache = PatternTilePictureCache();
      addTearDown(glyphLayoutCache.dispose);
      addTearDown(tilePictureCache.dispose);
      PatternRenderBatchMetrics? metrics;
      interaction.value(tilePictureCache);

      _paintCachedFixture(
        fixture: fixture,
        glyphLayoutCache: glyphLayoutCache,
        tilePictureCache: tilePictureCache,
        camera: const PatternCamera(cellSize: 16, origin: Offset.zero),
        settings: const PatternRenderSettings(
          showCellColor: true,
          showSymbols: false,
        ),
        renderLod: RenderLod.detail,
        onBatchMetrics: (value) => metrics = value,
      );

      expect(metrics?.glyphCount, 0);
    });
  }

  test('keeps completion overlays dynamic over reused static pictures', () {
    final fixture = _createCountingDocument();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    final tilePictureCache = PatternTilePictureCache();
    addTearDown(glyphLayoutCache.dispose);
    addTearDown(tilePictureCache.dispose);
    PatternRenderBatchMetrics? completedMetrics;

    _paintCachedFixture(
      fixture: fixture,
      glyphLayoutCache: glyphLayoutCache,
      tilePictureCache: tilePictureCache,
      camera: const PatternCamera(cellSize: 8, origin: Offset.zero),
    );
    _paintCachedFixture(
      fixture: fixture,
      glyphLayoutCache: glyphLayoutCache,
      tilePictureCache: tilePictureCache,
      camera: const PatternCamera(cellSize: 8, origin: Offset.zero),
      completedCells: <GridCoordinate>{const GridCoordinate(0, 0)},
      onBatchMetrics: (metrics) => completedMetrics = metrics,
    );

    expect(completedMetrics?.tilePictureHits, 1);
    expect(completedMetrics?.tilePictureMisses, 0);
    expect(fixture.grid.queryCount, 1);
    expect(completedMetrics?.drawCallCount, greaterThan(4));
  });
}

/// Paints one grid-LOD frame through the shared tile picture cache.
void _paintCachedFixture({
  required ({PatternDocument document, _CountingPatternGrid grid}) fixture,
  required PatternGlyphLayoutCache glyphLayoutCache,
  PatternGlyphPictureCache? glyphPictureCache,
  required PatternTilePictureCache tilePictureCache,
  required PatternCamera camera,
  PatternRenderSettings settings = const PatternRenderSettings(
    showCellColor: true,
  ),
  RenderLod renderLod = RenderLod.grid,
  Set<GridCoordinate> completedCells = const <GridCoordinate>{},
  ValueChanged<PatternRenderBatchMetrics>? onBatchMetrics,
}) {
  final painter = ViewportPatternPainter(
    document: fixture.document,
    camera: camera,
    visibleBounds: const GridBounds(
      startRow: 0,
      endRow: 4,
      startColumn: 0,
      endColumn: 5,
    ),
    settings: settings,
    selection: const PatternRenderSelection(),
    completedCells: completedCells,
    completionSelection: const <GridCoordinate>{},
    surfaceColor: Colors.white,
    regionColor: Colors.blue,
    completionSelectionColor: Colors.teal,
    glyphLayoutCache: glyphLayoutCache,
    glyphPictureCache: glyphPictureCache,
    symbolRenderCache: PatternSymbolRenderCache(fixture.document),
    tilePictureCache: tilePictureCache,
    renderLod: renderLod,
    completedOverviewCoordinates: const <int, Set<PatternTileCoordinate>>{},
    onBatchMetrics: onBatchMetrics,
  );
  final recorder = PictureRecorder();
  painter.paint(Canvas(recorder), const Size(400, 300));
  recorder.endRecording().dispose();
}

/// Creates a representative document backed by an observable spatial grid.
({PatternDocument document, _CountingPatternGrid grid})
_createCountingDocument() {
  final sourceDocument = SamplePatternFixture.create();
  final countingGrid = _CountingPatternGrid(
    dimensions: sourceDocument.grid.dimensions,
    cells: sourceDocument.grid.cells,
  );
  return (
    document: PatternDocument(
      id: sourceDocument.id,
      title: sourceDocument.title,
      schemaVersion: sourceDocument.schemaVersion,
      grid: countingGrid,
      threads: sourceDocument.threads,
      symbols: sourceDocument.symbols,
      backstitchDefinitions: sourceDocument.backstitchDefinitions,
      backstitches: sourceDocument.backstitches,
      regions: sourceDocument.regions,
      sourceMetadata: sourceDocument.sourceMetadata,
      sourceChecksum: sourceDocument.sourceChecksum,
      diagnostics: sourceDocument.diagnostics,
    ),
    grid: countingGrid,
  );
}

/// Pattern grid that records visible-range queries made by the painter.
class _CountingPatternGrid extends PatternGrid {
  /// Creates a counting grid over representative immutable cells.
  _CountingPatternGrid({required super.dimensions, required super.cells});

  /// Number of spatial range queries requested from this grid.
  int queryCount = 0;

  /// Number of visible-tile summary queries requested from this grid.
  int tileSummaryQueryCount = 0;

  /// Records and delegates one visible-cell range query.
  @override
  Iterable<StitchCell> cellsIntersecting(GridBounds bounds) {
    queryCount++;
    return super.cellsIntersecting(bounds);
  }

  /// Records and delegates one visible-tile summary query.
  @override
  Iterable<PatternTileSummary> overviewSummariesIntersecting(
    GridBounds bounds,
    int blockSize,
  ) {
    tileSummaryQueryCount++;
    return super.overviewSummariesIntersecting(bounds, blockSize);
  }
}

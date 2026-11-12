import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_interaction.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_camera.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_render_selection.dart';
import 'package:stitch_scope/presentation/pattern_renderer/render_lod.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport_pattern_painter.dart';
import 'package:stitch_scope/presentation/screens/pattern_workspace_screen.dart';

/// Covers navigation and completion-selection interactions in the viewport.
void main() {
  testWidgets('pans the large pattern with a direct camera transform', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 300,
          child: PatternRenderView(
            document: LargeSamplePatternFixture.create(),
          ),
        ),
      ),
    );
    await tester.pump();

    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    final before =
        (tester.widget<CustomPaint>(canvasFinder).painter!
                as ViewportPatternPainter)
            .camera;
    await tester.drag(
      find.byKey(const ValueKey('pattern-viewport')),
      const Offset(0, -20),
    );
    await tester.pump();
    final after =
        (tester.widget<CustomPaint>(canvasFinder).painter!
                as ViewportPatternPainter)
            .camera;

    expect(after.origin.dy, lessThan(before.origin.dy));
    expect(after.cellSize, before.cellSize);
  });

  testWidgets('camera movement repaints without rebuilding the canvas widget', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 300,
          child: PatternRenderView(
            document: LargeSamplePatternFixture.create(),
          ),
        ),
      ),
    );
    await tester.pump();

    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    final canvasBefore = tester.widget<CustomPaint>(canvasFinder);
    final painter = canvasBefore.painter! as ViewportPatternPainter;
    final cameraBefore = painter.camera;

    await tester.drag(
      find.byKey(const ValueKey('pattern-viewport')),
      const Offset(0, -20),
    );
    await tester.pump();

    final canvasAfter = tester.widget<CustomPaint>(canvasFinder);
    expect(identical(canvasAfter, canvasBefore), isTrue);
    expect(painter.camera.origin.dy, lessThan(cameraBefore.origin.dy));
    expect(
      find.byKey(const ValueKey('pattern-render-boundary')),
      findsOneWidget,
    );
  });

  testWidgets('keeps drag navigation separate from completion cell selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 300,
          child: PatternRenderView(
            document: LargeSamplePatternFixture.create(),
            interactionMode: PatternInteractionMode.editCompletion,
          ),
        ),
      ),
    );
    await tester.pump();

    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    final before =
        (tester.widget<CustomPaint>(canvasFinder).painter!
                as ViewportPatternPainter)
            .camera;
    await tester.drag(
      find.byKey(const ValueKey('pattern-viewport')),
      const Offset(0, -30),
    );
    await tester.pump();
    final painter =
        tester.widget<CustomPaint>(canvasFinder).painter!
            as ViewportPatternPainter;

    expect(painter.camera.origin.dy, lessThan(before.origin.dy));
    expect(painter.completionSelection, isEmpty);
  });

  testWidgets('control-drag adds completion cells without panning on Android', (
    tester,
  ) async {
    final addedCoordinates = <GridCoordinate>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: SizedBox(
          width: 400,
          height: 300,
          child: PatternRenderView(
            document: SamplePatternFixture.create(),
            interactionMode: PatternInteractionMode.editCompletion,
            onCompletionCellAdded: addedCoordinates.add,
          ),
        ),
      ),
    );
    await tester.pump();

    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    final painter =
        tester.widget<CustomPaint>(canvasFinder).painter!
            as ViewportPatternPainter;
    final canvasOrigin = tester.getTopLeft(canvasFinder);
    final firstCell =
        canvasOrigin + painter.camera.gridToScreen(row: 0.5, column: 0.5);
    final secondCell =
        canvasOrigin + painter.camera.gridToScreen(row: 1.5, column: 2.5);
    final cameraBefore = painter.camera;

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final gesture = await tester.startGesture(
      firstCell,
      kind: PointerDeviceKind.mouse,
    );
    await gesture.moveTo(secondCell);
    await tester.pump();
    await gesture.up();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    final cameraAfter =
        (tester.widget<CustomPaint>(canvasFinder).painter!
                as ViewportPatternPainter)
            .camera;
    expect(addedCoordinates, <GridCoordinate>[
      const GridCoordinate(0, 0),
      const GridCoordinate(1, 2),
    ]);
    expect(cameraAfter.origin, cameraBefore.origin);
    expect(cameraAfter.cellSize, cameraBefore.cellSize);
  });

  testWidgets(
    'double-click-drag adds completion cells without panning on Windows',
    (tester) async {
      final addedCoordinates = <GridCoordinate>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.windows),
          home: SizedBox(
            width: 400,
            height: 300,
            child: PatternRenderView(
              document: SamplePatternFixture.create(),
              interactionMode: PatternInteractionMode.editCompletion,
              onCompletionCellAdded: addedCoordinates.add,
            ),
          ),
        ),
      );
      await tester.pump();

      final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
      final painter =
          tester.widget<CustomPaint>(canvasFinder).painter!
              as ViewportPatternPainter;
      final canvasOrigin = tester.getTopLeft(canvasFinder);
      final firstCell =
          canvasOrigin + painter.camera.gridToScreen(row: 0.5, column: 0.5);
      final secondCell =
          canvasOrigin + painter.camera.gridToScreen(row: 1.5, column: 2.5);
      final cameraBefore = painter.camera;

      final firstTap = await tester.startGesture(
        firstCell,
        kind: PointerDeviceKind.mouse,
      );
      await firstTap.up();
      await tester.pump(const Duration(milliseconds: 50));
      final selectionDrag = await tester.startGesture(
        firstCell,
        kind: PointerDeviceKind.mouse,
      );
      await tester.pump();
      await selectionDrag.moveTo(secondCell);
      await tester.pump();
      await selectionDrag.up();
      await tester.pump();

      final cameraAfter =
          (tester.widget<CustomPaint>(canvasFinder).painter!
                  as ViewportPatternPainter)
              .camera;
      expect(addedCoordinates, <GridCoordinate>[
        const GridCoordinate(0, 0),
        const GridCoordinate(1, 2),
      ]);
      expect(cameraAfter.origin, cameraBefore.origin);
      expect(cameraAfter.cellSize, cameraBefore.cellSize);
    },
  );

  testWidgets('reports completion coordinates without a symbol callback', (
    tester,
  ) async {
    GridCoordinate? selectedCoordinate;
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 300,
          child: PatternRenderView(
            document: SamplePatternFixture.create(),
            interactionMode: PatternInteractionMode.editCompletion,
            onCompletionCellSelected: (coordinate) {
              selectedCoordinate = coordinate;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    final painter =
        tester.widget<CustomPaint>(canvasFinder).painter!
            as ViewportPatternPainter;
    final firstFlowerCenter =
        tester.getTopLeft(canvasFinder) +
        painter.camera.gridToScreen(row: 0.5, column: 0.5);

    await tester.tapAt(firstFlowerCenter);
    await tester.pump();

    expect(selectedCoordinate, const GridCoordinate(0, 0));
  });

  testWidgets('does not select cells while the renderer is in overview LOD', (
    tester,
  ) async {
    var selectionCallbackCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: PatternRenderView(
              document: LargeSamplePatternFixture.create(),
              onSymbolSelected: (_) => selectionCallbackCount++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final viewport = find.byKey(const ValueKey('pattern-viewport'));
    final painter = _painter(
      tester,
      find.byKey(const ValueKey('pattern-grid-canvas')),
    );
    expect(painter.renderLod, RenderLod.overview);

    await tester.tapAt(tester.getCenter(viewport));
    await tester.pump();

    expect(selectionCallbackCount, 0);
  });

  testWidgets('pinch zoom updates the focal camera and settles repainting', (
    tester,
  ) async {
    await tester.pumpWidget(_viewportApp(LargeSamplePatternFixture.create()));
    await tester.pump();

    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    final before = _painter(tester, canvasFinder).camera;
    final viewport = find.byKey(const ValueKey('pattern-viewport'));
    final center = tester.getCenter(viewport);
    final localCenter = center - tester.getTopLeft(viewport);
    final firstPointer = await tester.startGesture(
      center - const Offset(30, 0),
      pointer: 1,
    );
    final secondPointer = await tester.startGesture(
      center + const Offset(30, 0),
      pointer: 2,
    );
    await firstPointer.moveBy(const Offset(-20, 0));
    await secondPointer.moveBy(const Offset(20, 0));
    await tester.pump();
    await firstPointer.up();
    await secondPointer.up();
    await tester.pump(const Duration(milliseconds: 150));

    final after = _painter(tester, canvasFinder).camera;
    expect(after.cellSize, greaterThan(before.cellSize));
    expect(
      after.screenToGrid(localCenter),
      closeToOffset(before.screenToGrid(localCenter), tolerance: 4),
    );
  });

  testWidgets('wheel zoom updates the camera around the pointer', (
    tester,
  ) async {
    await tester.pumpWidget(_viewportApp(LargeSamplePatternFixture.create()));
    await tester.pump();

    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    final viewport = find.byKey(const ValueKey('pattern-viewport'));
    final focalPoint = tester.getCenter(viewport);
    final localFocalPoint = focalPoint - tester.getTopLeft(viewport);
    final before = _painter(tester, canvasFinder).camera;
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: focalPoint,
        scrollDelta: const Offset(0, -120),
      ),
    );
    await tester.pump();

    final after = _painter(tester, canvasFinder).camera;
    expect(after.cellSize, greaterThan(before.cellSize));
    expect(
      after.screenToGrid(localFocalPoint),
      closeToOffset(before.screenToGrid(localFocalPoint)),
    );
    await tester.pump(const Duration(milliseconds: 150));
  });

  testWidgets('suppresses selected-symbol rendering in overview', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: SizedBox(
            width: 200,
            height: 100,
            child: PatternRenderView(
              document: LargeSamplePatternFixture.create(),
              selection: const PatternRenderSelection(
                threadId: 'dmc-321',
                selectedSymbolId: 'large-red',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    final painter = _painter(tester, canvasFinder);
    expect(painter.renderLod, RenderLod.overview);
    expect(painter.selection.selectedSymbolId, 'large-red');
    expect(painter.selectedVisibleCells, isEmpty);
  });

  testWidgets('reads and writes tile cache entries while panning', (
    tester,
  ) async {
    await tester.pumpWidget(_viewportApp(SamplePatternFixture.create()));
    await tester.pump();

    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    final painterBefore = _painter(tester, canvasFinder);
    final entriesBefore = painterBefore.tilePictureCache!.entryCount;
    expect(entriesBefore, greaterThan(0));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('pattern-viewport'))),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();

    final cacheDuringPan = _painter(tester, canvasFinder).tilePictureCache!;
    expect(cacheDuringPan.reuseEnabled, isTrue);
    expect(cacheDuringPan.writesEnabled, isTrue);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      _painter(tester, canvasFinder).tilePictureCache!.entryCount,
      greaterThanOrEqualTo(entriesBefore),
    );
  });

  testWidgets('resizing keeps the camera inside the new viewport bounds', (
    tester,
  ) async {
    final document = LargeSamplePatternFixture.create();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 320,
          height: 240,
          child: PatternRenderView(document: document),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 640,
          height: 480,
          child: PatternRenderView(document: document),
        ),
      ),
    );
    await tester.pump();

    final camera = _painter(
      tester,
      find.byKey(const ValueKey('pattern-grid-canvas')),
    ).camera;
    expect(camera.cellSize, inInclusiveRange(1, PatternCamera.maximumCellSize));
    expect(camera.origin.dx.isFinite, isTrue);
    expect(camera.origin.dy.isFinite, isTrue);
  });
}

/// Builds a fixed-size application shell around a viewport document.
Widget _viewportApp(PatternDocument document) => MaterialApp(
  home: SizedBox(
    width: 400,
    height: 300,
    child: PatternRenderView(document: document),
  ),
);

/// Reads the current viewport painter from the test canvas.
ViewportPatternPainter _painter(WidgetTester tester, Finder canvasFinder) =>
    tester.widget<CustomPaint>(canvasFinder).painter! as ViewportPatternPainter;

/// Matches two grid points within the precision expected from gesture events.
Matcher closeToOffset(Offset expected, {double tolerance = 0.01}) =>
    predicate<Offset>(
      (actual) => (actual - expected).distance < tolerance,
      'an offset close to $expected',
    );

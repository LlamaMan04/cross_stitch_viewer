import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/app/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_interaction.dart';
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
}

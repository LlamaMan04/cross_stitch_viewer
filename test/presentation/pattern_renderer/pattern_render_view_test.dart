import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_render_selection.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport_pattern_painter.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport_ruler_painter.dart';
import 'package:stitch_scope/presentation/screens/pattern_workspace_screen.dart';

/// Covers rendering inputs supplied through the public pattern render view.
void main() {
  testWidgets(
    'renders visible completion and optionally excludes it from selection',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: PatternRenderView(
              document: SamplePatternFixture.create(),
              settings: const PatternRenderSettings(
                includeCompletedCellsInSelection: false,
              ),
              selection: const PatternRenderSelection(
                selectedSymbolId: 'flower',
              ),
              completedCells: <GridCoordinate>{const GridCoordinate(0, 0)},
            ),
          ),
        ),
      );
      await tester.pump();

      final canvas = tester.widget<CustomPaint>(
        find.byKey(const ValueKey('pattern-grid-canvas')),
      );
      final painter = canvas.painter! as ViewportPatternPainter;

      expect(painter.completedVisibleCells, hasLength(1));
      expect(painter.selectedVisibleCells, hasLength(1));
      expect(
        painter.selectedVisibleCells.single.coordinate,
        const GridCoordinate(3, 4),
      );
    },
  );

  testWidgets('reserves strips only for enabled fixed viewport rulers', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 400,
          height: 300,
          child: PatternRenderView(
            document: SamplePatternFixture.create(),
            settings: const PatternRenderSettings(
              showTopRuler: true,
              showLeftRuler: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final rulers = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('pattern-viewport-rulers')),
    );
    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    final canvas = tester.getRect(canvasFinder);
    final viewport = tester.getRect(
      find.byKey(const ValueKey('pattern-viewport-rulers')),
    );

    expect(rulers.painter, isA<ViewportRulerPainter>());
    final rulerPainter = rulers.painter! as ViewportRulerPainter;
    expect(rulerPainter.rulerColor, ViewportRulerPainter.backgroundColor);
    expect(rulerPainter.tickColor, Colors.black);
    expect(
      canvas.top - viewport.top,
      closeTo(ViewportRulerPainter.topExtent, 0.01),
    );
    expect(canvas.left - viewport.left, closeTo(0, 0.01));
  });

  testWidgets(
    'hides rulers and restores drawable space when grid is disabled',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 400,
            height: 300,
            child: PatternRenderView(
              document: SamplePatternFixture.create(),
              settings: const PatternRenderSettings(showGrid: false),
            ),
          ),
        ),
      );
      await tester.pump();

      final canvas = tester.getRect(
        find.byKey(const ValueKey('pattern-grid-canvas')),
      );
      final viewport = tester.getRect(
        find.byKey(const ValueKey('pattern-viewport')),
      );

      expect(
        find.byKey(const ValueKey('pattern-viewport-rulers')),
        findsNothing,
      );
      expect(canvas.top - viewport.top, closeTo(0, 0.01));
      expect(canvas.left - viewport.left, closeTo(0, 0.01));
    },
  );
}

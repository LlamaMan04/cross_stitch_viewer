import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_interaction.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport_pattern_painter.dart';
import 'package:stitch_scope/presentation/screens/pattern_workspace_screen.dart';

import '../../domain/in_memory_repositories.dart';
import '../../support/library_app_harness.dart';

/// Covers workspace menus, settings, completion actions, and symbol selection.
void main() {
  testWidgets('floating menu activates only one workspace surface', (
    tester,
  ) async {
    final documents = InMemoryPatternDocumentRepository();
    await tester.pumpWidget(
      buildLibraryApp(documents, seedDocument: SamplePatternFixture.create()),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garden Sampler'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('floating-menu-toggle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('floating-menu-renderer-settings')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('floating-menu-symbol-palette')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('floating-menu-completion-selection')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('floating-menu-renderer-settings')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('renderer-settings-panel')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('symbol-palette-panel')), findsNothing);
    expect(find.byKey(const ValueKey('completion-action-bar')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('close-renderer-settings')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('renderer-settings-panel')), findsNothing);

    await selectWorkspaceMenuOption(
      tester,
      const ValueKey('floating-menu-symbol-palette'),
    );
    expect(find.byKey(const ValueKey('renderer-settings-panel')), findsNothing);
    expect(find.byKey(const ValueKey('symbol-palette-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('completion-action-bar')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('close-symbol-palette')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('symbol-palette-panel')), findsNothing);

    await selectWorkspaceMenuOption(
      tester,
      const ValueKey('floating-menu-completion-selection'),
    );
    expect(find.byKey(const ValueKey('renderer-settings-panel')), findsNothing);
    expect(find.byKey(const ValueKey('symbol-palette-panel')), findsNothing);
    expect(find.byKey(const ValueKey('completion-action-bar')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('close-completion-selection')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('completion-action-bar')), findsNothing);
  });

  testWidgets(
    'changes and persists renderer settings without resetting camera',
    (tester) async {
      final documents = InMemoryPatternDocumentRepository();
      final progress = InMemoryProgressRepository();
      await tester.pumpWidget(
        buildLibraryApp(
          documents,
          progress: progress,
          seedDocument: SamplePatternFixture.create(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Sampler'));
      await tester.pumpAndSettle();

      ViewportPatternPainter painter() =>
          tester
                  .widget<CustomPaint>(
                    find.byKey(const ValueKey('pattern-grid-canvas')),
                  )
                  .painter!
              as ViewportPatternPainter;

      expect(painter().settings, const PatternRenderSettings());
      final viewportSize = tester.getSize(
        find.byKey(const ValueKey('pattern-grid-canvas')),
      );
      await selectWorkspaceMenuOption(
        tester,
        const ValueKey('floating-menu-renderer-settings'),
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('pattern-grid-canvas'))),
        viewportSize,
      );
      final cameraBeforeChange = painter().camera;
      expect(
        find.byKey(const ValueKey('cell-color-opacity-setting')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('show-cell-color-setting')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('cell-color-opacity-setting')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('show-grid-setting')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('selection-highlight-color-setting')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teal').last);
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('renderer-settings-panel')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('show-completed-overlay-setting')),
      );
      await tester.pumpAndSettle();

      expect(painter().settings.showCellColor, isTrue);
      expect(painter().settings.showGrid, isFalse);
      expect(painter().settings.showCompletedCellOverlay, isFalse);
      expect(painter().settings.includeCompletedCellsInSelection, isTrue);
      expect(
        painter().settings.selectionHighlightColor,
        SelectionHighlightColorPreset.teal,
      );
      expect(
        painter().camera.cellSize,
        greaterThanOrEqualTo(cameraBeforeChange.cellSize),
      );
      expect(painter().camera.origin.dx.isFinite, isTrue);
      expect(painter().camera.origin.dy.isFinite, isTrue);
      final saved = await progress.getForDocument('sample-garden-sampler');
      expect(saved?.viewport?.renderSettings.showCellColor, isTrue);
      expect(saved?.viewport?.renderSettings.showGrid, isFalse);
      expect(saved?.viewport?.renderSettings.showCompletedCellOverlay, isFalse);
      expect(
        saved?.viewport?.renderSettings.selectionHighlightColor,
        SelectionHighlightColorPreset.teal,
      );

      await selectWorkspaceMenuOption(
        tester,
        const ValueKey('floating-menu-completion-selection'),
      );
      expect(painter().settings.showCompletedCellOverlay, isTrue);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Sampler'));
      await tester.pumpAndSettle();
      expect(painter().settings.showCellColor, isTrue);
      expect(painter().settings.showGrid, isFalse);
      expect(painter().settings.showCompletedCellOverlay, isTrue);
      expect(
        painter().settings.selectionHighlightColor,
        SelectionHighlightColorPreset.teal,
      );
    },
  );

  testWidgets(
    'restores the settled camera with renderer settings after reopening',
    (tester) async {
      final documents = InMemoryPatternDocumentRepository();
      final progress = InMemoryProgressRepository();
      await tester.pumpWidget(
        buildLibraryApp(
          documents,
          progress: progress,
          seedDocument: LargeSamplePatternFixture.create(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Large Test Pattern'));
      await tester.pumpAndSettle();

      final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
      ViewportPatternPainter painter() =>
          tester.widget<CustomPaint>(canvasFinder).painter!
              as ViewportPatternPainter;

      await selectWorkspaceMenuOption(
        tester,
        const ValueKey('floating-menu-renderer-settings'),
      );
      await tester.tap(find.byKey(const ValueKey('show-cell-color-setting')));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('pattern-viewport')),
        const Offset(-80, -40),
      );
      await tester.pump(const Duration(milliseconds: 300));
      final movedCamera = painter().camera;
      final saved = await progress.getForDocument('sample-large-test-pattern');

      expect(saved?.viewport, isNotNull);
      expect(saved?.viewport?.zoom, movedCamera.cellSize);
      expect(
        saved?.viewport?.panX,
        closeTo(movedCamera.origin.dx / movedCamera.cellSize, 0.000001),
      );
      expect(saved?.viewport?.renderSettings.showCellColor, isTrue);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Large Test Pattern'));
      await tester.pumpAndSettle();

      final restoredCamera = painter().camera;
      expect(restoredCamera.cellSize, movedCamera.cellSize);
      expect(painter().settings.showCellColor, isTrue);
      final restoredCenter = restoredCamera.screenToGrid(
        tester.getSize(canvasFinder).center(Offset.zero),
      );
      expect(restoredCenter.dx.floor(), saved?.viewport?.anchor.column);
      expect(restoredCenter.dy.floor(), saved?.viewport?.anchor.row);
    },
  );

  testWidgets(
    'selects exact cells for completion, persists the action, and undoes it',
    (tester) async {
      final documents = InMemoryPatternDocumentRepository();
      final progress = InMemoryProgressRepository();
      await tester.pumpWidget(
        buildLibraryApp(
          documents,
          progress: progress,
          seedDocument: SamplePatternFixture.create(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Sampler'));
      await tester.pumpAndSettle();

      final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
      ViewportPatternPainter painter() =>
          tester.widget<CustomPaint>(canvasFinder).painter!
              as ViewportPatternPainter;
      final firstFlowerCenter =
          tester.getTopLeft(canvasFinder) +
          painter().camera.gridToScreen(row: 0.5, column: 0.5);

      await selectWorkspaceMenuOption(
        tester,
        const ValueKey('floating-menu-completion-selection'),
      );
      expect(
        find.byKey(const ValueKey('completion-action-bar')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PatternRenderView>(find.byType(PatternRenderView))
            .interactionMode,
        PatternInteractionMode.editCompletion,
      );

      await tester.tapAt(firstFlowerCenter);
      await tester.pumpAndSettle();
      expect(painter().completionSelection, <GridCoordinate>{
        const GridCoordinate(0, 0),
      });
      expect(painter().selection.hasSelection, isFalse);
      expect(find.text('1 selected'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mark-completed')));
      await tester.pumpAndSettle();
      expect(painter().completedCells, contains(const GridCoordinate(0, 0)));
      expect(painter().completionSelection, isEmpty);
      expect(
        (await progress.getForDocument('sample-garden-sampler'))
            ?.completedCells,
        <GridCoordinate>[const GridCoordinate(0, 0)],
      );
      final undoFinder = find.byKey(const ValueKey('completion-undo-snackbar'));
      expect(
        tester
            .getRect(undoFinder)
            .overlaps(
              tester.getRect(find.byKey(const ValueKey('mark-completed'))),
            ),
        isFalse,
      );
      await tester.pump(const Duration(seconds: 4));
      expect(undoFinder, findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('undo-completion-action')));
      await tester.pumpAndSettle();
      expect(painter().completedCells, isEmpty);
      expect(
        (await progress.getForDocument('sample-garden-sampler'))
            ?.completedCells,
        isEmpty,
      );
    },
  );

  testWidgets('marks an exact completed cell incomplete', (tester) async {
    final documents = InMemoryPatternDocumentRepository();
    final progress = InMemoryProgressRepository();
    await progress.save(
      ProgressState(
        documentId: 'sample-garden-sampler',
        schemaVersion: 1,
        completedCells: const <GridCoordinate>[GridCoordinate(0, 0)],
        lastInteractionAt: DateTime.utc(2026, 11, 7),
      ),
    );
    await tester.pumpWidget(
      buildLibraryApp(
        documents,
        progress: progress,
        seedDocument: SamplePatternFixture.create(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garden Sampler'));
    await tester.pumpAndSettle();

    final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
    ViewportPatternPainter painter() =>
        tester.widget<CustomPaint>(canvasFinder).painter!
            as ViewportPatternPainter;
    final firstFlowerCenter =
        tester.getTopLeft(canvasFinder) +
        painter().camera.gridToScreen(row: 0.5, column: 0.5);

    await selectWorkspaceMenuOption(
      tester,
      const ValueKey('floating-menu-completion-selection'),
    );
    await tester.tapAt(firstFlowerCenter);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mark-incomplete')));
    await tester.pumpAndSettle();
    expect(painter().completedCells, isEmpty);
    expect(
      (await progress.getForDocument('sample-garden-sampler'))?.completedCells,
      isEmpty,
    );
    expect(
      find.byKey(const ValueKey('completion-undo-snackbar')),
      findsOneWidget,
    );

    await selectWorkspaceMenuOption(
      tester,
      const ValueKey('floating-menu-renderer-settings'),
    );
    expect(
      find.byKey(const ValueKey('completion-undo-snackbar')),
      findsNothing,
    );
    await selectWorkspaceMenuOption(
      tester,
      const ValueKey('floating-menu-completion-selection'),
    );
    await tester.tapAt(firstFlowerCenter);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('mark-completed')));
    await tester.pump();
    final undoFinder = find.byKey(const ValueKey('completion-undo-snackbar'));
    await tester.pump(const Duration(milliseconds: 4900));
    expect(undoFinder, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(undoFinder, findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('floating-menu-toggle')));
    await tester.pump();
    expect(undoFinder, findsNothing);
  });

  testWidgets(
    'selects a cell symbol, inspects matching cells, and clears selection',
    (tester) async {
      final documents = InMemoryPatternDocumentRepository();
      final progress = InMemoryProgressRepository();
      await tester.pumpWidget(
        buildLibraryApp(
          documents,
          progress: progress,
          seedDocument: SamplePatternFixture.create(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Sampler'));
      await tester.pumpAndSettle();

      final canvasFinder = find.byKey(const ValueKey('pattern-grid-canvas'));
      ViewportPatternPainter painter() =>
          tester.widget<CustomPaint>(canvasFinder).painter!
              as ViewportPatternPainter;
      final flowerCenter =
          tester.getTopLeft(canvasFinder) +
          painter().camera.gridToScreen(row: 0.5, column: 0.5);

      await tester.tapAt(flowerCenter);
      await tester.pumpAndSettle();
      expect(painter().selection.selectedSymbolId, 'flower');
      expect(painter().selectedVisibleCells, hasLength(2));
      expect(await progress.getForDocument('sample-garden-sampler'), isNull);

      await selectWorkspaceMenuOption(
        tester,
        const ValueKey('floating-menu-symbol-palette'),
      );
      expect(
        find.byKey(const ValueKey('symbol-palette-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('selected-symbol-details')),
        findsOneWidget,
      );
      expect(find.text('DMC 321'), findsWidgets);

      final originBeforePan = painter().camera.origin;
      await tester.dragFrom(
        tester.getTopLeft(canvasFinder) + const Offset(300, 300),
        const Offset(-50, 0),
      );
      await tester.pumpAndSettle();
      expect(painter().camera.origin.dx, lessThan(originBeforePan.dx));
      expect(painter().selection.selectedSymbolId, 'flower');

      await tester.tap(find.byKey(const ValueKey('symbol-palette-leaf')));
      await tester.pumpAndSettle();
      expect(painter().selection.selectedSymbolId, 'leaf');
      expect(painter().selectedVisibleCells, hasLength(1));
      await tester.tap(find.byKey(const ValueKey('clear-symbol-selection')));
      await tester.pumpAndSettle();
      expect(painter().selection.hasSelection, isFalse);
      expect(painter().selectedVisibleCells, isEmpty);
    },
  );

  testWidgets('shows backstitch thread details from the symbol palette', (
    tester,
  ) async {
    final documents = InMemoryPatternDocumentRepository();
    final progress = InMemoryProgressRepository();
    await tester.pumpWidget(
      buildLibraryApp(
        documents,
        progress: progress,
        seedDocument: SamplePatternFixture.create(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garden Sampler'));
    await tester.pumpAndSettle();

    await selectWorkspaceMenuOption(
      tester,
      const ValueKey('floating-menu-symbol-palette'),
    );
    final backstitch = find.byKey(
      const ValueKey('backstitch-palette-#C72C41'),
    );
    expect(
      find.byKey(const ValueKey('backstitch-palette-#5B8C3A')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('backstitch-palette-sample-flower-outline-right'),
      ),
      findsNothing,
    );
    await tester.scrollUntilVisible(backstitch, 160);
    await tester.tap(backstitch);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('selected-backstitch-details')), findsOneWidget);
    expect(find.text('2 matching backstitch segments'), findsOneWidget);
    expect(find.textContaining('Endpoints:'), findsNothing);
  });
}

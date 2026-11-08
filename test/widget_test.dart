import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/app/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_interaction.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_render_selection.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport_pattern_painter.dart';
import 'package:stitch_scope/presentation/screens/library_screen.dart';
import 'package:stitch_scope/presentation/screens/pattern_workspace_screen.dart';

import 'domain/in_memory_repositories.dart';

/// Covers the empty and persisted-pattern states of the library screen.
void main() {
  testWidgets('shows empty-library guidance when seeding is disabled', (
    tester,
  ) async {
    final repository = InMemoryPatternDocumentRepository();

    await tester.pumpWidget(_libraryApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Your pattern library starts here'), findsOneWidget);
    expect(find.text('Garden Sampler'), findsNothing);
  });

  testWidgets('seeds and opens the sample pattern from the library', (
    tester,
  ) async {
    final repository = InMemoryPatternDocumentRepository();

    await tester.pumpWidget(
      _libraryApp(repository, seedDocument: SamplePatternFixture.create()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Garden Sampler'), findsOneWidget);
    expect(await repository.getById('sample-garden-sampler'), isNotNull);

    await tester.tap(find.text('Garden Sampler'));
    await tester.pumpAndSettle();

    expect(find.text('Pattern Workspace'), findsNothing);
    expect(find.text('4 × 5'), findsOneWidget);
    expect(find.text('Garden Sampler'), findsOneWidget);
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.toolbarHeight, 48);
    expect(
      (appBar.leading! as IconButton).key,
      const ValueKey('workspace-back'),
    );
    expect(find.byKey(const ValueKey('floating-menu-toggle')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('floating-menu-renderer-settings')),
      findsNothing,
    );
    expect(find.byKey(const ValueKey('pattern-viewport')), findsOneWidget);
    expect(find.byKey(const ValueKey('pattern-grid-canvas')), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsNothing);
    final canvas = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('pattern-grid-canvas')),
    );
    final painter = canvas.painter! as ViewportPatternPainter;
    expect(painter.document.grid.cells, hasLength(3));
    expect(painter.document.symbolById('flower')?.thread.color, '#C72C41');
    expect(
      painter.document.grid.cellsIntersecting(painter.visibleBounds),
      hasLength(3),
    );

    await _selectWorkspaceMenuOption(
      tester,
      const ValueKey('floating-menu-renderer-settings'),
    );
    expect(
      find.byKey(const ValueKey('renderer-settings-panel')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('workspace-back')));
    await tester.pumpAndSettle();
    expect(find.text('Pattern Library'), findsOneWidget);
  });

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

  testWidgets('floating menu activates only one workspace surface', (
    tester,
  ) async {
    final documents = InMemoryPatternDocumentRepository();
    await tester.pumpWidget(
      _libraryApp(documents, seedDocument: SamplePatternFixture.create()),
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

    await _selectWorkspaceMenuOption(
      tester,
      const ValueKey('floating-menu-symbol-palette'),
    );
    expect(find.byKey(const ValueKey('renderer-settings-panel')), findsNothing);
    expect(find.byKey(const ValueKey('symbol-palette-panel')), findsOneWidget);
    expect(find.byKey(const ValueKey('completion-action-bar')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('close-symbol-palette')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('symbol-palette-panel')), findsNothing);

    await _selectWorkspaceMenuOption(
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

  testWidgets('upserts seed patterns without clearing the library', (
    tester,
  ) async {
    final repository = InMemoryPatternDocumentRepository();
    await repository.save(SamplePatternFixture.create());

    await tester.pumpWidget(
      _libraryApp(
        repository,
        seedDocuments: [
          SamplePatternFixture.create(),
          LargeSamplePatternFixture.create(),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(await repository.listSummaries(), hasLength(2));
    expect(find.text('Garden Sampler'), findsOneWidget);
    expect(find.text('Large Test Pattern'), findsOneWidget);
  });

  testWidgets(
    'changes and persists renderer settings without resetting camera',
    (tester) async {
      final documents = InMemoryPatternDocumentRepository();
      final progress = InMemoryProgressRepository();

      await tester.pumpWidget(
        _libraryApp(
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
      await _selectWorkspaceMenuOption(
        tester,
        const ValueKey('floating-menu-renderer-settings'),
      );
      expect(
        find.byKey(const ValueKey('floating-menu-toggle')),
        findsOneWidget,
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
      expect(find.byKey(const ValueKey('grid-color-setting')), findsNothing);
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
        find.byKey(const ValueKey('include-completed-in-selection-setting')),
        findsNothing,
      );
      expect(
        painter().settings.selectionHighlightColor,
        SelectionHighlightColorPreset.teal,
      );
      expect(painter().camera, cameraBeforeChange);
      final saved = await progress.getForDocument('sample-garden-sampler');
      expect(saved?.viewport?.renderSettings.showCellColor, isTrue);
      expect(saved?.viewport?.renderSettings.showGrid, isFalse);
      expect(saved?.viewport?.renderSettings.showCompletedCellOverlay, isFalse);
      expect(
        saved?.viewport?.renderSettings.includeCompletedCellsInSelection,
        isTrue,
      );
      expect(
        saved?.viewport?.renderSettings.selectionHighlightColor,
        SelectionHighlightColorPreset.teal,
      );

      await _selectWorkspaceMenuOption(
        tester,
        const ValueKey('floating-menu-completion-selection'),
      );
      expect(painter().settings.showCompletedCellOverlay, isTrue);
      expect(
        (await progress.getForDocument('sample-garden-sampler'))
            ?.viewport
            ?.renderSettings
            .showCompletedCellOverlay,
        isTrue,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Sampler'));
      await tester.pumpAndSettle();
      expect(painter().settings.showCellColor, isTrue);
      expect(painter().settings.showGrid, isFalse);
      expect(painter().settings.showCompletedCellOverlay, isTrue);
      expect(painter().settings.includeCompletedCellsInSelection, isTrue);
      expect(
        painter().settings.selectionHighlightColor,
        SelectionHighlightColorPreset.teal,
      );
    },
  );

  testWidgets(
    'selects exact cells for completion, persists the action, and undoes it',
    (tester) async {
      final documents = InMemoryPatternDocumentRepository();
      final progress = InMemoryProgressRepository();

      await tester.pumpWidget(
        _libraryApp(
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

      await _selectWorkspaceMenuOption(
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
      expect(
        painter().completionSelectionOverlayColor.withValues(alpha: 1),
        Theme.of(tester.element(canvasFinder)).colorScheme.primary,
      );
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
      final undoRect = tester.getRect(undoFinder);
      expect(
        undoRect.overlaps(
          tester.getRect(find.byKey(const ValueKey('mark-completed'))),
        ),
        isFalse,
      );
      expect(
        undoRect.overlaps(
          tester.getRect(find.byKey(const ValueKey('floating-menu-toggle'))),
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
      _libraryApp(
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

    await _selectWorkspaceMenuOption(
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

    await _selectWorkspaceMenuOption(
      tester,
      const ValueKey('floating-menu-renderer-settings'),
    );
    expect(
      find.byKey(const ValueKey('completion-undo-snackbar')),
      findsNothing,
    );

    await _selectWorkspaceMenuOption(
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

  testWidgets(
    'selects a cell symbol, inspects matching cells, and clears selection',
    (tester) async {
      final documents = InMemoryPatternDocumentRepository();
      final progress = InMemoryProgressRepository();

      await tester.pumpWidget(
        _libraryApp(
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
      expect(find.byKey(const ValueKey('symbol-palette-panel')), findsNothing);
      expect(
        find.byKey(const ValueKey('selected-symbol-details')),
        findsNothing,
      );
      expect(await progress.getForDocument('sample-garden-sampler'), isNull);

      await _selectWorkspaceMenuOption(
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
      expect(painter().selectedVisibleCells, hasLength(2));

      await tester.tap(find.byKey(const ValueKey('symbol-palette-leaf')));
      await tester.pumpAndSettle();
      expect(painter().selection.selectedSymbolId, 'leaf');
      expect(painter().selectedVisibleCells, hasLength(1));

      await tester.tap(find.byKey(const ValueKey('clear-symbol-selection')));
      await tester.pumpAndSettle();
      expect(painter().selection.hasSelection, isFalse);
      expect(painter().selectedVisibleCells, isEmpty);
      expect(
        find.byKey(const ValueKey('selected-symbol-details')),
        findsNothing,
      );
    },
  );
}

/// Wraps a library screen in the Material context required by widget tests.
Widget _libraryApp(
  InMemoryPatternDocumentRepository repository, {
  InMemoryProgressRepository? progress,
  List<PatternDocument> seedDocuments = const [],
  PatternDocument? seedDocument,
}) => MaterialApp(
  home: LibraryScreen(
    patternDocuments: repository,
    progress: progress ?? InMemoryProgressRepository(),
    seedDocuments: seedDocuments,
    seedDocument: seedDocument,
  ),
);

/// Opens the workspace menu when necessary and selects one visible choice.
Future<void> _selectWorkspaceMenuOption(
  WidgetTester tester,
  ValueKey<String> optionKey,
) async {
  if (find.byKey(optionKey).evaluate().isEmpty) {
    await tester.tap(find.byKey(const ValueKey('floating-menu-toggle')));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(optionKey));
  await tester.pumpAndSettle();
}

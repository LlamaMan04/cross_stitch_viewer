import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/app/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/progress_models.dart';
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
    expect(
      find.byKey(const ValueKey('renderer-settings-toggle')),
      findsOneWidget,
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

    await tester.tap(find.byKey(const ValueKey('renderer-settings-toggle')));
    await tester.pumpAndSettle();
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
      await tester.tap(find.byKey(const ValueKey('renderer-settings-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('renderer-settings-toggle')),
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
      await tester.tap(
        find.byKey(const ValueKey('selection-highlight-color-setting')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Teal').last);
      await tester.pumpAndSettle();

      expect(painter().settings.showCellColor, isTrue);
      expect(painter().settings.showGrid, isFalse);
      expect(
        painter().settings.selectionHighlightColor,
        SelectionHighlightColorPreset.teal,
      );
      expect(painter().camera, cameraBeforeChange);
      final saved = await progress.getForDocument('sample-garden-sampler');
      expect(saved?.viewport?.renderSettings.showCellColor, isTrue);
      expect(saved?.viewport?.renderSettings.showGrid, isFalse);
      expect(
        saved?.viewport?.renderSettings.selectionHighlightColor,
        SelectionHighlightColorPreset.teal,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Garden Sampler'));
      await tester.pumpAndSettle();
      expect(painter().settings.showCellColor, isTrue);
      expect(painter().settings.showGrid, isFalse);
      expect(
        painter().settings.selectionHighlightColor,
        SelectionHighlightColorPreset.teal,
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
      expect(
        find.byKey(const ValueKey('symbol-palette-panel')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('selected-symbol-details')),
        findsOneWidget,
      );
      expect(find.text('DMC 321'), findsWidgets);
      expect(await progress.getForDocument('sample-garden-sampler'), isNull);

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

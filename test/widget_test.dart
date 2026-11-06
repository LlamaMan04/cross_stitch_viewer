import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/app/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
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

    expect(find.text('Pattern Workspace'), findsOneWidget);
    expect(find.text('4 × 5'), findsOneWidget);
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

  testWidgets('replaces existing patterns with both seed patterns', (
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
}

/// Wraps a library screen in the Material context required by widget tests.
Widget _libraryApp(
  InMemoryPatternDocumentRepository repository, {
  List<PatternDocument> seedDocuments = const [],
  PatternDocument? seedDocument,
}) => MaterialApp(
  home: LibraryScreen(
    patternDocuments: repository,
    seedDocuments: seedDocuments,
    seedDocument: seedDocument,
  ),
);

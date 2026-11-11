import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport_pattern_painter.dart';

import '../../domain/in_memory_repositories.dart';
import '../../support/library_app_harness.dart';

/// Covers library loading, seeding, and navigation into a workspace.
void main() {
  testWidgets('shows empty-library guidance when seeding is disabled', (
    tester,
  ) async {
    final repository = InMemoryPatternDocumentRepository();

    await tester.pumpWidget(buildLibraryApp(repository));
    await tester.pumpAndSettle();

    expect(find.text('Your pattern library starts here'), findsOneWidget);
    expect(find.text('Garden Sampler'), findsNothing);
  });

  testWidgets('seeds and opens the sample pattern from the library', (
    tester,
  ) async {
    final repository = InMemoryPatternDocumentRepository();

    await tester.pumpWidget(
      buildLibraryApp(repository, seedDocument: SamplePatternFixture.create()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Garden Sampler'), findsOneWidget);
    expect(await repository.getById('sample-garden-sampler'), isNotNull);

    await tester.tap(find.text('Garden Sampler'));
    await tester.pumpAndSettle();

    expect(find.text('Pattern Workspace'), findsNothing);
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

    await selectWorkspaceMenuOption(
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

  testWidgets('upserts seed patterns without clearing the library', (
    tester,
  ) async {
    final repository = InMemoryPatternDocumentRepository();
    await repository.save(SamplePatternFixture.create());

    await tester.pumpWidget(
      buildLibraryApp(
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

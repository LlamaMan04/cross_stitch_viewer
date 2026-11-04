import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
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
    expect(find.byKey(const ValueKey('pattern-grid-canvas')), findsOneWidget);
    final interactiveViewer = tester.widget<InteractiveViewer>(
      find.byKey(const ValueKey('pattern-interactive-viewer')),
    );
    expect(interactiveViewer.panEnabled, isTrue);
    expect(interactiveViewer.scaleEnabled, isTrue);
    expect(interactiveViewer.minScale, 1);
    expect(interactiveViewer.maxScale, 8);
    expect(interactiveViewer.boundaryMargin, const EdgeInsets.all(24));
    final padding = tester.widget<Padding>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Padding && widget.padding == const EdgeInsets.all(24),
      ),
    );
    expect(padding.padding, const EdgeInsets.all(24));
    final canvas = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('pattern-grid-canvas')),
    );
    final painter = canvas.painter! as PatternGridPainter;
    expect(painter.document.grid.cells, hasLength(3));
    expect(painter.document.symbolById('flower')?.thread.color, '#C72C41');
  });
}

/// Wraps a library screen in the Material context required by widget tests.
Widget _libraryApp(
  InMemoryPatternDocumentRepository repository, {
  PatternDocument? seedDocument,
}) => MaterialApp(
  home: LibraryScreen(patternDocuments: repository, seedDocument: seedDocument),
);

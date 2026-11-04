import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/presentation/screens/library_screen.dart';

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
    expect(find.text('4 rows × 5 columns'), findsOneWidget);
  });
}

/// Wraps a library screen in the Material context required by widget tests.
Widget _libraryApp(
  InMemoryPatternDocumentRepository repository, {
  PatternDocument? seedDocument,
}) => MaterialApp(
  home: LibraryScreen(patternDocuments: repository, seedDocument: seedDocument),
);

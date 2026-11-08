import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/presentation/screens/library_screen.dart';

import '../domain/in_memory_repositories.dart';

/// Builds a library screen with in-memory repositories for widget tests.
Widget buildLibraryApp(
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
Future<void> selectWorkspaceMenuOption(
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

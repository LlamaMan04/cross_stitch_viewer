import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/presentation/screens/settings_screen.dart';

import '../../domain/in_memory_repositories.dart';

void main() {
  testWidgets('does not load sample patterns until the button is selected', (
    tester,
  ) async {
    final repository = InMemoryPatternDocumentRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(patternDocuments: repository),
      ),
    );
    await tester.pumpAndSettle();

    expect(await repository.listSummaries(), isEmpty);

    await tester.tap(find.byKey(const ValueKey('load-sample-patterns')));
    await tester.pumpAndSettle();

    expect(await repository.listSummaries(), hasLength(3));
    expect(find.text('Sample patterns loaded.'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/backstitch_sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_backstitch.dart';

/// Verifies that the backstitch rendering fixture covers the planned geometry.
void main() {
  test('creates representative backstitch geometry and shared colors', () {
    final document = BackstitchSamplePatternFixture.create();

    expect(
      document.backstitches,
      hasLength(BackstitchSamplePatternFixture.backstitchCount),
    );
    expect(document.backstitchDefinitions, hasLength(3));
    expect(
      document.backstitchDefinitions.where(
        (definition) => definition.threadId == 'thread-red',
      ),
      hasLength(BackstitchSamplePatternFixture.sameColorDefinitionCount),
    );
    expect(
      document.backstitches.map((backstitch) => backstitch.id),
      containsAll(<String>{
        'horizontal',
        'vertical',
        'diagonal',
        'partial-cell',
        'shared-endpoint-a',
        'shared-endpoint-b',
        'crossing-viewport',
      }),
    );
    expect(
      document.backstitchById('partial-cell')?.start,
      const BackstitchCoordinate(row: 1.5, column: 0.5),
    );
    expect(
      document.backstitchById('shared-endpoint-a')?.end,
      document.backstitchById('shared-endpoint-b')?.start,
    );

    document.validate();
  });
}

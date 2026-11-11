import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';

/// Verifies the built-in sample contains representative linear stitch data.
void main() {
  test('creates the garden sample with backstitch details', () {
    final document = SamplePatternFixture.create();

    expect(
      document.backstitches,
      hasLength(SamplePatternFixture.backstitchCount),
    );
    expect(
      document.backstitches.map((backstitch) => backstitch.id),
      containsAll(<String>{
        'sample-flower-outline-top',
        'sample-flower-outline-right',
        'sample-leaf-vein',
      }),
    );
    document.validate();
  });
}

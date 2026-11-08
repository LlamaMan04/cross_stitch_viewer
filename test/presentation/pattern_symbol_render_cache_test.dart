import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/sample_pattern_fixture.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_symbol_render_cache.dart';

/// Verifies parsed symbol metadata and opacity-specific paint reuse.
void main() {
  test(
    'parses symbol colors once and reuses the active-opacity fill paint',
    () {
      final cache = PatternSymbolRenderCache(SamplePatternFixture.create());

      final metadata = cache.metadataFor('flower');
      final firstPaint = cache.fillPaintFor('flower', 0.22);
      final reusedPaint = cache.fillPaintFor('flower', 0.22);
      final changedOpacityPaint = cache.fillPaintFor('flower', 0.5);

      expect(metadata?.threadColor, const Color(0xFFC72C41));
      expect(reusedPaint, same(firstPaint));
      expect(changedOpacityPaint, isNot(same(firstPaint)));
      expect(changedOpacityPaint?.color.a, closeTo(0.5, 0.001));
      expect(cache.metadataFor('missing'), isNull);
      expect(cache.fillPaintFor('missing', 0.22), isNull);
    },
  );
}

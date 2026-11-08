import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_glyph_layout_cache.dart';

/// Verifies reuse and bounded eviction of renderer glyph layouts.
void main() {
  test('reuses matching glyph layouts and evicts the least recent entry', () {
    final cache = PatternGlyphLayoutCache(maximumEntries: 2);
    addTearDown(cache.dispose);

    final firstLayout = cache.layoutFor(
      glyph: 'X',
      foreground: Colors.black,
      fontSize: 16,
    );
    final reusedLayout = cache.layoutFor(
      glyph: 'X',
      foreground: Colors.black,
      fontSize: 16,
    );
    cache.layoutFor(glyph: 'O', foreground: Colors.black, fontSize: 16);
    cache.layoutFor(glyph: '+', foreground: Colors.white, fontSize: 18);
    final replacementLayout = cache.layoutFor(
      glyph: 'X',
      foreground: Colors.black,
      fontSize: 16,
    );

    expect(reusedLayout, same(firstLayout));
    expect(replacementLayout, isNot(same(firstLayout)));
  });
}

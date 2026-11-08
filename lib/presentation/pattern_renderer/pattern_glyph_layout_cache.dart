import 'dart:collection';

import 'package:flutter/material.dart';

/// Reuses bounded glyph layouts across renderer paint passes.
class PatternGlyphLayoutCache {
  /// Creates a least-recently-used cache capped at [maximumEntries].
  PatternGlyphLayoutCache({this.maximumEntries = 128})
    : assert(maximumEntries > 0);

  /// Maximum number of native text layouts retained by this cache.
  final int maximumEntries;

  /// Layouts ordered from least to most recently used.
  final LinkedHashMap<
    ({String glyph, Color foreground, double fontSize}),
    TextPainter
  >
  _layouts = LinkedHashMap();

  /// Returns a laid-out glyph matching the supplied visual inputs.
  TextPainter layoutFor({
    required String glyph,
    required Color foreground,
    required double fontSize,
  }) {
    final key = (glyph: glyph, foreground: foreground, fontSize: fontSize);
    final cachedLayout = _layouts.remove(key);
    if (cachedLayout != null) {
      // Reinsertion promotes this entry to the most-recently-used position.
      _layouts[key] = cachedLayout;
      return cachedLayout;
    }

    final layout = TextPainter(
      text: TextSpan(
        text: glyph,
        style: TextStyle(
          color: foreground,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    _layouts[key] = layout;
    if (_layouts.length > maximumEntries) {
      final oldestKey = _layouts.keys.first;
      _layouts.remove(oldestKey)?.dispose();
    }
    return layout;
  }

  /// Releases every native text layout retained by the cache.
  void dispose() {
    for (final layout in _layouts.values) {
      layout.dispose();
    }
    _layouts.clear();
  }
}

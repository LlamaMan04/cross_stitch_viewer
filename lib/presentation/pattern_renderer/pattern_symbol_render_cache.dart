import 'package:flutter/material.dart';

import '../../domain/pattern_backstitch.dart';
import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/pattern_document.dart';

/// Immutable presentation metadata derived once from a pattern symbol.
class PatternSymbolRenderMetadata {
  /// Creates renderer metadata for [symbol] and its parsed [threadColor].
  const PatternSymbolRenderMetadata({
    required this.symbol,
    required this.threadId,
    required this.threadColor,
  });

  /// Source symbol definition used for glyph and thread details.
  final SymbolDefinition symbol;

  /// Stable thread identity used for cross-definition selection.
  final String threadId;

  /// Opaque thread color parsed from the symbol's canonical RGB value.
  final Color threadColor;
}

/// Cached geometry and opaque thread color for one backstitch.
class BackstitchRenderMetadata {
  /// Resolves immutable rendering information for a segment and definition.
  BackstitchRenderMetadata({
    required this.segment,
    required this.definition,
    required ThreadDefinition thread,
  }) : threadId = thread.id,
       threadColor = PatternSymbolRenderCache._parseColor(thread.color),
       bounds = Rect.fromLTRB(
         segment.start.column < segment.end.column
             ? segment.start.column
             : segment.end.column,
         segment.start.row < segment.end.row
             ? segment.start.row
             : segment.end.row,
         segment.start.column > segment.end.column
             ? segment.start.column
             : segment.end.column,
         segment.start.row > segment.end.row
             ? segment.start.row
             : segment.end.row,
       );

  /// Source line and stable segment identity.
  final BackstitchSegment segment;

  /// Reusable stitch definition referenced by [segment].
  final BackstitchDefinition definition;

  /// Opaque color resolved before painting.
  final Color threadColor;

  /// Stable thread identity used to select matching linework.
  final String threadId;

  /// Inclusive axis-aligned bounds in pattern coordinates.
  final Rect bounds;

  /// Whether the line's bounds touch the visible grid rectangle.
  bool intersects(GridBounds visible) =>
      !visible.isEmpty &&
      bounds.right >= visible.startColumn &&
      bounds.left <= visible.endColumn &&
      bounds.bottom >= visible.startRow &&
      bounds.top <= visible.endRow;
}

/// Reuses parsed symbol colors and opacity-specific fill paints.
class PatternSymbolRenderCache {
  /// Creates render metadata for every symbol in [document].
  PatternSymbolRenderCache(PatternDocument document)
    : _metadataById = Map<String, PatternSymbolRenderMetadata>.unmodifiable({
        for (final symbol in document.symbols)
          symbol.id: PatternSymbolRenderMetadata(
            symbol: symbol,
            threadId: symbol.threadId,
            threadColor: _parseColor(document.threadForSymbol(symbol)!.color),
          ),
      }),
      _backstitches = List.unmodifiable(
        document.backstitches.map((segment) {
          final definition = document.definitionForBackstitch(segment)!;
          return BackstitchRenderMetadata(
            segment: segment,
            definition: definition,
            thread: document.threadForBackstitch(definition)!,
          );
        }),
      );

  /// Immutable render metadata keyed by stable symbol ID.
  final Map<String, PatternSymbolRenderMetadata> _metadataById;

  /// Compact immutable list used for visible backstitch queries.
  final List<BackstitchRenderMetadata> _backstitches;

  /// Returns immutable candidates, including lines crossing the visible range.
  List<BackstitchRenderMetadata> backstitchesIntersecting(GridBounds bounds) =>
      List.unmodifiable(_backstitches.where((line) => line.intersects(bounds)));

  /// Fill paints for the single opacity currently used by the viewport.
  final Map<String, Paint> _fillPaints = <String, Paint>{};

  /// Opacity represented by [_fillPaints], or null before the first request.
  double? _fillOpacity;

  /// Returns precomputed metadata for [symbolId], if the document defines it.
  PatternSymbolRenderMetadata? metadataFor(String symbolId) =>
      _metadataById[symbolId];

  /// Returns one shared fill paint for [symbolId] at [opacity].
  Paint? fillPaintFor(String symbolId, double opacity) {
    final metadata = _metadataById[symbolId];
    if (metadata == null) return null;
    if (_fillOpacity != opacity) {
      _fillPaints.clear();
      _fillOpacity = opacity;
    }
    return _fillPaints.putIfAbsent(
      symbolId,
      () => Paint()..color = metadata.threadColor.withValues(alpha: opacity),
    );
  }

  /// Calculates a population-weighted RGB color from symbol [counts].
  Color? weightedAverageColorFor(Map<String, int> counts) {
    var red = 0;
    var green = 0;
    var blue = 0;
    var colorCellCount = 0;
    for (final entry in counts.entries) {
      final metadata = _metadataById[entry.key];
      if (metadata == null || entry.value <= 0) continue;
      final colorValue = metadata.threadColor.toARGB32();
      red += ((colorValue >> 16) & 0xFF) * entry.value;
      green += ((colorValue >> 8) & 0xFF) * entry.value;
      blue += (colorValue & 0xFF) * entry.value;
      colorCellCount += entry.value;
    }
    if (colorCellCount == 0) return null;
    return Color.fromARGB(
      255,
      (red / colorCellCount).round(),
      (green / colorCellCount).round(),
      (blue / colorCellCount).round(),
    );
  }

  /// Converts a validated canonical RGB value into an opaque color.
  static Color _parseColor(String value) =>
      Color(int.parse('FF${value.substring(1)}', radix: 16));
}

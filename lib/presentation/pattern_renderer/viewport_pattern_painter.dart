import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/progress_models.dart';
import '../../domain/value_objects.dart';
import 'pattern_camera.dart';
import 'pattern_glyph_layout_cache.dart';
import 'pattern_render_selection.dart';
import 'pattern_symbol_render_cache.dart';
import 'render_lod.dart';

/// Paints only the pattern cells and rules intersecting visible grid bounds.
class ViewportPatternPainter extends CustomPainter {
  /// Creates a painter from immutable document, camera, bounds, and theme data.
  ViewportPatternPainter({
    required this.document,
    required this.camera,
    required this.visibleBounds,
    required this.settings,
    required this.selection,
    required this.completedCells,
    required this.completionSelection,
    required this.surfaceColor,
    required this.regionColor,
    required this.completionSelectionColor,
    required this.glyphLayoutCache,
    required this.symbolRenderCache,
    required this.renderLod,
    required this.completedTileCoordinates,
  });

  /// Normalized source document rendered by this painter.
  final PatternDocument document;

  /// Camera that maps grid coordinates directly into screen coordinates.
  final PatternCamera camera;

  /// Half-open grid range that this paint pass may inspect.
  final GridBounds visibleBounds;

  /// Persisted visual switches and colors for this paint pass.
  final PatternRenderSettings settings;

  /// Ephemeral symbol selection highlighted during this paint pass.
  final PatternRenderSelection selection;

  /// Completed grid coordinates used by dynamic cell overlays.
  final Set<GridCoordinate> completedCells;

  /// Exact coordinates selected for a pending completion action.
  final Set<GridCoordinate> completionSelection;

  /// Background color used for the viewport and empty cells.
  final Color surfaceColor;

  /// Theme color used for enabled source-region outlines.
  final Color regionColor;

  /// Primary application color used by completion-selection overlays.
  final Color completionSelectionColor;

  /// Shared glyph layouts retained across otherwise short-lived painters.
  final PatternGlyphLayoutCache glyphLayoutCache;

  /// Parsed symbol colors and fill paints shared across viewport painters.
  final PatternSymbolRenderCache symbolRenderCache;

  /// Automatic detail policy resolved by the viewport with hysteresis.
  final RenderLod renderLod;

  /// Tiles containing completed cells, indexed outside the paint loop.
  final Set<PatternTileCoordinate> completedTileCoordinates;

  /// Completed-cell color and opacity resolved once for this paint delegate.
  late final Color _completedOverlayColor = _parseColor(
    settings.completedCellColor.colorHex,
  ).withValues(alpha: settings.completedCellOpacity);

  /// Paint reused for every completed-cell overlay in this delegate.
  late final Paint _completedOverlayPaint = Paint()
    ..color = _completedOverlayColor;

  /// Visible populated cells materialized only when a cell layer needs them.
  late final List<StitchCell> _visibleCells = List<StitchCell>.unmodifiable(
    document.grid.cellsIntersecting(visibleBounds),
  );

  /// Tile summaries queried lazily only by overview rendering.
  late final List<PatternTileSummary> _visibleTileSummaries =
      List<PatternTileSummary>.unmodifiable(
        document.grid.tileSummariesIntersecting(visibleBounds),
      );

  /// Tiles containing pending exact-cell completion selections.
  late final Set<PatternTileCoordinate> _completionSelectionTiles =
      Set<PatternTileCoordinate>.unmodifiable(
        completionSelection.map(PatternGrid.tileCoordinateFor),
      );

  /// Completed populated cells intersecting the current visible bounds.
  Iterable<StitchCell> get completedVisibleCells sync* {
    for (final cell in _visibleCells) {
      if (completedCells.contains(cell.coordinate)) yield cell;
    }
  }

  /// Matching visible cells used by selection painting and focused tests.
  Iterable<StitchCell> get selectedVisibleCells sync* {
    final selectedSymbolId = selection.selectedSymbolId;
    if (selectedSymbolId == null) return;
    for (final cell in _visibleCells) {
      final isExcludedCompletedCell =
          !settings.includeCompletedCellsInSelection &&
          completedCells.contains(cell.coordinate);
      if (cell.symbolId == selectedSymbolId && !isExcludedCompletedCell) {
        yield cell;
      }
    }
  }

  /// Paints the visible document background, cells, glyphs, and grid rules.
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surfaceColor);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintDocumentBackground(canvas);
    if (renderLod == RenderLod.overview) _paintOverviewTiles(canvas);
    _paintCellFills(canvas);
    if (settings.showCompletedCellOverlay) {
      _paintCompletedCells(canvas);
    }
    _paintSelectedSymbol(canvas);
    _paintCompletionSelection(canvas);
    _paintGlyphs(canvas);
    if (settings.showGrid) _paintGrid(canvas);
    if (settings.showRegions) _paintRegions(canvas);
    canvas.restore();
  }

  /// Theme-derived color used to overlay exact completion-cell selections.
  Color get completionSelectionOverlayColor {
    final overlayOpacity = math.max(0.55, settings.completedCellOpacity);
    return completionSelectionColor.withValues(alpha: overlayOpacity);
  }

  /// Paints a high-contrast theme-color overlay on selected exact cells.
  void _paintCompletionSelection(Canvas canvas) {
    if (completionSelection.isEmpty || renderLod == RenderLod.overview) return;
    final overlayPaint = Paint()..color = completionSelectionOverlayColor;
    for (final coordinate in completionSelection) {
      if (!visibleBounds.contains(coordinate)) continue;
      final cell = document.grid.cellAt(coordinate);
      if (cell == null) continue;
      canvas.drawRect(_cellRect(cell), overlayPaint);
    }
  }

  /// Paints a translucent accent and outline across selected visible cells.
  void _paintSelectedSymbol(Canvas canvas) {
    if (!selection.hasSelection || renderLod == RenderLod.overview) return;
    final highlightColor = _parseColor(
      settings.selectionHighlightColor.colorHex,
    );
    final fillPaint = Paint()..color = highlightColor.withValues(alpha: 0.22);
    final outlinePaint = Paint()
      ..color = highlightColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(2, camera.cellSize * 0.16);
    for (final cell in selectedVisibleCells) {
      final cellRect = _cellRect(cell);
      canvas.drawRect(cellRect, fillPaint);
      canvas.drawRect(
        cellRect.deflate(outlinePaint.strokeWidth / 2),
        outlinePaint,
      );
    }
  }

  /// Paints the configured neutral overlay on completed visible cells.
  void _paintCompletedCells(Canvas canvas) {
    if (completedCells.isEmpty || renderLod == RenderLod.overview) return;
    for (final cell in completedVisibleCells) {
      canvas.drawRect(_cellRect(cell), _completedOverlayPaint);
    }
  }

  /// Paints the document rectangle without iterating through empty cells.
  void _paintDocumentBackground(Canvas canvas) {
    // One rectangle represents both populated and empty document cells.
    final dimensions = document.grid.dimensions;
    final documentRect = Rect.fromLTWH(
      camera.origin.dx,
      camera.origin.dy,
      dimensions.columns * camera.cellSize,
      dimensions.rows * camera.cellSize,
    );
    canvas.drawRect(documentRect, Paint()..color = surfaceColor);
  }

  /// Paints configured thread-color fills for visible populated cells.
  void _paintCellFills(Canvas canvas) {
    if (!settings.showCellColor || renderLod == RenderLod.overview) return;
    for (final cell in _visibleCells) {
      final fillPaint = symbolRenderCache.fillPaintFor(
        cell.symbolId,
        settings.cellColorOpacity,
      );
      if (fillPaint == null) continue;
      canvas.drawRect(_cellRect(cell), fillPaint);
    }
  }

  /// Paints glyphs after dynamic overlays so symbols remain legible.
  void _paintGlyphs(Canvas canvas) {
    if (!settings.showSymbols || renderLod != RenderLod.detail) return;
    for (final cell in _visibleCells) {
      final metadata = symbolRenderCache.metadataFor(cell.symbolId);
      if (metadata == null) continue;
      _paintGlyph(
        canvas,
        _cellRect(cell),
        metadata.symbol,
        _effectiveCellBackground(cell, metadata),
      );
    }
  }

  /// Paints density plus dynamic tile accents without enumerating tile cells.
  void _paintOverviewTiles(Canvas canvas) {
    final gridColor = _parseColor(settings.gridColor.colorHex);
    final selectedSymbolId = selection.selectedSymbolId;
    final selectedColor = _parseColor(
      settings.selectionHighlightColor.colorHex,
    );
    final selectedPaint = Paint()
      ..color = selectedColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.min(2, camera.cellSize * 2);
    final pendingPaint = Paint()
      ..color = completionSelectionColor.withValues(alpha: 0.4);
    final completedPaint = Paint()
      ..color = _completedOverlayColor.withValues(
        alpha: settings.completedCellOpacity * 0.45,
      );
    for (final summary in _visibleTileSummaries) {
      final tileRect = _tileRect(summary.coordinate);
      final tileRows = math.min(
        PatternGrid.tileSize,
        document.grid.dimensions.rows -
            summary.coordinate.row * PatternGrid.tileSize,
      );
      final tileColumns = math.min(
        PatternGrid.tileSize,
        document.grid.dimensions.columns -
            summary.coordinate.column * PatternGrid.tileSize,
      );
      final density = summary.populatedCellCount / (tileRows * tileColumns);
      final metadata = symbolRenderCache.metadataFor(summary.dominantSymbolId);
      final densityColor = settings.showCellColor && metadata != null
          ? metadata.threadColor.withValues(
              alpha: settings.cellColorOpacity * density,
            )
          : gridColor.withValues(alpha: 0.18 * density);
      canvas.drawRect(tileRect, Paint()..color = densityColor);
      if (settings.showCompletedCellOverlay &&
          completedTileCoordinates.contains(summary.coordinate)) {
        canvas.drawRect(tileRect, completedPaint);
      }
      if (selectedSymbolId != null &&
          summary.symbolCounts.containsKey(selectedSymbolId)) {
        canvas.drawRect(
          tileRect.deflate(selectedPaint.strokeWidth / 2),
          selectedPaint,
        );
      }
      if (_completionSelectionTiles.contains(summary.coordinate)) {
        canvas.drawRect(tileRect, pendingPaint);
      }
    }
  }

  /// Calculates the full screen-space rectangle occupied by one tile.
  Rect _tileRect(PatternTileCoordinate coordinate) {
    final startRow = coordinate.row * PatternGrid.tileSize;
    final startColumn = coordinate.column * PatternGrid.tileSize;
    final endRow = math.min(
      startRow + PatternGrid.tileSize,
      document.grid.dimensions.rows,
    );
    final endColumn = math.min(
      startColumn + PatternGrid.tileSize,
      document.grid.dimensions.columns,
    );
    return Rect.fromLTWH(
      camera.origin.dx + startColumn * camera.cellSize,
      camera.origin.dy + startRow * camera.cellSize,
      (endColumn - startColumn) * camera.cellSize,
      (endRow - startRow) * camera.cellSize,
    );
  }

  /// Resolves the composited background used for glyph contrast selection.
  Color _effectiveCellBackground(
    StitchCell cell,
    PatternSymbolRenderMetadata metadata,
  ) {
    var background = surfaceColor;
    if (settings.showCellColor) {
      background = Color.alphaBlend(
        metadata.threadColor.withValues(alpha: settings.cellColorOpacity),
        background,
      );
    }
    if (settings.showCompletedCellOverlay &&
        completedCells.contains(cell.coordinate)) {
      background = Color.alphaBlend(_completedOverlayColor, background);
    }
    return background;
  }

  /// Paints outlines for source regions intersecting the visible grid range.
  void _paintRegions(Canvas canvas) {
    final paint = Paint()
      ..color = regionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final region in document.regionsIntersecting(visibleBounds)) {
      final regionRect = Rect.fromLTWH(
        camera.origin.dx + region.origin.column * camera.cellSize,
        camera.origin.dy + region.origin.row * camera.cellSize,
        region.columns * camera.cellSize,
        region.rows * camera.cellSize,
      );
      canvas.drawRect(regionRect, paint);
    }
  }

  /// Paints only visible minor, ten-cell, and document-edge rules.
  void _paintGrid(Canvas canvas) {
    if (visibleBounds.isEmpty) return;
    // Visible endpoints bound both the horizontal and vertical rule segments.
    final dimensions = document.grid.dimensions;
    final left = camera.origin.dx + visibleBounds.startColumn * camera.cellSize;
    final right = camera.origin.dx + visibleBounds.endColumn * camera.cellSize;
    final top = camera.origin.dy + visibleBounds.startRow * camera.cellSize;
    final bottom = camera.origin.dy + visibleBounds.endRow * camera.cellSize;

    final overview = renderLod == RenderLod.overview;
    for (final row in _ruleCoordinates(
      visibleBounds.startRow,
      visibleBounds.endRow,
      overview,
      dimensions.rows,
    )) {
      final y = camera.origin.dy + row * camera.cellSize;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        _rulePaint(row, dimensions.rows),
      );
    }
    for (final column in _ruleCoordinates(
      visibleBounds.startColumn,
      visibleBounds.endColumn,
      overview,
      dimensions.columns,
    )) {
      final x = camera.origin.dx + column * camera.cellSize;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        _rulePaint(column, dimensions.columns),
      );
    }
  }

  /// Yields every visible rule or only ten-cell rules in overview mode.
  Iterable<int> _ruleCoordinates(
    int start,
    int end,
    bool majorOnly,
    int documentExtent,
  ) sync* {
    if (!majorOnly) {
      for (var coordinate = start; coordinate <= end; coordinate++) {
        yield coordinate;
      }
      return;
    }
    final firstMajor = ((start + 9) ~/ 10) * 10;
    for (var coordinate = firstMajor; coordinate <= end; coordinate += 10) {
      yield coordinate;
    }
    if (documentExtent >= start &&
        documentExtent <= end &&
        documentExtent % 10 != 0) {
      yield documentExtent;
    }
  }

  /// Selects a capped stroke width for a rule at [coordinate].
  Paint _rulePaint(int coordinate, int documentExtent) {
    // Outside and ten-cell rules take precedence over ordinary minor rules.
    final isOutside = coordinate == 0 || coordinate == documentExtent;
    final isMajor = coordinate % 10 == 0;
    final strokeWidth = isOutside
        ? math.min(2.25, camera.cellSize * 0.38)
        : isMajor
        ? math.min(2.0, camera.cellSize * 0.3)
        : math.min(1.0, camera.cellSize * 0.18);
    return Paint()
      ..color = _parseColor(settings.gridColor.colorHex)
      ..strokeWidth = strokeWidth;
  }

  /// Calculates one cell's screen-space rectangle.
  Rect _cellRect(StitchCell cell) => Rect.fromLTWH(
    camera.origin.dx + cell.coordinate.column * camera.cellSize,
    camera.origin.dy + cell.coordinate.row * camera.cellSize,
    camera.cellSize,
    camera.cellSize,
  );

  /// Paints a centered symbol glyph with contrast against its thread color.
  void _paintGlyph(
    Canvas canvas,
    Rect rect,
    SymbolDefinition symbol,
    Color backgroundColor,
  ) {
    // Choose a non-color-dependent foreground contrast for each glyph.
    final foreground = backgroundColor.computeLuminance() > 0.45
        ? Colors.black87
        : Colors.white;
    // Text metrics are cached because many cells share the same symbol style.
    final textPainter = glyphLayoutCache.layoutFor(
      glyph: symbol.displayGlyph,
      foreground: foreground,
      fontSize: (camera.cellSize * 0.58).clamp(12, 32),
    );
    textPainter.paint(
      canvas,
      rect.center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  /// Converts a validated domain `#RRGGBB` value into an opaque Flutter color.
  Color _parseColor(String value) =>
      Color(int.parse('FF${value.substring(1)}', radix: 16));

  /// Repaints when any visible rendering input changes.
  @override
  bool shouldRepaint(ViewportPatternPainter oldDelegate) =>
      oldDelegate.document != document ||
      oldDelegate.camera != camera ||
      oldDelegate.visibleBounds != visibleBounds ||
      oldDelegate.settings != settings ||
      oldDelegate.selection != selection ||
      !setEquals(oldDelegate.completedCells, completedCells) ||
      !setEquals(oldDelegate.completionSelection, completionSelection) ||
      oldDelegate.renderLod != renderLod ||
      !setEquals(
        oldDelegate.completedTileCoordinates,
        completedTileCoordinates,
      ) ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.regionColor != regionColor ||
      oldDelegate.completionSelectionColor != completionSelectionColor;
}

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/progress_models.dart';
import 'pattern_camera.dart';
import 'pattern_render_selection.dart';

/// Paints only the pattern cells and rules intersecting visible grid bounds.
class ViewportPatternPainter extends CustomPainter {
  /// Creates a painter from immutable document, camera, bounds, and theme data.
  ViewportPatternPainter({
    required this.document,
    required this.camera,
    required this.visibleBounds,
    required this.settings,
    required this.selection,
    required this.surfaceColor,
    required this.regionColor,
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

  /// Background color used for the viewport and empty cells.
  final Color surfaceColor;

  /// Theme color used for enabled source-region outlines.
  final Color regionColor;

  /// Matching visible cells used by selection painting and focused tests.
  Iterable<StitchCell> get selectedVisibleCells sync* {
    final selectedSymbolId = selection.selectedSymbolId;
    if (selectedSymbolId == null) return;
    for (final cell in document.grid.cellsIntersecting(visibleBounds)) {
      if (cell.symbolId == selectedSymbolId) yield cell;
    }
  }

  /// Paints the visible document background, cells, glyphs, and grid rules.
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surfaceColor);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintDocumentBackground(canvas);
    _paintCells(canvas);
    _paintSelectedSymbol(canvas);
    if (settings.showGrid) _paintGrid(canvas);
    if (settings.showRegions) _paintRegions(canvas);
    canvas.restore();
  }

  /// Paints a translucent fill highlight across selected visible cells.
  void _paintSelectedSymbol(Canvas canvas) {
    final highlightColor = _parseColor(
      settings.selectionHighlightColor.colorHex,
    );
    final highlightPaint = Paint()
      ..color = highlightColor.withValues(alpha: 0.38);
    for (final cell in selectedVisibleCells) {
      canvas.drawRect(_cellRect(cell), highlightPaint);
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

  /// Paints populated cells returned by the grid's spatial range query.
  void _paintCells(Canvas canvas) {
    if (!settings.showCellColor && !settings.showSymbols) return;
    for (final cell in document.grid.cellsIntersecting(visibleBounds)) {
      // Resolve symbol metadata only for cells returned by the spatial query.
      final symbol = document.symbolById(cell.symbolId);
      if (symbol == null) continue;
      // Cell and color values are reused by both fill and glyph layers.
      final cellRect = _cellRect(cell);
      final threadColor = _parseColor(symbol.thread.color);
      final effectiveBackground = settings.showCellColor
          ? Color.alphaBlend(
              threadColor.withValues(alpha: settings.cellColorOpacity),
              surfaceColor,
            )
          : surfaceColor;
      if (settings.showCellColor) {
        canvas.drawRect(
          cellRect,
          Paint()
            ..color = threadColor.withValues(alpha: settings.cellColorOpacity),
        );
      }
      if (settings.showSymbols && camera.cellSize >= 12) {
        _paintGlyph(canvas, cellRect, symbol, effectiveBackground);
      }
    }
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

    for (var row = visibleBounds.startRow; row <= visibleBounds.endRow; row++) {
      final y = camera.origin.dy + row * camera.cellSize;
      canvas.drawLine(
        Offset(left, y),
        Offset(right, y),
        _rulePaint(row, dimensions.rows),
      );
    }
    for (
      var column = visibleBounds.startColumn;
      column <= visibleBounds.endColumn;
      column++
    ) {
      final x = camera.origin.dx + column * camera.cellSize;
      canvas.drawLine(
        Offset(x, top),
        Offset(x, bottom),
        _rulePaint(column, dimensions.columns),
      );
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
    // Text metrics provide exact centering within the screen-space cell.
    final textPainter = TextPainter(
      text: TextSpan(
        text: symbol.displayGlyph,
        style: TextStyle(
          color: foreground,
          fontSize: (camera.cellSize * 0.58).clamp(12, 32),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
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
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.regionColor != regionColor;
}

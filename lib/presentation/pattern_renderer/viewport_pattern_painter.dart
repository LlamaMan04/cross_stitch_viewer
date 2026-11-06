import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import 'pattern_camera.dart';

/// Paints only the pattern cells and rules intersecting visible grid bounds.
class ViewportPatternPainter extends CustomPainter {
  /// Creates a painter from immutable document, camera, bounds, and theme data.
  ViewportPatternPainter({
    required this.document,
    required this.camera,
    required this.visibleBounds,
    required this.surfaceColor,
    required this.gridColor,
  });

  /// Normalized source document rendered by this painter.
  final PatternDocument document;

  /// Camera that maps grid coordinates directly into screen coordinates.
  final PatternCamera camera;

  /// Half-open grid range that this paint pass may inspect.
  final GridBounds visibleBounds;

  /// Background color used for the viewport and empty cells.
  final Color surfaceColor;

  /// Color used for all grid-rule classes.
  final Color gridColor;

  /// Paints the visible document background, cells, glyphs, and grid rules.
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = surfaceColor);
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    _paintDocumentBackground(canvas);
    _paintCells(canvas);
    _paintGrid(canvas);
    canvas.restore();
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
    for (final cell in document.grid.cellsIntersecting(visibleBounds)) {
      // Resolve symbol metadata only for cells returned by the spatial query.
      final symbol = document.symbolById(cell.symbolId);
      if (symbol == null) continue;
      // Cell and color values are reused by both fill and glyph layers.
      final cellRect = _cellRect(cell);
      final threadColor = _parseColor(symbol.thread.color);
      canvas.drawRect(
        cellRect,
        Paint()..color = threadColor.withValues(alpha: 0.22),
      );
      if (camera.cellSize >= 12) {
        _paintGlyph(canvas, cellRect, symbol, threadColor);
      }
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
      ..color = gridColor
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
    Color threadColor,
  ) {
    // Choose a non-color-dependent foreground contrast for each glyph.
    final foreground = threadColor.computeLuminance() > 0.45
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
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.gridColor != gridColor;
}

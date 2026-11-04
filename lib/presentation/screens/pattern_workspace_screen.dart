import 'package:flutter/material.dart';

import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/repositories.dart';

/// Loads and displays a read-only rendering of a persisted pattern document.
class PatternWorkspaceScreen extends StatelessWidget {
  /// Creates a workspace for the selected document.
  const PatternWorkspaceScreen({
    required this.documentId,
    required this.patternDocuments,
    super.key,
  });

  /// Stable identity of the document opened from the library.
  final String documentId;

  /// Repository used to load the selected normalized document.
  final PatternDocumentRepository patternDocuments;

  /// Builds the loading, missing-document, and pattern-rendering states.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pattern Workspace')),
      body: FutureBuilder<PatternDocument?>(
        future: patternDocuments.getById(documentId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final document = snapshot.data;
          if (document == null) {
            return const Center(
              child: Text('This pattern is no longer available.'),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        document.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(
                      '${document.grid.dimensions.rows} × '
                      '${document.grid.dimensions.columns}',
                    ),
                  ],
                ),
              ),
              Expanded(child: PatternRenderView(document: document)),
            ],
          );
        },
      ),
    );
  }
}

/// Fits a normalized pattern grid into a pannable and zoomable viewport.
class PatternRenderView extends StatelessWidget {
  /// Creates a read-only custom-painted pattern grid.
  const PatternRenderView({required this.document, super.key});

  /// Pattern data rendered by this view.
  final PatternDocument document;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceContainerLowest,
          border: Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.circular(12),
        ),
        child: InteractiveViewer(
          key: const ValueKey('pattern-interactive-viewer'),
          minScale: 1,
          maxScale: 8,
          panEnabled: true,
          scaleEnabled: true,
          trackpadScrollCausesScale: false,
          child: CustomPaint(
            key: const ValueKey('pattern-grid-canvas'),
            painter: PatternGridPainter(
              document: document,
              surfaceColor: colors.surfaceContainerLowest,
              gridColor: colors.outlineVariant,
              labelColor: colors.onSurfaceVariant,
              regionColor: colors.primary,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// Paints a fitted sparse pattern grid, its stitch symbols, and region bounds.
class PatternGridPainter extends CustomPainter {
  /// Creates a painter with document data and colors supplied by the active theme.
  PatternGridPainter({
    required this.document,
    required this.surfaceColor,
    required this.gridColor,
    required this.labelColor,
    required this.regionColor,
  });

  /// Pattern grid, symbols, and source regions to render.
  final PatternDocument document;

  /// Background color used for empty grid cells.
  final Color surfaceColor;

  /// Color used for cell boundaries.
  final Color gridColor;

  /// Color used for row and column labels.
  final Color labelColor;

  /// Color used for source region outlines.
  final Color regionColor;

  @override
  void paint(Canvas canvas, Size size) {
    final dimensions = document.grid.dimensions;
    const labelExtent = 28.0;
    const minimumExtent = 1.0;
    final gridWidth = size.width - labelExtent;
    final gridHeight = size.height - labelExtent;
    if (gridWidth <= minimumExtent || gridHeight <= minimumExtent) return;

    final cellSize = (gridWidth / dimensions.columns).clamp(
      0.0,
      gridHeight / dimensions.rows,
    );
    if (cellSize <= minimumExtent) return;
    final renderedWidth = cellSize * dimensions.columns;
    final renderedHeight = cellSize * dimensions.rows;
    final origin = Offset(
      labelExtent + (gridWidth - renderedWidth) / 2,
      labelExtent + (gridHeight - renderedHeight) / 2,
    );
    final gridRect = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      renderedWidth,
      renderedHeight,
    );

    canvas.drawRect(gridRect, Paint()..color = surfaceColor);
    _paintCells(canvas, origin, cellSize);
    _paintGrid(canvas, gridRect, cellSize);
    _paintRegions(canvas, origin, cellSize);
    _paintLabels(canvas, origin, cellSize);
  }

  /// Paints sparse populated cells with their thread color and display glyph.
  void _paintCells(Canvas canvas, Offset origin, double cellSize) {
    for (final cell in document.grid.cells) {
      final symbol = document.symbolById(cell.symbolId);
      if (symbol == null) continue;
      final rect = _cellRect(cell, origin, cellSize);
      final color = _parseColor(symbol.thread.color);
      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.22));
      _paintGlyph(canvas, rect, symbol, color, cellSize);
    }
  }

  /// Paints all row and column rules in one pass.
  void _paintGrid(Canvas canvas, Rect gridRect, double cellSize) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var row = 0; row <= document.grid.dimensions.rows; row++) {
      final y = gridRect.top + row * cellSize;
      canvas.drawLine(
        Offset(gridRect.left, y),
        Offset(gridRect.right, y),
        paint,
      );
    }
    for (var column = 0; column <= document.grid.dimensions.columns; column++) {
      final x = gridRect.left + column * cellSize;
      canvas.drawLine(
        Offset(x, gridRect.top),
        Offset(x, gridRect.bottom),
        paint,
      );
    }
  }

  /// Paints source-region extents over the cell grid.
  void _paintRegions(Canvas canvas, Offset origin, double cellSize) {
    final paint = Paint()
      ..color = regionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final region in document.regions) {
      canvas.drawRect(
        Rect.fromLTWH(
          origin.dx + region.origin.column * cellSize,
          origin.dy + region.origin.row * cellSize,
          region.columns * cellSize,
          region.rows * cellSize,
        ),
        paint,
      );
    }
  }

  /// Paints one-based row and column coordinates when cells are large enough.
  void _paintLabels(Canvas canvas, Offset origin, double cellSize) {
    if (cellSize < 16) return;
    for (var column = 0; column < document.grid.dimensions.columns; column++) {
      _paintCenteredText(
        canvas,
        '${column + 1}',
        Offset(origin.dx + (column + 0.5) * cellSize, origin.dy / 2),
        fontSize: 11,
        color: labelColor,
      );
    }
    for (var row = 0; row < document.grid.dimensions.rows; row++) {
      _paintCenteredText(
        canvas,
        '${row + 1}',
        Offset(origin.dx / 2, origin.dy + (row + 0.5) * cellSize),
        fontSize: 11,
        color: labelColor,
      );
    }
  }

  /// Paints a centered grid symbol with contrast chosen for its thread color.
  void _paintGlyph(
    Canvas canvas,
    Rect rect,
    SymbolDefinition symbol,
    Color color,
    double cellSize,
  ) {
    if (cellSize < 12) return;
    final luminance = color.computeLuminance();
    _paintCenteredText(
      canvas,
      symbol.displayGlyph,
      rect.center,
      fontSize: (cellSize * 0.58).clamp(12.0, 32.0),
      color: luminance > 0.45 ? Colors.black87 : Colors.white,
      fontWeight: FontWeight.w600,
    );
  }

  /// Paints text centered on [center] using the current canvas.
  void _paintCenteredText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// Calculates the rendered bounds of one populated sparse cell.
  Rect _cellRect(StitchCell cell, Offset origin, double cellSize) =>
      Rect.fromLTWH(
        origin.dx + cell.coordinate.column * cellSize,
        origin.dy + cell.coordinate.row * cellSize,
        cellSize,
        cellSize,
      );

  /// Converts a validated domain `#RRGGBB` value into a Flutter color.
  Color _parseColor(String value) =>
      Color(int.parse('FF${value.substring(1)}', radix: 16));

  @override
  bool shouldRepaint(PatternGridPainter oldDelegate) =>
      oldDelegate.document != document ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.regionColor != regionColor;
}

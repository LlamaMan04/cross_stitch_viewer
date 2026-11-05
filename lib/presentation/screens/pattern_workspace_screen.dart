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
        // Load only the selected document so the workspace does not duplicate
        // the library's summary query or keep a second copy of every pattern.
        future: patternDocuments.getById(documentId),
        builder: (context, snapshot) {
          // Keep loading visible while the repository completes its read.
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final document = snapshot.data;
          // A document can disappear after its library row was opened.
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
                    // Let long titles use the available space beside the
                    // compact dimensions summary.
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

  /// Space retained around the grid while it is fitted into the viewport.
  static const _patternInset = 24.0;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    // The border and padding separate the canvas from the workspace while
    // allowing the grid to expand with its parent.
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
          maxScale: 40,
          panEnabled: true,
          scaleEnabled: true,
          trackpadScrollCausesScale: false,
          // Keep room around the fitted grid while the user pans it.
          boundaryMargin: const EdgeInsets.all(_patternInset),
          child: Padding(
            padding: const EdgeInsets.all(_patternInset),
            child: CustomPaint(
              key: const ValueKey('pattern-grid-canvas'),
              painter: PatternGridPainter(
                document: document,
                surfaceColor: colors.surfaceContainerLowest,
                gridColor: colors.outlineVariant,
                labelColor: colors.onSurfaceVariant,
                regionColor: colors.primary,
              ),
              // Fill the available viewport; the painter calculates a square
              // cell size that fits inside this area.
              child: const SizedBox.expand(),
            ),
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
    // Reserve a label row and column around the grid. All later geometry uses
    // the same origin so labels stay aligned with their cells.
    const labelExtent = 28.0;
    const minimumExtent = 1.0;
    final gridWidth = size.width - labelExtent;
    final gridHeight = size.height - labelExtent;
    // Layout can briefly provide a very small size; avoid invalid geometry.
    if (gridWidth <= minimumExtent || gridHeight <= minimumExtent) return;

    // Keep cells square by fitting the grid to the tighter available axis.
    final cellSize = (gridWidth / dimensions.columns).clamp(
      0.0,
      gridHeight / dimensions.rows,
    );
    if (cellSize <= minimumExtent) return;
    // Center the fitted grid in the remaining space after reserving labels.
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

    // Paint from back to front so each layer remains visible and predictable.
    canvas.drawRect(gridRect, Paint()..color = surfaceColor);
    // Draw sparse stitch data before the rules so cell boundaries stay clear.
    _paintCells(canvas, origin, cellSize);
    // Empty cells are meaningful, so draw the complete grid separately from
    // the sparse cell data stored in the domain model.
    _paintGrid(canvas, gridRect, cellSize);
    // Region outlines show source boundaries without hiding stitch content.
    _paintRegions(canvas, origin, cellSize);
    // Coordinates are drawn last so they stay legible above the other layers.
    _paintLabels(canvas, origin, cellSize);
  }

  /// Paints sparse populated cells with their thread color and display glyph.
  void _paintCells(Canvas canvas, Offset origin, double cellSize) {
    for (final cell in document.grid.cells) {
      final symbol = document.symbolById(cell.symbolId);
      // Skip incomplete source references without preventing other cells from
      // being rendered.
      if (symbol == null) continue;
      final rect = _cellRect(cell, origin, cellSize);
      final color = _parseColor(symbol.thread.color);
      // A translucent fill preserves the grid while showing the thread color.
      canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.22));
      _paintGlyph(canvas, rect, symbol, color, cellSize);
    }
  }

  /// Paints all row and column rules in one pass.
  void _paintGrid(Canvas canvas, Rect gridRect, double cellSize) {
    // Reuse one paint object for all rules in this frequently called path.
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var row = 0; row <= document.grid.dimensions.rows; row++) {
      // Include both endpoints to close the outer border as well as internals.
      final y = gridRect.top + row * cellSize;
      canvas.drawLine(
        Offset(gridRect.left, y),
        Offset(gridRect.right, y),
        paint,
      );
    }
    for (var column = 0; column <= document.grid.dimensions.columns; column++) {
      // The inclusive range closes the left and right borders.
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
    // Use outlines only so provenance boundaries do not obscure grid content.
    final paint = Paint()
      ..color = regionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final region in document.regions) {
      // Regions use grid-cell coordinates, so convert origin and extent with
      // the same cell-size transform used by the grid.
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
    // At smaller scales labels overlap; the threshold keeps them readable.
    if (cellSize < 16) return;
    for (var column = 0; column < document.grid.dimensions.columns; column++) {
      // Column numbers are centered in the reserved top label row.
      _paintCenteredText(
        canvas,
        '${column + 1}',
        Offset(origin.dx + (column + 0.5) * cellSize, origin.dy / 2),
        fontSize: 11,
        color: labelColor,
      );
    }
    for (var row = 0; row < document.grid.dimensions.rows; row++) {
      // Row numbers are centered in the reserved left label column.
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
    // The fill remains useful at small scales, but glyphs would collide.
    if (cellSize < 12) return;
    final luminance = color.computeLuminance();
    // Choose a contrasting foreground for dark and light thread colors.
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
    // TextPainter supplies font metrics so labels can be centered by their
    // measured size rather than approximated from a fixed character width.
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
    // Move from the text painter's top-left origin to the requested center.
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  /// Calculates the rendered bounds of one populated sparse cell.
  Rect _cellRect(StitchCell cell, Offset origin, double cellSize) =>
      // Convert zero-based domain coordinates into canvas pixels.
      Rect.fromLTWH(
        origin.dx + cell.coordinate.column * cellSize,
        origin.dy + cell.coordinate.row * cellSize,
        cellSize,
        cellSize,
      );

  /// Converts a validated domain `#RRGGBB` value into a Flutter color.
  Color _parseColor(String value) =>
      // Prefix FF because the domain value contains RGB, not an alpha byte.
      Color(int.parse('FF${value.substring(1)}', radix: 16));

  @override
  bool shouldRepaint(PatternGridPainter oldDelegate) =>
      // Repaint when document data or any theme color used by the painter
      // changes; otherwise Flutter can safely reuse the existing picture.
      oldDelegate.document != document ||
      oldDelegate.surfaceColor != surfaceColor ||
      oldDelegate.gridColor != gridColor ||
      oldDelegate.labelColor != labelColor ||
      oldDelegate.regionColor != regionColor;
}

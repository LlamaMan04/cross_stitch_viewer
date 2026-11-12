import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/pattern_grid.dart';
import '../../domain/value_objects.dart';
import 'pattern_camera.dart';
import 'pattern_viewport_controller.dart';
import 'render_lod.dart';

/// Paints fixed top and left rulers aligned to the drawable pattern grid.
class ViewportRulerPainter extends CustomPainter {
  /// Creates a ruler painter driven by the shared viewport camera controller.
  ViewportRulerPainter({
    required this.cameraController,
    required this.dimensions,
    required this.drawableSize,
    required this.showTopRuler,
    required this.showLeftRuler,
    required this.rulerColor,
    required this.tickColor,
    required this.labelColor,
  }) : super(repaint: cameraController);

  /// Fixed height of the top ruler whenever it is enabled.
  static const double topExtent = 22;

  /// Fixed width of the left ruler whenever it is enabled.
  static const double leftExtent = 32;

  /// Consistent off-white surface behind ruler ticks and labels.
  static const Color backgroundColor = Color(0xFFFFFBF5);

  /// Camera notifier shared with the drawable viewport.
  final PatternViewportController cameraController;

  /// Immutable pattern dimensions used to clip visible ruler coordinates.
  final PatternDimensions dimensions;

  /// Size of the grid-only drawable viewport below and beside rulers.
  final Size drawableSize;

  /// Whether the horizontal column ruler is displayed.
  final bool showTopRuler;

  /// Whether the vertical row ruler is displayed.
  final bool showLeftRuler;

  /// Background applied to every enabled ruler strip.
  final Color rulerColor;

  /// Grid-matched color used by ruler ticks and dividers.
  final Color tickColor;

  /// Foreground used by zero-indexed ruler labels.
  final Color labelColor;

  /// Current left offset of the drawable pattern grid.
  double get _gridLeft => showLeftRuler ? leftExtent : 0;

  /// Current top offset of the drawable pattern grid.
  double get _gridTop => showTopRuler ? topExtent : 0;

  /// Paints ruler backgrounds, grid-line ticks, and decluttered labels.
  @override
  void paint(Canvas canvas, Size size) {
    if (!showTopRuler && !showLeftRuler) return;
    final camera = cameraController.camera;
    final bounds = camera.visibleBounds(
      viewportSize: drawableSize,
      dimensions: dimensions,
    );
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1;
    if (showTopRuler) {
      canvas.drawRect(
        Rect.fromLTWH(_gridLeft, 0, drawableSize.width, topExtent),
        Paint()..color = rulerColor,
      );
      canvas.drawLine(
        Offset(_gridLeft, topExtent),
        Offset(_gridLeft + drawableSize.width, topExtent),
        tickPaint,
      );
      _paintTopRuler(canvas, camera, bounds, tickPaint);
    }
    if (showLeftRuler) {
      canvas.drawRect(
        Rect.fromLTWH(0, _gridTop, leftExtent, drawableSize.height),
        Paint()..color = rulerColor,
      );
      canvas.drawLine(
        Offset(leftExtent, _gridTop),
        Offset(leftExtent, _gridTop + drawableSize.height),
        tickPaint,
      );
      _paintLeftRuler(canvas, camera, bounds, tickPaint);
    }
    if (showTopRuler && showLeftRuler) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, leftExtent, topExtent),
        Paint()..color = rulerColor,
      );
    }
  }

  /// Paints ticks and zero-indexed labels for visible column grid lines.
  void _paintTopRuler(
    Canvas canvas,
    PatternCamera camera,
    GridBounds bounds,
    Paint tickPaint,
  ) {
    final labelInterval = _labelInterval(camera);
    for (final column in _tickCoordinates(
      start: bounds.startColumn,
      end: bounds.endColumn,
      documentExtent: dimensions.columns,
    )) {
      final x = _gridLeft + camera.origin.dx + column * camera.cellSize;
      final isMajor = column % 10 == 0;
      tickPaint.strokeWidth = isMajor ? 1.5 : 1;
      canvas.drawLine(
        Offset(x, topExtent),
        Offset(x, topExtent - (isMajor ? 12 : 8)),
        tickPaint,
      );
      if (column % labelInterval == 0) {
        _paintLabel(
          canvas,
          '$column',
          Offset(x + 2, 2),
          maxWidth: math.max(0, _gridLeft + drawableSize.width - x - 2),
        );
      }
    }
  }

  /// Paints ticks and zero-indexed labels for visible row grid lines.
  void _paintLeftRuler(
    Canvas canvas,
    PatternCamera camera,
    GridBounds bounds,
    Paint tickPaint,
  ) {
    final labelInterval = _labelInterval(camera);
    for (final row in _tickCoordinates(
      start: bounds.startRow,
      end: bounds.endRow,
      documentExtent: dimensions.rows,
    )) {
      final y = _gridTop + camera.origin.dy + row * camera.cellSize;
      final isMajor = row % 10 == 0;
      tickPaint.strokeWidth = isMajor ? 1.5 : 1;
      canvas.drawLine(
        Offset(leftExtent, y),
        Offset(leftExtent - (isMajor ? 12 : 8), y),
        tickPaint,
      );
      if (row % labelInterval == 0) {
        _paintLabel(canvas, '$row', Offset(2, y + 1), maxWidth: leftExtent - 4);
      }
    }
  }

  /// Returns the label interval needed to prevent overview text collisions.
  int _labelInterval(PatternCamera camera) {
    if (cameraController.renderLod != RenderLod.overview) return 10;
    var interval = 10;
    while (interval * camera.cellSize < 40) {
      interval *= 10;
    }
    return interval;
  }

  /// Yields every tick outside overview and only major or edge ticks in it.
  Iterable<int> _tickCoordinates({
    required int start,
    required int end,
    required int documentExtent,
  }) sync* {
    final overview = cameraController.renderLod == RenderLod.overview;
    for (var coordinate = start; coordinate <= end; coordinate++) {
      final isMajor = coordinate % 10 == 0;
      final isDocumentEdge = coordinate == documentExtent;
      if (!overview || isMajor || isDocumentEdge) yield coordinate;
    }
  }

  /// Paints a clipped ruler label at a grid-line coordinate.
  void _paintLabel(
    Canvas canvas,
    String text,
    Offset offset, {
    required double maxWidth,
  }) {
    if (maxWidth <= 0) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: labelColor, fontSize: 10, height: 1),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    painter.paint(canvas, offset);
  }

  /// Repaints only when layout, enabled strips, or palette inputs change.
  @override
  bool shouldRepaint(covariant ViewportRulerPainter oldDelegate) =>
      dimensions != oldDelegate.dimensions ||
      drawableSize != oldDelegate.drawableSize ||
      showTopRuler != oldDelegate.showTopRuler ||
      showLeftRuler != oldDelegate.showLeftRuler ||
      rulerColor != oldDelegate.rulerColor ||
      tickColor != oldDelegate.tickColor ||
      labelColor != oldDelegate.labelColor;
}

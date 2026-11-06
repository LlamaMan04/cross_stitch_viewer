import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../domain/pattern_grid.dart';
import '../../domain/value_objects.dart';

/// Immutable grid-space camera used by the viewport and painter.
class PatternCamera {
  /// Creates a camera with a logical-pixel cell size and screen-space origin.
  const PatternCamera({required this.cellSize, required this.origin});

  /// Smallest supported on-screen cell extent.
  static const double minimumCellSize = 1;

  /// Largest supported on-screen cell extent.
  static const double maximumCellSize = 80;

  /// Logical pixels occupied by one grid cell.
  final double cellSize;

  /// Screen-space location of grid coordinate `(0, 0)`.
  final Offset origin;

  /// Creates a centered camera that fits [dimensions] inside [viewportSize].
  factory PatternCamera.fit({
    required PatternDimensions dimensions,
    required Size viewportSize,
    double padding = 24,
  }) {
    // Retain the requested inset while tolerating transient tiny layouts.
    final availableWidth = math.max(1, viewportSize.width - padding * 2);
    final availableHeight = math.max(1, viewportSize.height - padding * 2);
    // Fit against the tighter axis and keep zoom within interaction limits.
    final fittedCellSize = math
        .min(
          availableWidth / dimensions.columns,
          availableHeight / dimensions.rows,
        )
        .clamp(minimumCellSize, maximumCellSize);
    // Rendered extents center the fitted document in each available axis.
    final renderedWidth = dimensions.columns * fittedCellSize;
    final renderedHeight = dimensions.rows * fittedCellSize;
    return PatternCamera(
      cellSize: fittedCellSize,
      origin: Offset(
        (viewportSize.width - renderedWidth) / 2,
        (viewportSize.height - renderedHeight) / 2,
      ),
    ).clampTo(dimensions: dimensions, viewportSize: viewportSize);
  }

  /// Converts a grid-line coordinate into a screen-space point.
  Offset gridToScreen({required double row, required double column}) =>
      Offset(origin.dx + column * cellSize, origin.dy + row * cellSize);

  /// Converts a screen-space point into fractional row and column values.
  Offset screenToGrid(Offset point) => Offset(
    (point.dx - origin.dx) / cellSize,
    (point.dy - origin.dy) / cellSize,
  );

  /// Calculates clamped half-open bounds with one cell of overscan.
  GridBounds visibleBounds({
    required Size viewportSize,
    required PatternDimensions dimensions,
    int overscan = 1,
  }) {
    // Convert each viewport edge to a grid line and include overscan.
    final firstColumn = ((-origin.dx / cellSize).floor() - overscan).clamp(
      0,
      dimensions.columns,
    );
    final endColumn =
        (((viewportSize.width - origin.dx) / cellSize).ceil() + overscan).clamp(
          0,
          dimensions.columns,
        );
    final firstRow = ((-origin.dy / cellSize).floor() - overscan).clamp(
      0,
      dimensions.rows,
    );
    final endRow =
        (((viewportSize.height - origin.dy) / cellSize).ceil() + overscan)
            .clamp(0, dimensions.rows);
    return GridBounds(
      startRow: math.min(firstRow, endRow),
      endRow: math.max(firstRow, endRow),
      startColumn: math.min(firstColumn, endColumn),
      endColumn: math.max(firstColumn, endColumn),
    );
  }

  /// Returns a camera translated by [delta] and clamped to the document.
  PatternCamera panBy({
    required Offset delta,
    required PatternDimensions dimensions,
    required Size viewportSize,
  }) => PatternCamera(
    cellSize: cellSize,
    origin: origin + delta,
  ).clampTo(dimensions: dimensions, viewportSize: viewportSize);

  /// Zooms around [focalPoint], preserving its underlying grid coordinate.
  PatternCamera zoomAround({
    required Offset focalPoint,
    required double scale,
    required PatternDimensions dimensions,
    required Size viewportSize,
  }) {
    // Capture the fractional grid coordinate before changing scale.
    final gridPoint = screenToGrid(focalPoint);
    final nextCellSize = (cellSize * scale).clamp(
      minimumCellSize,
      maximumCellSize,
    );
    // Reposition the origin so the captured grid point remains under focus.
    final nextOrigin = Offset(
      focalPoint.dx - gridPoint.dx * nextCellSize,
      focalPoint.dy - gridPoint.dy * nextCellSize,
    );
    return PatternCamera(
      cellSize: nextCellSize,
      origin: nextOrigin,
    ).clampTo(dimensions: dimensions, viewportSize: viewportSize);
  }

  /// Restricts panning while retaining a small reachable margin at each edge.
  PatternCamera clampTo({
    required PatternDimensions dimensions,
    required Size viewportSize,
    double edgeMargin = 24,
  }) {
    // Document extents determine the opposite legal origin for each axis.
    final documentWidth = dimensions.columns * cellSize;
    final documentHeight = dimensions.rows * cellSize;
    final alternateX = viewportSize.width - documentWidth - edgeMargin;
    final alternateY = viewportSize.height - documentHeight - edgeMargin;
    // Sorting both candidates also supports documents smaller than the view.
    final minimumX = math.min(edgeMargin, alternateX);
    final maximumX = math.max(edgeMargin, alternateX);
    final minimumY = math.min(edgeMargin, alternateY);
    final maximumY = math.max(edgeMargin, alternateY);
    return PatternCamera(
      cellSize: cellSize,
      origin: Offset(
        origin.dx.clamp(minimumX, maximumX),
        origin.dy.clamp(minimumY, maximumY),
      ),
    );
  }

  /// Compares camera values by cell size and origin.
  @override
  bool operator ==(Object other) =>
      other is PatternCamera &&
      cellSize == other.cellSize &&
      origin == other.origin;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode => Object.hash(cellSize, origin);
}

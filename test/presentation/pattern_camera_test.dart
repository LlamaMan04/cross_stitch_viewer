import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_camera.dart';

/// Verifies camera transforms, visible bounds, zoom, and pan constraints.
void main() {
  test('screen and grid transforms round-trip', () {
    const camera = PatternCamera(cellSize: 20, origin: Offset(15, -30));

    final screenPoint = camera.gridToScreen(row: 4.5, column: 7.25);
    final gridPoint = camera.screenToGrid(screenPoint);

    expect(gridPoint.dx, closeTo(7.25, 0.000001));
    expect(gridPoint.dy, closeTo(4.5, 0.000001));
  });

  test('visible bounds clamp and include one-cell overscan', () {
    const camera = PatternCamera(cellSize: 10, origin: Offset(-25, -15));

    final bounds = camera.visibleBounds(
      viewportSize: const Size(100, 80),
      dimensions: const PatternDimensions(20, 30),
    );

    expect(
      bounds,
      const GridBounds(startRow: 0, endRow: 11, startColumn: 1, endColumn: 14),
    );
  });

  test('focal zoom preserves the grid point beneath the cursor', () {
    const dimensions = PatternDimensions(100, 100);
    const viewportSize = Size(500, 500);
    const focalPoint = Offset(250, 250);
    const camera = PatternCamera(cellSize: 10, origin: Offset(-100, -100));
    final before = camera.screenToGrid(focalPoint);

    final zoomed = camera.zoomAround(
      focalPoint: focalPoint,
      scale: 2,
      dimensions: dimensions,
      viewportSize: viewportSize,
    );
    final after = zoomed.screenToGrid(focalPoint);

    expect(after.dx, closeTo(before.dx, 0.000001));
    expect(after.dy, closeTo(before.dy, 0.000001));
    expect(zoomed.cellSize, 20);
  });

  test('zooming out stops at the fitted viewport scale', () {
    const dimensions = PatternDimensions(100, 200);
    const viewportSize = Size(1000, 500);
    const camera = PatternCamera(cellSize: 10, origin: Offset.zero);

    final zoomed = camera.zoomAround(
      focalPoint: const Offset(500, 250),
      scale: 0.01,
      dimensions: dimensions,
      viewportSize: viewportSize,
    );

    expect(zoomed.cellSize, closeTo(4.52, 0.000001));
    expect(
      zoomed.cellSize * dimensions.rows,
      closeTo(
        viewportSize.height - PatternCamera.viewportPadding * 2,
        0.000001,
      ),
    );
  });

  test('pan remains bounded around the document', () {
    const dimensions = PatternDimensions(100, 100);
    const viewportSize = Size(500, 500);
    const camera = PatternCamera(cellSize: 10, origin: Offset.zero);

    final panned = camera.panBy(
      delta: const Offset(10000, -10000),
      dimensions: dimensions,
      viewportSize: viewportSize,
    );

    expect(panned.origin, const Offset(24, -524));
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_camera.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_viewport_bounds.dart';

/// Verifies distinct document-clamped paint and prefetch ranges.
void main() {
  test('expands prefetch bounds by one tile without expanding paint bounds', () {
    const dimensions = PatternDimensions(100, 100);
    const camera = PatternCamera(cellSize: 10, origin: Offset(-170, -170));

    final bounds = PatternViewportBounds.calculate(
      camera: camera,
      viewportSize: const Size(100, 100),
      dimensions: dimensions,
    );

    expect(
      bounds.paintBounds,
      const GridBounds(
        startRow: 16,
        endRow: 28,
        startColumn: 16,
        endColumn: 28,
      ),
    );
    expect(
      bounds.prefetchBounds,
      const GridBounds(
        startRow: 0,
        endRow: 48,
        startColumn: 0,
        endColumn: 48,
      ),
    );
  });

  test('clamps tile-aligned prefetch bounds at document edges', () {
    const dimensions = PatternDimensions(18, 18);
    const camera = PatternCamera(cellSize: 10, origin: Offset.zero);

    final bounds = PatternViewportBounds.calculate(
      camera: camera,
      viewportSize: const Size(50, 50),
      dimensions: dimensions,
      prefetchTileDistance: 3,
    );

    expect(
      bounds.paintBounds,
      const GridBounds(startRow: 0, endRow: 6, startColumn: 0, endColumn: 6),
    );
    expect(
      bounds.prefetchBounds,
      const GridBounds(startRow: 0, endRow: 18, startColumn: 0, endColumn: 18),
    );
  });

  test('keeps an empty paint range empty for prefetching', () {
    const dimensions = PatternDimensions(20, 20);
    const camera = PatternCamera(cellSize: 10, origin: Offset(-1000, -1000));

    final bounds = PatternViewportBounds.calculate(
      camera: camera,
      viewportSize: const Size(10, 10),
      dimensions: dimensions,
    );

    expect(bounds.paintBounds.isEmpty, isTrue);
    expect(bounds.prefetchBounds, bounds.paintBounds);
  });

  test('allows profiling to disable the prefetch expansion', () {
    const dimensions = PatternDimensions(100, 100);
    const camera = PatternCamera(cellSize: 10, origin: Offset(-170, -170));

    final bounds = PatternViewportBounds.calculate(
      camera: camera,
      viewportSize: const Size(100, 100),
      dimensions: dimensions,
      prefetchTileDistance: 0,
    );

    expect(
      bounds.prefetchBounds,
      const GridBounds(
        startRow: 16,
        endRow: 32,
        startColumn: 16,
        endColumn: 32,
      ),
    );
  });
}

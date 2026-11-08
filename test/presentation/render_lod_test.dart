import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/presentation/pattern_renderer/render_lod.dart';

/// Verifies renderer detail thresholds and transition hysteresis.
void main() {
  test('selects initial detail levels at the documented thresholds', () {
    expect(resolveRenderLod(cellSize: 2.9), RenderLod.overview);
    expect(resolveRenderLod(cellSize: 3), RenderLod.grid);
    expect(resolveRenderLod(cellSize: 11.9), RenderLod.grid);
    expect(resolveRenderLod(cellSize: 12), RenderLod.detail);
  });

  test('retains prior detail near thresholds until hysteresis is crossed', () {
    expect(
      resolveRenderLod(cellSize: 3.1, previous: RenderLod.overview),
      RenderLod.overview,
    );
    expect(
      resolveRenderLod(cellSize: 3.25, previous: RenderLod.overview),
      RenderLod.grid,
    );
    expect(
      resolveRenderLod(cellSize: 2.8, previous: RenderLod.grid),
      RenderLod.grid,
    );
    expect(
      resolveRenderLod(cellSize: 2.74, previous: RenderLod.grid),
      RenderLod.overview,
    );
    expect(
      resolveRenderLod(cellSize: 11.8, previous: RenderLod.detail),
      RenderLod.detail,
    );
    expect(
      resolveRenderLod(cellSize: 11.74, previous: RenderLod.detail),
      RenderLod.grid,
    );
  });

  test('supports direct jumps across multiple detail levels', () {
    expect(
      resolveRenderLod(cellSize: 20, previous: RenderLod.overview),
      RenderLod.detail,
    );
    expect(
      resolveRenderLod(cellSize: 1, previous: RenderLod.detail),
      RenderLod.overview,
    );
  });
}

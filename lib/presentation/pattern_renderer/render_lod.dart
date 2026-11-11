import 'dart:math' as math;

import '../../domain/pattern_grid.dart';

/// Automatic detail level selected from the current on-screen cell size.
enum RenderLod {
  /// Tile summaries, major rules, and borders replace microscopic cell detail.
  overview,

  /// Individual cells and rules remain visible while glyphs are suppressed.
  grid,

  /// Every configured cell layer and legible glyph is rendered.
  detail,
}

/// Two adjacent summary resolutions and their continuous blend weight.
class OverviewRenderLevels {
  /// Creates a resolution blend from a finer level toward a coarser level.
  const OverviewRenderLevels({
    required this.fineBlockSize,
    required this.coarseBlockSize,
    required this.coarseWeight,
  });

  /// Cell width of the finer overview summary blocks.
  final int fineBlockSize;

  /// Cell width of the coarser overview summary blocks.
  final int coarseBlockSize;

  /// Opacity assigned to the coarser level, between zero and one.
  final double coarseWeight;

  /// Whether a second summary resolution contributes to this frame.
  bool get blendsLevels => fineBlockSize != coarseBlockSize && coarseWeight > 0;
}

/// Selects summary sizes that stay near [targetBlockPixels] on screen.
OverviewRenderLevels resolveOverviewRenderLevels({
  required double cellSize,
  double targetBlockPixels = 6,
}) {
  assert(cellSize.isFinite && cellSize > 0);
  assert(targetBlockPixels.isFinite && targetBlockPixels > 0);
  final sizes = PatternGrid.overviewBlockSizes;
  final desiredBlockSize = targetBlockPixels / cellSize;
  if (desiredBlockSize <= sizes.first) {
    return OverviewRenderLevels(
      fineBlockSize: sizes.first,
      coarseBlockSize: sizes.first,
      coarseWeight: 0,
    );
  }
  if (desiredBlockSize >= sizes.last) {
    return OverviewRenderLevels(
      fineBlockSize: sizes.last,
      coarseBlockSize: sizes.last,
      coarseWeight: 0,
    );
  }
  for (var index = 0; index < sizes.length - 1; index++) {
    final fineSize = sizes[index];
    final coarseSize = sizes[index + 1];
    if (desiredBlockSize > coarseSize) continue;
    final coarseWeight =
        math.log(desiredBlockSize / fineSize) / math.log(coarseSize / fineSize);
    if (coarseWeight >= 1) {
      return OverviewRenderLevels(
        fineBlockSize: coarseSize,
        coarseBlockSize: coarseSize,
        coarseWeight: 0,
      );
    }
    return OverviewRenderLevels(
      fineBlockSize: fineSize,
      coarseBlockSize: coarseSize,
      coarseWeight: coarseWeight.clamp(0, 1),
    );
  }
  throw StateError('Overview block resolution could not be resolved.');
}

/// Resolves renderer detail with hysteresis around three and twelve pixels.
RenderLod resolveRenderLod({required double cellSize, RenderLod? previous}) {
  assert(cellSize.isFinite && cellSize > 0);
  if (previous == null) {
    if (cellSize < 3) return RenderLod.overview;
    if (cellSize < 12) return RenderLod.grid;
    return RenderLod.detail;
  }
  if (cellSize < 2.75) return RenderLod.overview;
  if (cellSize >= 12.25) return RenderLod.detail;
  return switch (previous) {
    RenderLod.overview when cellSize < 3.25 => RenderLod.overview,
    RenderLod.detail when cellSize >= 11.75 => RenderLod.detail,
    RenderLod.overview || RenderLod.grid || RenderLod.detail => RenderLod.grid,
  };
}

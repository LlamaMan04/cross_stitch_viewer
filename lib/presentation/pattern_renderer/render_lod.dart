/// Automatic detail level selected from the current on-screen cell size.
enum RenderLod {
  /// Tile summaries, major rules, and borders replace microscopic cell detail.
  overview,

  /// Individual cells and rules remain visible while glyphs are suppressed.
  grid,

  /// Every configured cell layer and legible glyph is rendered.
  detail,
}

/// Resolves renderer detail with hysteresis around three and twelve pixels.
RenderLod resolveRenderLod({
  required double cellSize,
  RenderLod? previous,
}) {
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

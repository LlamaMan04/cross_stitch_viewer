# Renderer Symbol-Painting Optimization Plan

## Objective

Improve panning smoothness at the border of symbol rendering, especially on systems where a newly exposed tile causes a visible frame-time spike. Preserve the current rendering behavior while reducing work performed on the interactive path.

The primary hypothesis is that the hitch occurs when panning crosses a 16×16 source-tile boundary. The viewport overscans by only one cell, cache writes are disabled during interaction, and a missing tile falls back to per-cell fill and glyph painting. The result is a burst of `TextPainter.paint`, path construction, and display-list work exactly when a new edge enters the viewport.

## Scope and non-goals

This plan covers:

- Static tile-picture reuse and prefetching.
- Active pan versus continuous zoom rendering policies.
- Symbol glyph picture caching.
- Spatial indexing for dynamic overlays.
- Grid geometry reuse.
- Renderer instrumentation and performance validation.

It does not change the normalized pattern model, symbol interpretation, selection semantics, or visual styling unless a later benchmark demonstrates that a visual adjustment is required.

## Current rendering path

The relevant flow is:

1. `PatternCamera.visibleBounds` computes the visible grid range with one-cell overscan.
2. `ViewportPatternPainter._prepareStaticTileFrame` converts that range into 16×16 source tiles.
3. Cached fill and glyph pictures are replayed when available.
4. During cache misses, the painter enumerates tile cells and paints fills and glyphs directly.
5. Dynamic completion and selected-symbol overlays scan visible cells separately.
6. Grid paths are rebuilt for each paint.

The important interaction policy is that cache writes are suspended during camera interaction. This is useful for zoom, where the scale changes continuously, but it also makes same-scale pan misses expensive because newly exposed tiles cannot be warmed while the gesture is active.

## Phase 0 — Establish a reproducible baseline

### Implementation

1. Enable the existing renderer instrumentation with `PATTERN_RENDER_INSTRUMENTATION`.
2. Add a repeatable benchmark fixture containing:
   - A large sparse pattern.
   - A dense pattern with many repeated symbols.
   - A pattern with many distinct symbols.
   - Completed-cell and selected-symbol overlays enabled.
3. Exercise these cases at detail level:
   - Slow horizontal pan across a tile boundary.
   - Slow vertical pan across a tile boundary.
   - Diagonal pan across two tile boundaries.
   - Repeated back-and-forth pan over the same boundary.
   - Wheel and pinch zoom near the detail threshold.
4. Record build time, raster time, tile hits/misses, cache bytes, evictions, visible cells, glyphs, and draw calls.
5. Capture a performance trace on at least one fast desktop and one slower or mobile-class device.

### Acceptance criteria

The baseline should identify whether the hitch correlates primarily with:

- Tile misses.
- Cache evictions.
- Direct glyph painting.
- Dynamic overlay scans.
- Grid-path construction.
- Raster cost of replaying many pictures.

Do not tune cache sizes or tile dimensions until this data is available.

## Phase 1 — Make panning tile-aware

### 1. Expand the effective prefetch range

Add separate concepts for `paintBounds` and `prefetchBounds`.

- Keep `paintBounds` close to the viewport to avoid unnecessary draw work.
- Expand `prefetchBounds` by at least one full source tile in every direction.
- Clamp both ranges to document dimensions.
- Use tile-aligned prefetch bounds so the cache can warm complete tiles rather than repeatedly preparing partial edge ranges.

The initial default should be one tile of prefetch in each direction. Make the value configurable for profiling.

### 2. Add a tile prefetch queue

Create a small viewport-owned prefetch coordinator that:

- Receives the current camera, render LOD, style, and prefetch bounds.
- Prioritizes tiles nearest to the visible edge.
- Avoids duplicate work for keys already cached or queued.
- Limits the number of tiles recorded per frame.
- Cancels or deprioritizes stale work after a large pan or zoom.

The queue should use the same `PatternTilePictureKey` and recording code as normal cache population. It must not mutate document data.

### 3. Reuse the previous static frame during pan

Retain the previous frame's tile leases or pictures for the duration of an active same-scale pan.

Suggested behavior:

1. At gesture start, retain the current static tile frame.
2. During pan, translate and replay retained pictures using the camera delta.
3. Paint only newly exposed strips or tiles that are already available.
4. If a new tile is unavailable, leave the existing translated frame visible for that area or paint a cheap fallback, depending on visual requirements.
5. On gesture end, render the exact current frame and release the old frame.

The fallback must avoid displaying stale content outside the document bounds. The document background and clip remain authoritative.

### 4. Permit bounded writes during pure pan

Split interaction state into:

- `isPanning`: same cell size, camera translation only.
- `isZooming`: cell size changes.

For panning:

- Keep cache reuse enabled.
- Permit a bounded number of tile recordings per frame or queue them for the next frame.
- Avoid recording more than the configured per-frame budget.

For zooming:

- Continue bypassing exact-scale picture reuse while the scale is changing.
- Resume cache population after the gesture settles.

This preserves the current zoom optimization while removing the unnecessary restriction for same-scale movement.

## Phase 2 — Reduce glyph recording cost

### 1. Add a glyph picture cache

Introduce a bounded cache keyed by:

- Display glyph.
- Foreground color.
- Quantized font-size bucket.
- Any font or text configuration that affects layout.

Each cache entry should contain a `ui.Picture` recorded around a stable origin, plus its measured width and height. Use a lease or deferred-disposal mechanism similar to `PatternTilePictureCache` so eviction cannot dispose a picture currently being replayed.

### 2. Replace repeated `TextPainter.paint` calls during tile recording

During `_paintGlyphsForCells`:

- Resolve the glyph picture once for each distinct glyph/style combination in the tile.
- Translate to the cell center.
- Replay the picture instead of laying out and painting text per cell.

Retain `PatternGlyphLayoutCache` for measurement and fallback behavior. The glyph picture cache is an optimization on top of layout caching, not a replacement for correctness checks.

### 3. Define scale-bucket behavior

Use the same or a compatible scale quantization strategy as tile pictures. Validate that the maximum visual error from scaling a glyph picture is acceptable. If glyph scaling produces blurry output on a target platform, use narrower font-size buckets or record glyphs at a slightly higher representative size.

### Acceptance criteria

- New tile recording performs one glyph-picture lookup per distinct glyph/style combination rather than one text paint per cell.
- Glyph readability matches the existing renderer at detail-level scales.
- Cache growth remains bounded and does not cause frequent tile-picture evictions.

## Phase 3 — Index dynamic overlays

Static tile pictures do not cover dynamic completion and selection overlays. These currently iterate over visible cells on every paint.

### 1. Completed-cell spatial index

Build an immutable or incrementally maintained map from `PatternTileCoordinate` to completed coordinates. During painting:

- Determine intersecting tiles from `paintBounds`.
- Visit only completed coordinates in those tiles.
- Batch overlay rectangles into one or a small number of paths grouped by paint.

This preserves exact-cell overlays while avoiding a scan through all visible populated cells.

### 2. Selected-symbol index

Add a document-level or viewport-level index from `symbolId` to populated cells, preferably grouped by tile. When a symbol is selected:

- Resolve its tile groups once.
- Intersect only those groups with the visible tile range.
- Paint matching cells without testing every visible cell.

Invalidate or rebuild this index only when the document changes. Selection changes should not rebuild the document index.

### 3. Batch dynamic rectangles

Replace one `drawRect` call per completed or selected cell with paths grouped by paint where practical. Keep separate paths for fills and outlines because they use different paint styles.

## Phase 4 — Cache grid geometry

Grid paths are rebuilt for each frame even though their structure changes only when the camera scale bucket, visible tile range, or grid settings change.

### Implementation

Create a bounded grid-picture cache keyed by:

- Visible tile-aligned range or a grid tile range.
- Quantized cell size.
- Grid color and relevant settings.
- Render LOD.

Record minor, major, and outside rules into separate pictures or one picture with stable paint state. Replay the pictures translated to the current camera origin.

If a full grid-picture cache is too expensive, first cache the line geometry and rebuild only the final screen-space transform.

### Caution

Do not cache a picture at an exact camera origin if that causes cache churn for every pan offset. Cache grid geometry in tile-local coordinates and apply the camera translation during replay.

## Phase 5 — Revisit tile sizing and cache budgets

Only after Phases 1–4 are measured, evaluate these parameters:

### Tile size

The current 16×16 tile is a compromise:

- Smaller tiles reduce the cost of an individual miss but increase picture count and replay calls.
- Larger tiles reduce replay calls but make an edge miss more expensive.

Benchmark 8×8, 16×16, and 32×32 using the same fixtures. Choose based on worst-frame raster time, not average frame time alone.

### Cache budget

Track:

- Hit rate during repeated pans.
- Evictions per second.
- Native display-list memory.
- Time spent recording tiles.

Increase the default budget only if eviction is demonstrably causing the hitch and memory remains acceptable on target systems. Consider separate budgets for glyph-heavy detail pictures and cheaper fill-only pictures.

### Scale quantization

The current quarter-pixel cell-size buckets can produce many cache variants during zoom. Keep exact-scale zoom bypass behavior, but consider coarser settled buckets if the visual quality remains acceptable.

## Phase 6 — Validate behavior and regressions

### Functional tests

Add tests for:

- Prefetch bounds being tile-aligned and clamped.
- Prefetch cancellation after a camera jump.
- Pan reuse preserving the correct translated content.
- Zoom continuing to bypass stale scale-specific pictures.
- Glyph picture cache eviction and active-frame disposal safety.
- Completed and selected overlays matching the previous cell-by-cell output.
- Grid cache invalidation when color, settings, LOD, or scale bucket changes.

### Performance tests

Add benchmark assertions or diagnostic thresholds for:

- Maximum tile recordings per pan frame.
- Maximum direct glyph paints per pan frame.
- Cache hit rate after a repeated pan.
- Evictions during a representative viewport sweep.
- Worst raster frame time at tile boundaries.

Avoid brittle absolute timing thresholds across all platforms. Prefer relative comparisons against the current implementation and record platform-specific baselines where possible.

### Visual validation

Check:

- Symbols at the viewport edge.
- Symbols crossing tile boundaries.
- Document edges and empty cells.
- Detail/grid/overview LOD transitions.
- Selection and completion overlays during motion.
- Theme and font changes, which must invalidate affected native pictures.

## Suggested implementation order

1. Add targeted counters for direct glyph paints, tile recordings, prefetch work, overlay candidates, and grid rules.
2. Split pan and zoom cache policies.
3. Add tile-aligned prefetch with a strict per-frame recording budget.
4. Add previous-frame static-layer reuse for active panning.
5. Add spatial overlay indexes and path batching.
6. Add the glyph picture cache.
7. Add grid geometry caching.
8. Benchmark tile sizes, cache budgets, and scale buckets.
9. Run functional, performance, and visual regression validation.

## Definition of done

The optimization is complete when:

- Crossing a tile boundary during a steady pan no longer causes a visible hitch on supported target systems.
- Direct per-cell glyph painting is rare during pan and bounded during cache warm-up.
- Repeated pans over the same region achieve a high tile-picture hit rate without excessive evictions.
- Dynamic overlays remain correct and no longer require full visible-cell scans.
- Zoom remains visually stable and does not replay incorrectly scaled pictures.
- Theme, font, document, and renderer-setting changes invalidate all affected caches.
- The result is verified with frame timing traces, renderer metrics, and visual regression tests.

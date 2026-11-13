# Renderer Symbol-Painting Optimization Plan

## Objective

Reduce frame-time spikes when panning across source-tile boundaries while preserving the current rendering behavior, selection semantics, visual styling, and normalized pattern model.

The primary suspected cause is synchronous work for newly exposed 16×16 tiles: cell enumeration, per-cell glyph painting, display-list recording, dynamic overlay scans, and grid-path construction can all occur on the interactive paint path.

## Completed foundation

The renderer already has bounded tile-picture caching with document, style, LOD, and quantized-scale keys; leased native-picture disposal; sparse tile-backed grid queries; overview summaries; visible-cell memoization; fill/grid path batching; glyph layout caching; and zoom-time tile-picture bypass. Renderer instrumentation and representative large-pattern fixtures also exist.

The remaining work below is not yet complete: measured baselines, tile prefetching, previous-frame pan reuse, glyph-picture caching, dynamic overlay indexes, grid geometry caching, parameter tuning, and end-to-end performance validation.

## Implementation plan

### Phase 0 — Establish a reproducible baseline

#### 0.1 Expand renderer metrics

Extend `PatternRenderBatchMetrics` and its instrumentation output with:

- Direct cell-fill count and direct glyph-paint count.
- Tile recordings started, completed, rejected, and queued.
- Prefetch requests, prefetched tiles, cancelled requests, and stale requests.
- Dynamic-overlay candidates visited and primitives painted.
- Grid rules generated and grid paths recorded/replayed.
- Per-frame pan/zoom state and whether the frame was interactive.

Keep cumulative cache counters separate from per-frame counters so a trace can distinguish current-frame work from lifetime totals.

#### 0.2 Add repeatable benchmark scenarios

Create a renderer benchmark or diagnostic test harness using deterministic fixtures for:

1. A large sparse pattern.
2. A dense pattern with a small repeated symbol set.
3. A pattern with many distinct symbols and colors.
4. Completed-cell and selected-symbol overlays enabled.

For each scenario, exercise:

- Slow horizontal, vertical, and diagonal pans across tile boundaries.
- Repeated back-and-forth pans over the same boundary.
- Wheel and pinch zoom near each LOD threshold.
- Theme/style changes after the cache has warmed.

Capture build time, raster time, tile hits/misses, recordings, evictions, cache bytes, visible cells, glyph work, overlay candidates, grid work, and draw calls.

#### 0.3 Record baseline traces

Run the scenarios on at least one desktop and one slower/mobile-class target. Store the scenario description and summarized results in the repository, not brittle platform-specific absolute timing assertions. Use the baseline to identify the dominant cost before changing tile size or cache budgets.

### Phase 1 — Make same-scale panning tile-aware

#### 1.1 Introduce paint and prefetch bounds

Add a viewport-owned bounds calculation with these separate concepts:

- `paintBounds`: the document-clamped range that is actually drawn.
- `prefetchBounds`: a tile-aligned range expanded by a configurable number of source tiles in every direction.

The initial prefetch distance should be one 16×16 tile. Keep the value configurable for profiling. Ensure negative camera positions, document edges, small documents, and empty ranges are handled without producing invalid tile coordinates.

The painter must use `paintBounds` for visible rendering and never expand actual draw work merely because prefetching is enabled.

#### 1.2 Extract shared tile recording

Move tile-key creation, tile-cell lookup, and static tile-picture recording behind a reusable service or viewport helper. Both normal cache population and prefetching must call the same implementation so they cannot diverge in style, LOD, scale, or invalidation behavior.

The helper should return a leased cache entry when possible and must safely dispose rejected or temporary pictures. It must not mutate `PatternDocument` or progress state.

#### 1.3 Add a bounded prefetch coordinator

Create a small coordinator owned by `PatternViewport` that receives:

- The current camera and render LOD.
- Static tile-picture style.
- Paint and prefetch bounds.
- The current interaction generation or camera revision.

Implement the following behavior:

1. Generate tile keys for the prefetch range.
2. Remove keys already cached or already queued.
3. Prioritize tiles closest to the visible edge, then tiles in the pan direction.
4. Record at most a configurable number of tiles per frame.
5. Schedule remaining work using post-frame callbacks or a controlled microtask/frame queue.
6. Cancel or deprioritize work from an old camera revision after a large pan, zoom, document change, or style change.
7. Request a repaint after useful work completes.

Do not let prefetch work run unbounded inside `paint`. It must be cooperative and observable through metrics.

#### 1.4 Split pan and zoom policies

Represent interaction state explicitly as either:

- Settled.
- Same-scale panning.
- Continuous zooming.

For same-scale panning:

- Continue reusing matching cached pictures.
- Permit only the configured number of synchronous tile recordings per frame.
- Send additional misses to the prefetch coordinator.

For continuous zooming:

- Continue bypassing exact-scale tile-picture reuse while the scale changes.
- Avoid cache writes during the zoom gesture.
- Resume cache population only after the gesture settles.

Ensure a small scale delta cannot accidentally switch a pure pan into zoom mode, and ensure wheel zoom uses the same policy as pinch zoom.

#### 1.5 Reuse the previous static frame during active pan

Retain the previous static tile frame or its leases at the start of a same-scale pan. During the gesture:

1. Translate retained pictures by the camera delta.
2. Clip to the document and viewport bounds.
3. Paint newly exposed strips from already available tiles.
4. Use direct fallback only for bounded newly exposed work when no picture is available.
5. Do not show translated content outside document bounds; the document background and clip remain authoritative.
6. At gesture end, render the exact camera position, release old leases, and schedule prefetch for the surrounding tiles.

The frame-reuse implementation must be disabled or invalidated when scale, LOD, document identity, theme, font inputs, or static render settings change.

#### 1.6 Add Phase 1 tests

Cover:

- Tile-aligned and clamped prefetch bounds.
- Duplicate suppression and stale-request cancellation.
- Per-frame recording limits.
- Pure pan reuse versus zoom bypass.
- Correct document-edge clipping during translated-frame reuse.
- Lease safety when a retained frame is evicted or replaced.

### Phase 2 — Reduce glyph recording cost

#### 2.1 Add a bounded glyph-picture cache

Create a cache of recorded glyph pictures keyed by every input that affects their appearance:

- Display glyph.
- Foreground color.
- Quantized font-size bucket.
- Font family, weight, text direction, and any other relevant text configuration.
- Renderer/font generation used for invalidation.

Each entry should contain the picture, measured width/height, estimated memory cost, and deferred-disposal state. Use the same lease pattern as tile pictures so eviction cannot dispose of a picture being replayed.

Use an entry or byte budget and expose hits, misses, evictions, and bytes in diagnostics.

#### 2.2 Replay glyph pictures while recording tiles

Update `_paintGlyphsForCells` so it:

1. Resolves symbol metadata and contrast as it does today.
2. Groups or resolves repeated glyph/style combinations once per tile.
3. Replays the cached glyph picture translated to the cell center.
4. Retains `PatternGlyphLayoutCache` for measurement, fallback, and correctness checks.
5. Falls back to `TextPainter.paint` if a glyph cannot be safely cached.

The glyph picture cache is an optimization below tile-picture caching; it must not change glyph placement or fallback behavior.

#### 2.3 Validate scale buckets

Use compatible quantization with tile pictures and measure readability at detail-level scales. If scaling introduces blur on a target platform, narrow the bucket width or record at a slightly higher representative size. Add visual tests for symbols at tile edges and at LOD transitions.

### Phase 3 — Index and batch dynamic overlays

#### 3.1 Build completed-cell tile indexes

Create an immutable or incrementally maintained index from `PatternTileCoordinate` to completed coordinates. Rebuild it only when the completed-cell set changes.

During painting:

1. Compute the tiles intersecting `paintBounds`.
2. Visit completed coordinates only in those tiles.
3. Filter to the exact visible bounds.
4. Accumulate rectangles into paths grouped by overlay paint.

Completion changes must update or replace the affected index without coupling it to imported pattern data.

#### 3.2 Build selected-symbol indexes

Create a document-derived index from `threadId` or symbol identity to populated cells grouped by tile. Resolve the selected thread once, then inspect only matching tile groups intersecting `paintBounds`.

Selection changes must not rebuild the document index. Document replacement must create a new index. Preserve the existing rule that completed cells may be excluded from selection according to settings.

#### 3.3 Batch dynamic rectangles

Replace one canvas call per completed or selected cell with one or a small number of paths per paint/style group. Keep selected fills and outlines separate because they use different paint state. Preserve draw order relative to static fills, glyphs, grid, regions, and backstitches.

#### 3.4 Add overlay tests

Compare indexed rendering with the current cell-by-cell result for:

- Empty, sparse, dense, and boundary-crossing tiles.
- Completed cells at document edges.
- Selected symbols with and without completed cells included.
- Selection and completion changes without document changes.

### Phase 4 — Cache grid geometry

#### 4.1 Define grid cache keys

Create a bounded grid-geometry or grid-picture cache keyed by:

- Tile-aligned visible range or grid geometry tile range.
- Quantized cell size.
- Grid color and relevant grid settings.
- Render LOD.
- Document dimensions where document-edge rules are involved.

Do not key on the exact camera origin. Camera translation must be applied during replay.

#### 4.2 Record and replay grid geometry

Prefer tile-local line geometry or pictures. Keep minor, major, and outside rules in separate paths/pictures when that avoids paint-state changes. Replay the cached geometry translated to the current camera origin.

Invalidate entries when grid color, visibility/settings, LOD, scale bucket, document dimensions, theme, or font/ruler inputs change.

If native grid pictures are not beneficial on a target platform, retain cached line geometry and only rebuild the screen-space transform.

#### 4.3 Add grid-cache tests

Verify reuse across camera translations and invalidation after every key input changes. Check document edges, overview major-only rules, and scale-bucket changes.

### Phase 5 — Tune tile size, cache budgets, and quantization

Only after Phases 1–4 are implemented and measured, benchmark:

- 8×8, 16×16, and 32×32 source tiles.
- Multiple tile-picture byte budgets.
- Separate glyph-heavy and fill-only budgets if useful.
- Current quarter-pixel scale buckets versus coarser settled buckets.
- Different prefetch distances and per-frame recording limits.

Choose settings using worst-frame raster time and interaction smoothness, not average frame time alone. Record hit rate, evictions per second, recording time, native display-list memory, and worst boundary-crossing frame.

Keep platform-specific defaults only when the measurements demonstrate a meaningful difference and the configuration remains understandable.

### Phase 6 — Functional, performance, and visual validation

#### 6.1 Functional validation

Run the full Flutter test suite and add focused tests for:

- Prefetch bounds and cancellation.
- Pan frame reuse and lease disposal.
- Zoom bypass and settled cache warming.
- Glyph-picture cache keys, eviction, fallback, and disposal.
- Completed and selected overlay indexes.
- Grid-cache invalidation.
- Theme, font, document, and renderer-setting invalidation.

#### 6.2 Performance validation

Use relative or platform-specific baselines rather than one brittle absolute timing threshold. Track:

- Maximum synchronous tile recordings per pan frame.
- Maximum direct glyph paints per pan frame.
- Cache hit rate after repeated pans.
- Prefetch completion rate.
- Evictions during a representative viewport sweep.
- Overlay candidates visited.
- Worst raster frame at a tile boundary.

#### 6.3 Visual validation

Check symbols and overlays:

- At viewport edges and across tile boundaries.
- At document edges and in empty cells.
- During detail/grid/overview transitions.
- During active pan and zoom.
- After theme, font, and renderer-setting changes.

Use golden or screenshot-based comparisons where practical, with targeted manual checks for native-picture scaling and text sharpness.

## Recommended delivery order

1. Expand instrumentation and add benchmark scenarios.
2. Implement explicit interaction modes and bounded same-scale pan recording.
3. Add tile-aligned prefetch and stale-work cancellation.
4. Add previous-frame static-layer reuse.
5. Add completed and selected overlay indexes with path batching.
6. Add glyph-picture caching and scale-bucket validation.
7. Add grid geometry caching.
8. Tune tile size, cache budgets, prefetch distance, and scale quantization.
9. Run functional, performance, and visual regression validation.

## Definition of done

The optimization is complete when:

- Steady panning across a tile boundary has no visible hitch on supported targets.
- Synchronous tile recordings and direct glyph paints are bounded during pan.
- Prefetching warms likely next tiles without expanding actual paint work.
- Repeated pans achieve a high tile-picture hit rate without excessive evictions.
- Dynamic overlays no longer scan all visible populated cells.
- Grid geometry is reused across camera translations.
- Zoom does not replay incorrectly scaled pictures.
- Theme, font, document, and renderer-setting changes invalidate affected caches.
- Results are supported by renderer metrics, frame traces, functional tests, and visual validation.

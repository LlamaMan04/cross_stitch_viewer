# Pattern Renderer Analysis

This is a static code review of the pattern renderer. No code changes were made as part of the analysis, and performance conclusions are based on code paths and the repository's optimization plan rather than device benchmarks.

## 1. God files and mixed responsibilities

### `pattern_viewport.dart`

[`pattern_viewport.dart`](../lib/presentation/pattern_renderer/pattern_viewport.dart) is the primary god file. It combines:

- Flutter widget construction and layout.
- Camera initialization, resizing, and persistence.
- Pan, pinch-zoom, wheel-zoom, and pointer gesture handling.
- Tap and backstitch hit testing.
- Completion-selection drag behavior.
- Cache invalidation and cache ownership.
- Overview completion indexing.
- Renderer instrumentation setup.
- Painter construction.

The file is approximately 875 lines and spans presentation layout, interaction state, camera control, cache lifecycle, and renderer-specific indexing.

Recommended split:

- `PatternViewport` widget/layout.
- `PatternViewportInteractionController`.
- `PatternViewportCacheCoordinator`.
- `PatternViewportSelectionController`.
- `PatternViewportCameraLifecycle`.

### `viewport_pattern_painter.dart`

The painter has been split into Dart `part` files, but the main painter remains responsible for coordinating:

- Static tile rendering.
- Dynamic overlays.
- Overview rendering.
- Grid rendering.
- Backstitches.
- Frame reuse.
- Prefetch submission.
- Instrumentation metrics.

The central `paint` method coordinates nearly every renderer subsystem. The `part` files reduce file size but remain tightly coupled to private state in the main painter.

### `pattern_symbol_render_cache.dart`

This class mixes several concerns:

- Symbol metadata construction.
- Backstitch metadata construction.
- Backstitch visibility queries.
- Mutable fill-paint caching.
- Weighted-average color calculations.
- Color parsing.

These could be separated into symbol metadata, a backstitch spatial index, fill-paint caching, and overview color aggregation utilities.

## 2. Efficiency and remaining optimization work

### Dynamic overlays scan visible cells repeatedly

Completed and selected cells are both derived by scanning `_visibleCells`. The same visible cells may therefore be traversed for fills, completed overlays, selected overlays, glyphs, and tile fallback work.

The repository's [`OPTIMIZATION_PLAN.md`](OPTIMIZATION_PLAN.md) identifies completed-cell indexes, selected-symbol indexes, and batched overlay paths as unfinished Phase 3 work.

Recommended improvement:

- Index completed coordinates by source tile.
- Index populated cells by thread ID and tile.
- Batch completed and selected rectangles into paths grouped by paint.
- Visit only tiles intersecting the visible bounds.

### Grid geometry is rebuilt every frame

`_paintGrid` reconstructs minor, major, and outside paths on every paint. It loops over visible horizontal and vertical rules and allocates new `Path` objects each frame.

Grid-path replay metrics exist, but grid geometry caching has not been implemented. This is unfinished Phase 4 work in the optimization plan.

Recommended improvement:

- Cache tile-local grid geometry or pictures.
- Key entries by cell-size bucket, grid style, LOD, and document dimensions.
- Replay geometry with camera translation instead of rebuilding screen-space paths.

### Backstitch queries are linear scans

`backstitchesIntersecting` filters the entire backstitch list for every query and creates a new list. This affects both rendering and backstitch hit testing.

Recommended improvement:

- Build a spatial index keyed by tile or coarse region.
- Reuse the same index for rendering and hit testing.

### Prefetch candidate sorting can become expensive

The prefetch coordinator builds, filters, and sorts the full candidate list on every submission. Actual recording is bounded, but candidate generation remains proportional to the prefetch range and sorting is `O(P log P)`.

Recommended improvement:

- Use a bounded priority queue.
- Generate only candidates needed for the configured per-frame budget.
- Avoid re-sorting unchanged candidate ranges between nearby camera revisions.

### Static tile recorder creation is repeated

The painter creates a `PatternStaticTileRecorder` multiple times during one paint pass: during normal painting, static-frame preparation, and prefetch submission.

Recommended improvement:

- Create one recorder per paint pass.
- Pass it through static-frame preparation and prefetch submission.

### Viewport bounds are recalculated repeatedly

Bounds are calculated in the widget build, the painter's `paintBounds` getter, and prefetch submission. These calculations are cheap but redundant.

Recommended improvement:

- Create one immutable bounds snapshot per paint pass and pass it through the renderer.

### Glyph rendering still performs per-cell cache work

Glyph-picture caching is implemented, but glyph painting still performs metadata resolution, key construction, and cache lookup/lease work for every visible cell.

Recommended improvement:

- Group cells by glyph appearance key.
- Resolve or acquire one glyph picture per group.
- Replay it for all matching cells.

### Completion overview indexing can be expensive

When completion data changes, the viewport maps the entire completion set over every overview block size. This is `O(5C)` for the current five resolutions.

Recommended improvement:

- Maintain or incrementally update overview completion indexes when completion changes are frequent.

## 3. Duplication

### Duplicate overview-indexing implementations

`_indexCompletedOverviewCoordinates` and `_indexOverviewCoordinates` in `pattern_viewport.dart` have effectively identical implementations. They should share one helper accepting an iterable of coordinates.

### Duplicate color parsing logic

The same `#RRGGBB` to opaque Flutter `Color` conversion appears in multiple renderer files and in the workspace palette code.

Recommended improvement:

- Move color parsing into a shared value-object or rendering utility.

### Repeated overlay filtering and rectangle painting

Completed cells, selected cells, and completion-selection cells each independently iterate candidates, check visibility, calculate rectangles, and issue draw calls.

The overlays are semantically distinct, but they can share candidate indexing, rectangle conversion, and path-batching helpers.

### Repeated coordinate conversion logic

The viewport and painter independently perform screen-to-grid and grid-to-screen conversions. A shared geometry service would reduce duplicated boundary and coordinate logic.

## 4. Poor coding practices and structural improvements

### Side effects during `build`

`PatternViewport.build` calls `_updateCameraForLayout` before constructing widgets. This mutates camera state during build and makes lifecycle behavior harder to reason about.

Recommended improvement:

- Move layout-dependent camera updates into a dedicated layout callback or controller.
- Keep build focused on deriving widgets from current state.

### Too many mutable state machines in one state object

The viewport state tracks camera lifecycle, gesture lifecycle, selection drag lifecycle, wheel-zoom debounce, cache generations, completion indexes, instrumentation, and theme invalidation.

Recommended improvement:

- Extract controllers with explicit ownership of each state machine.
- Centralize cache invalidation rules.

### Unused prefetch parameter

`PatternTilePrefetchCoordinator.submit` accepts `renderLod`, but the coordinator does not use it.

Recommended improvement:

- Remove the parameter, or use it to prevent inappropriate prefetch work for unsupported LODs.

### Redundant frame-reuse expression

The frame-reuse code computes:

```dart
retainedCamera.origin + (camera.origin - retainedCamera.origin)
```

This is algebraically equal to `camera.origin`. The simpler expression would make the transform easier to verify.

### Paint allocation is scattered through hot paths

Background, selection, region, backstitch, and overview paints are created in multiple paint paths. Some per-frame allocation is justified, but a centralized style bundle would make paint state easier to manage and may reduce allocation overhead.

### Individual overlay draw calls remain unbatched

Selected, completed, and completion-selection overlays use one `drawRect` per cell. This is explicitly contrary to the open Phase 3 batching plan and can become expensive for dense progress overlays.

### Mutable collections weaken invalidation assumptions

The viewport accepts mutable `Set<GridCoordinate>` instances and uses identity comparisons for some invalidation decisions. In-place mutation can therefore make changes difficult to detect reliably.

Recommended improvement:

- Use immutable collections or defensive snapshots at the widget boundary.

## Recommended implementation order

1. Add tile-indexed completed and selected overlay indexes.
2. Batch dynamic overlay rectangles into paths.
3. Add grid geometry caching and replay.
4. Add a backstitch spatial index shared by painting and hit testing.
5. Reuse one bounds snapshot and one static tile recorder per paint pass.
6. Consolidate duplicate overview indexing and color parsing.
7. Split viewport interaction, camera lifecycle, and cache coordination into separate controllers.
8. Group repeated glyph appearance keys during tile recording and direct fallback rendering.
9. Run target-device profiling before tuning tile sizes, cache budgets, or scale quantization.

## Overall assessment

The renderer has a strong optimization foundation: sparse tile queries, bounded tile caches, glyph-picture caching, frame reuse, prefetch limits, overview summaries, and diagnostics are already present.

The highest-value remaining work is dynamic overlay indexing and batching, followed by grid caching. The most significant maintainability issue is the concentration of widget lifecycle, interaction, cache, and rendering coordination inside `pattern_viewport.dart`.

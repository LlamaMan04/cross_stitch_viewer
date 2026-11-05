# Viewport Rendering Pipeline Implementation Plan

## Purpose

Replace the current full-pattern, fitted `CustomPaint` renderer with a
viewport-driven renderer. Each frame must perform work proportional to the
currently visible grid area, rather than to the complete document dimensions,
all populated cells, or all source regions.

This plan implements the rendering requirements in `UI_Changes.md`:

- Render only the visible grid area.
- Make color fills, symbols, source regions, rulers, and grid styling
  independently configurable.
- Default to symbols visible, cell colors hidden, source regions hidden, and
  a solid black grid.
- When cell colors are enabled, render each cell with its source thread color;
  thread colors are exempt from the grayscale styling request.
- Draw minor rules, 10-by-10 sub-grid rules, and outside borders at distinct,
  capped widths.
- Move workspace controls out of the main pattern viewport.

## Current-State Assessment

`PatternRenderView` currently uses `InteractiveViewer` to transform a child
whose `CustomPaint` is the viewport size. `PatternGridPainter` first fits the
whole grid into that canvas, then each paint does all of the following:

1. Iterates every sparse stitch cell.
2. Iterates every horizontal and vertical rule in the entire pattern.
3. Iterates every source region.
4. Iterates every row and column label once the cells are large enough.

Transforming that finished picture does not limit painter work to the visible
world region. It also makes it difficult to keep ruler text and rule widths
stable on the screen.

The domain already has a sparse cell map through `PatternGrid.cellAt` and has
a `ViewportState` model suitable for persisting a camera. It needs a
range-query index before visible-only rendering is guaranteed for sparse,
large documents.

## Target Architecture

```text
PatternWorkspaceScreen
|- compact workspace command bar
`- workspace body
   |- left collapsible renderer-settings panel
   |- PatternViewport (stateful)
   |  |- camera controller (grid-space pan + pixels-per-cell zoom)
   |  |- gesture adapter (drag, pinch, wheel/trackpad)
   |  |- viewport layout (optional fixed rulers + drawable grid rect)
   |  |- render-LOD resolver (derived from on-screen cell size)
   |  `- CustomPaint(ViewportPatternPainter)
   |     |- calculate VisibleGridBounds
   |     |- query visible cells and intersecting regions
   |     |- paint background and optional cell fills
   |     |- paint completion and selected-symbol overlays
   |     |- paint optional symbols
   |     |- paint minor / major / outside grid rules
   |     |- paint optional region outlines
   |     `- paint fixed top and left ruler overlays
   `- right collapsible symbol-palette panel
      `- select a symbol and view its glyph, thread color, brand, catalog
         number, name, conversion notes, and other available thread details
```

The painter owns no gesture state and performs no persistence. The viewport
widget owns interaction and rebuilds/repaints the painter when the camera or
render settings change. Imported `PatternDocument` data remains immutable;
camera position and visual preferences are mutable user state.

## Data Contracts and New Types

Create the following presentation-layer types, preferably under
`lib/presentation/pattern_renderer/`:

| Type | Responsibility |
| --- | --- |
| `PatternRenderSettings` | Immutable, persistable visual switches, colors, opacity, and ruler configuration. |
| `GridColorPreset` | Named allowed grid colors; default is black. |
| `PatternRenderSelection` | Ephemeral selected symbol ID and any selection-specific visual state. |
| `CompletedCellStyle` | Immutable color and opacity used to gray completed cells. |
| `RenderLod` | Automatic overview, grid, or detail paint policy derived from `cellSizePx`. |
| `PatternCamera` | Pixels per cell plus the screen-space location of grid coordinate `(0, 0)`. |
| `VisibleGridBounds` | Inclusive/exclusive row and column range visible in the drawable grid rectangle. |
| `PatternViewportController` | Owns camera changes, fit/reset, bounds clamping, and optional restoration. |
| `PatternViewport` | Stateful widget that measures space, handles gestures, and hosts `CustomPaint`. |
| `ViewportPatternPainter` | Paints only the supplied visible bounds. |

`PatternRenderSettings` should have these initial fields:

```dart
const PatternRenderSettings(
  showCellColor: false,
  showSymbols: true,
  cellColorOpacity: 0.22,
  colorMode: PatternColorMode.threadColor,
  completedCellColor: Colors.grey,
  completedCellOpacity: 0.55,
  gridColor: Colors.black,
  showRegions: false,
  showTopRuler: true,
  showLeftRuler: true,
)
```

Clamp opacity to `0..1`, keep all settings immutable, and provide `copyWith`.
When `showCellColor` is enabled, use the imported thread color unchanged
(apart from the configured alpha). `PatternColorMode.threadColor` is the
default and cell fills must not be desaturated or converted to grayscale. If a
future non-thread color treatment is added, it must be an explicit opt-in and
must not replace the true-color mode.

`PatternRenderSelection` holds `String? selectedSymbolId` outside of imported
pattern data. Selecting a palette entry must cause every *visible* cell with
that symbol ID to receive the selected-symbol highlight; panning reveals the
same highlight on additional matching cells. The selected symbol's own palette
row remains visually selected until it is cleared or another symbol is chosen.

Completed-cell styling is separate from both thread color and symbol
selection. Source completion comes from `ProgressState.completedCells`; the
renderer tests only visible coordinates against that state. The completed-cell
overlay uses configurable `completedCellColor` and `completedCellOpacity`,
with a neutral gray default. The overlay must visibly gray completed cells
while preserving their grid lines and, when enabled, their glyphs.

`PatternRenderSettings` is part of `ViewportState`, not transient widget
state. Add a `renderSettings` field to the domain `ViewportState`, defaulting
to the settings shown above so existing callers and restored pre-settings
records remain valid. `ViewportState.validate` must validate every persisted
setting: opacity ranges, `#RRGGBB` color format, recognized color mode, and
any constrained grid-color preset. Keep `PatternRenderSelection` ephemeral;
the active palette selection and whether either side panel is currently open
are interaction state rather than viewport render settings.

Extend `PatternGrid` with an efficient, immutable range query such as:

```dart
Iterable<StitchCell> cellsIntersecting(VisibleGridBounds bounds);
```

The domain layer must not import presentation types. Define a domain-neutral
row/column bounds value object in `domain`, or accept primitive range
arguments. A tile index is the preferred implementation:

- Use fixed grid tiles (for example, 32 by 32 cells).
- Build `Map<TileCoordinate, List<StitchCell>>` once in the `PatternGrid`
  constructor.
- Query only tiles intersecting the visible bounds and filter their cells.
- Retain `cellAt` for direct lookup and existing callers.

This keeps a dense, zoomed-in view cheap and avoids scanning every populated
cell in a large sparse document.

Augment each spatial tile with immutable, precomputed summary data for
overview rendering: populated-cell count, dominant thread/symbol color, and
the symbol IDs/counts it contains. Completion and selection are mutable state,
so derive their tile accents from the current progress/selection state only for
visible tiles. Tile summaries and dynamic accents must not trigger a scan of
all cells when the camera enters overview zoom.

## Coordinate System

Use a single, explicit mapping throughout the renderer:

```text
screenX = gridOriginX + column * cellSizePx
screenY = gridOriginY + row    * cellSizePx
```

`gridOrigin` is the screen-space top-left of grid coordinate `(0, 0)` within
the drawable grid rectangle. It changes during pan; `cellSizePx` changes
during zoom. Do not scale a pre-painted child to implement zoom.

For the drawable grid rectangle `drawRect`, calculate the range as follows,
then clamp it to document dimensions and add a one-cell overscan:

```text
firstColumn = floor((drawRect.left   - gridOriginX) / cellSizePx)
lastColumn  = ceil ((drawRect.right  - gridOriginX) / cellSizePx)
firstRow    = floor((drawRect.top    - gridOriginY) / cellSizePx)
lastRow     = ceil ((drawRect.bottom - gridOriginY) / cellSizePx)
```

Use half-open bounds: `[firstRow, lastRow)` and `[firstColumn, lastColumn)`.
This removes endpoint ambiguity when determining visible cells and grid rules.

The viewport controller must clamp panning so the document stays reachable
without allowing unbounded blank space. Permit a small configurable edge
overscroll, but derive it from the drawable area, not the old full-grid
padding. Zoom around the focal gesture position: convert the focal screen
point to a grid coordinate before changing `cellSizePx`, then recompute the
origin so that grid coordinate remains beneath the finger/cursor.

## Rendering Stages

`ViewportPatternPainter.paint` should resolve `RenderLod` from the current
`cellSizePx`, clip to the drawable grid rectangle, and paint these stages in
order:

1. Paint the viewport background.
2. Query and paint visible cell fills when `showCellColor` is enabled.
3. Paint a semi-transparent completed-cell overlay for visible coordinates in
   `ProgressState.completedCells`.
4. Paint the selected-symbol highlight on every visible cell whose `symbolId`
   matches `PatternRenderSelection.selectedSymbolId`.
5. Query and paint visible glyphs when `showSymbols` is enabled and cells are
   large enough to be legible.
6. Paint only visible minor rules, ten-cell rules, and document-edge rules.
7. Query and paint source-region outlines only when `showRegions` is enabled.
8. Restore the clip and paint top/left rulers, which remain fixed overlays.

For every cell, calculate its screen rectangle directly from the camera.
Color fill uses the cell's source thread color and
`settings.cellColorOpacity`; do not apply a grayscale/desaturation transform.
Symbol foreground should be chosen for contrast against the effective
fill/background, not merely the raw thread color. Cache `TextPainter` or paragraph layout by symbol glyph,
font-size bucket, and foreground color if profiling shows glyph layout is a
hot path.

The selected-symbol highlight needs a distinct, accessible visual treatment
(for example, a high-contrast outline or translucent accent overlay) that can
coexist with both the completion overlay and true thread-color fill. Do not
hide selected cells simply because cell color or symbols are disabled.

### Level-of-Detail Policy

Level-of-detail is an automatic rendering decision, not a persisted viewport
setting. It is calculated solely from the on-screen `cellSizePx` and does not
change the camera, document data, or saved render settings. Every LOD still
queries only visible cells or visible spatial tiles.

| `RenderLod` | Cell-size range | Render policy |
| --- | --- | --- |
| `overview` | Below 3 logical pixels per cell | Omit glyphs and minor rules. Draw document borders and 10-by-10 rules, then render visible tile summaries/density rather than every cell. |
| `grid` | 3 through less than 12 logical pixels per cell | Draw visible cell fills when enabled plus capped minor, major, and border rules; omit glyphs. |
| `detail` | 12 or more logical pixels per cell | Draw individual visible fills, symbols, completion overlays, selected-symbol highlights, all visible rules, and rulers. |

Use hysteresis around each threshold so small zoom changes do not make layers
flicker. For example, promote from `overview` to `grid` at 3.25 pixels and
demote only below 2.75 pixels; promote from `grid` to `detail` at 12.25 pixels
and demote only below 11.75 pixels. Keep this threshold policy in a pure,
unit-tested `RenderLod resolveRenderLod(...)` function.

At overview level, selection and completion must remain discoverable without
per-cell painting: add a tile-level accent when a visible tile contains the
selected symbol or completed cells. At grid level, use normal overlays for
visible individual cells. At detail level, use the complete cell treatment.

### Grid Rules

Classify a visible rule as follows:

- A document edge is an outside rule.
- A coordinate divisible by ten is a major/sub-grid rule.
- All other coordinates are minor rules.

Paint only the row and column coordinates that intersect `VisibleGridBounds`,
including the final exclusive bound so the visible cells are closed. Keep
stroke widths in logical screen pixels. Widths must be capped relative to the
visible cell size, for example:

```text
minor   = min(1.0 px, cellSizePx * 0.18)
major   = min(1.5 px, cellSizePx * 0.26)
outside = min(2.0 px, cellSizePx * 0.35)
```

Allow overview zoom below individual-cell legibility through the LOD policy.
Never claim that every microscopic cell is individually distinguishable;
instead, omit the visually merged details and use visible tile summaries.

### Rulers

Reserve a fixed ruler extent only when its corresponding ruler is enabled.
The top ruler aligns ticks with visible column rules; the left ruler aligns
with visible row rules. Draw a tick at every visible grid line and attach each
label to its grid line, never to the center of a grid square. Labels are
zero-indexed grid-line coordinates: the far-left/far-top border is `0`, and
the line ten cells to its right/below is `10`. Draw text only for visible
coordinates divisible by ten. Use this same zero-indexed, grid-line convention
in ruler accessibility labels and any future coordinate-entry UI.

At overview zoom, keep tick positions aligned to grid lines but suppress ruler
text that would overlap. Select a larger zero-indexed label interval such as
100 or 1,000 grid lines based on available screen spacing; this is a label
decluttering rule only and does not change the 10-cell major-grid positions.

## UI Composition and Settings

1. Replace the tall title block in `PatternWorkspaceScreen` with a compact
   app bar/command bar containing back navigation, title, dimensions, reset
   view, a left-settings-panel toggle, and a right-symbol-palette toggle.
2. Let `PatternViewport` fill all remaining available space; remove the large
   outer decoration/padding that reduces renderer area.
3. Place the renderer settings in a collapsible window that expands from the
   left side of the workspace. It contains cell-color/symbol/region/ruler
   toggles, grid-color presets, cell-color opacity, and completed-cell color
   and opacity controls.
4. Place the symbol palette in an independent collapsible window that expands
   from the right side of the workspace. It lists document symbols, supports
   selecting/clearing a symbol, and shows the selected symbol's glyph and
   associated thread information.
5. When either panel is collapsed, the viewport reclaims its width. On narrow
   layouts, preserve the left/right semantic placement using edge drawers or
   sheets opened from their respective command-bar controls.
6. Persist every `PatternRenderSettings` field per pattern as part of its
   `ViewportState`. Reload those values before constructing the viewport so a
   document reopens with the same visual configuration. Do not place them in
   `PatternDocument` or global application settings.

## Persistence and Restoration

`ViewportState` is the storage boundary for both the camera and every viewport
render setting. Extend the domain model, `ViewportStates` table, generated
Drift data class, and `ProgressMapper` together; no renderer setting may live
only in widget memory. Continue to specify its camera coordinate convention:

- `zoom`: `cellSizePx`, or a stable multiplier from a named base cell size.
- `panX`/`panY`: grid origin in grid-space units, not physical pixels, so a
  viewport can restore sensibly at a different screen size.
- `anchor`: the grid coordinate under the viewport center at save time.
- `visibleRows`/`visibleColumns`: diagnostic/restoration context only.

Add one `ViewportStates` column for each `PatternRenderSettings` property:

| Domain setting | `viewport_states` column | Storage and default |
| --- | --- | --- |
| `showCellColor` | `show_cell_color` | Boolean, default `false`. |
| `showSymbols` | `show_symbols` | Boolean, default `true`. |
| `cellColorOpacity` | `cell_color_opacity` | Real, default `0.22`, constrained to `0..1`. |
| `colorMode` | `color_mode` | Text enum, default `thread_color`; only recognized modes allowed. |
| `gridColor` | `grid_color` | Canonical `#RRGGBB`, default black. |
| `showRegions` | `show_regions` | Boolean, default `false`. |
| `showTopRuler` | `show_top_ruler` | Boolean, default `true`. |
| `showLeftRuler` | `show_left_ruler` | Boolean, default `true`. |
| `completedCellColor` | `completed_cell_color` | Canonical `#RRGGBB`, default neutral gray. |
| `completedCellOpacity` | `completed_cell_opacity` | Real, default `0.55`, constrained to `0..1`. |

Use non-null columns with SQL defaults and checks wherever SQLite can enforce
the contract. The database migration must add the columns with those defaults,
backfill existing viewport rows through the defaults, increment the database
schema version, and preserve every existing camera field. Regenerate
`app_database.g.dart`; never hand-edit the generated file. Extend
`ProgressMapper.viewport` and `ProgressMapper.fromRows` so the domain
`ViewportState` and the persisted row round-trip every field.

On restoration, prefer the anchor plus zoom. Center the anchor in the new
drawable rect, apply the stored pan if compatible, then clamp to document
bounds. Save after a settings change and after pan/zoom settles or when
leaving the workspace; debounce/coalesce writes so rapid slider changes and
pointer events do not write progress state on every update.

## Implementation Sequence

### Phase 1: Establish contracts and tests

1. Add focused unit tests for visible-bounds calculation, including negative
   origins, edges, fractional cells, and one-cell overscan.
2. Add `PatternRenderSettings`, preset validation, and default-value tests.
3. Extend `ViewportState` with persisted render settings and add domain
   validation/default-value tests.
4. Extend `ViewportStates`, `ProgressMapper`, the database schema version,
   and the migration path for all render-settings columns; regenerate Drift
   code and add migration/round-trip tests.
5. Add `PatternGrid` range-query tests for empty, sparse, dense, and
   tile-boundary cases.
6. Add `RenderLod`, its hysteresis resolver, and visible-tile summary tests.
7. Add a renderer package/directory without changing the existing workspace
   path yet.

### Phase 2: Build the camera and viewport shell

1. Implement `PatternCamera` conversion helpers: screen-to-grid,
   grid-to-screen, visible bounds, and focal-point zoom.
2. Implement `PatternViewportController` with notifier/listenable behavior.
3. Build `PatternViewport` with `LayoutBuilder`, a fixed-size `CustomPaint`,
   and gesture handling.
4. Add reset/fit-to-pattern behavior. Fit should be an explicit camera setup,
   not a geometry calculation performed on every paint.
5. Add widget tests for drag, pinch/scroll zoom, reset, and viewport resizing.

### Phase 3: Replace the painter

1. Extract document/theme inputs and replace `PatternGridPainter` with
   `ViewportPatternPainter`.
2. Implement clipping and visible-only cell rendering using the new range
   query.
3. Implement the three rule classes with capped screen-space widths.
4. Add symbol-only, color-only, combined, and neither rendering modes.
5. Implement true thread-color parsing and opacity, preserving the source RGB
   value for enabled cell fills.
6. Add visible-only completed-cell overlays using `ProgressState` and its
   configurable gray color/opacity.
7. Add visible-only selected-symbol highlights, keyed by selected symbol ID.
8. Add source-region intersection filtering and default it to hidden.
9. Apply the three-level LOD policy: visible tile summaries at overview,
   glyph suppression at grid level, and complete per-cell rendering at detail.

### Phase 4: Add rulers and settings controls

1. Calculate the drawable rect after optional ruler strips.
2. Paint fixed rulers with every-line ticks and zero-indexed labels on each
   ten-cell grid line, including the `0` document border.
3. Add the left-side collapsible settings panel and the right-side collapsible
   symbol palette/thread-information panel.
4. Wire renderer controls to `PatternRenderSettings` and palette selection to
   `PatternRenderSelection`; neither may reset the camera position.
5. Verify the panels collapse independently and return their occupied width to
   the viewport.

### Phase 5: Integrate progress and remove legacy behavior

1. Load and restore camera state plus every persisted render setting when
   opening a document.
2. Debounce and save camera state and render-settings changes through
   `ProgressRepository`.
3. Remove the old `InteractiveViewer`, its padded full-grid child, and the
   all-pattern label implementation.
4. Update widget tests that assert the old widget tree or legacy scale values.
5. Document the coordinate and persistence conventions in code comments.

## Test and Verification Plan

### Unit Tests

- Visible bounds include exactly the cells/rules intersecting the drawable
  rect, including document edges.
- Grid-space/screen-space conversion round-trips within floating-point
  tolerance.
- Focal zoom preserves the grid coordinate under the focal point.
- Pan clamping works for documents both smaller and larger than the viewport.
- Range query returns the same cells as a reference full-list filter.
- Color opacity clamps and preserves the source thread RGB value.
- LOD thresholds and hysteresis select the expected overview, grid, and detail
  modes without transition flicker.
- Overview tile summaries match reference calculations and query only visible
  tiles.
- `ViewportState` validation rejects invalid persisted render settings and
  supplies the documented defaults when settings are absent from legacy data.
- Completed-cell color and opacity clamp, and completed-coordinate lookup is
  limited to the visible range.
- Selected-symbol matching highlights every visible matching cell and no
  nonmatching cells.
- Major rules occur at every tenth coordinate and outer rules occur only at
  document boundaries.

### Widget and Painter Tests

- Default view paints symbols but no color fill or source regions.
- Each display toggle affects only its expected paint layer.
- Selecting a symbol in the right palette highlights all visible cells using
  that symbol; the highlight persists through pan/zoom and clears correctly.
- Completed cells use the configured gray overlay while retaining grid lines
  and enabled symbols.
- Overview suppresses glyphs and minor rules while retaining major rules,
  document borders, and tile-level completion/selection indicators.
- Grid LOD suppresses glyphs; detail LOD restores individual symbols and all
  configured cell layers.
- Rulers reserve space only when enabled, place labels on grid lines rather
  than grid-square centers, and show `0`, `10`, `20`, etc. at ten-cell
  intervals.
- Left settings and right palette panels collapse independently; collapsed
  panels return their width to the pattern viewport.
- Change a setting, reload the pattern, and verify every render setting is
  restored from the associated `ViewportStates` record.
- A large fixture remains interactive after repeated pan/zoom operations.
- Resize/orientation changes retain a valid bounded camera.
- Verify painter inputs contain only the calculated visible bounds; expose
  test-only counters or a query spy instead of relying solely on pixels.

### Manual Performance Checks

- Test dense and sparse patterns substantially larger than the 100-by-200
  sample fixture.
- Profile pan and pinch on the supported desktop and mobile targets.
- Confirm frame work is unchanged when total off-screen cells/regions grow.
- Inspect at minimum, normal, and maximum zoom to confirm rules never obscure
  a cell and ruler text remains readable.

## Acceptance Criteria

- No paint path iterates all document cells, rows, columns, or regions merely
  because a repaint occurred.
- The default appearance is symbols on, color fills off, source regions off,
  and a solid black grid.
- Enabling cell colors renders the imported thread colors faithfully at the
  configured opacity; it does not grayscale or desaturate them.
- Selecting a symbol highlights every visible cell using that symbol without
  requiring a full-document render.
- Completed cells are visibly grayed using configurable color and opacity,
  while their grid lines and enabled glyphs remain visible.
- LOD is derived from on-screen cell size with hysteresis; overview rendering
  uses only visible tile summaries, grid rendering omits glyphs, and detail
  rendering restores individual-cell detail.
- Every viewport render setting round-trips through the domain model,
  `ViewportStates`, `ProgressMapper`, and database migration with the stated
  defaults for pre-existing rows.
- Visible 10-by-10 boundaries are thicker than minor rules and thinner than
  outside borders.
- Grid stroke widths are capped relative to on-screen cell size.
- Top and left rulers can be toggled independently and only label ten-cell
  grid lines using zero-indexed coordinates (`0`, `10`, `20`, ...).
- Pattern controls no longer materially reduce the main renderer viewport.
- Camera interaction, fitting, and restoration remain valid after layout-size
  changes.
- `flutter analyze` and the complete `flutter test` suite pass.

## Risks and Decisions to Resolve Before Coding

| Decision | Why it matters | Recommended initial choice |
| --- | --- | --- |
| Tile size | Balances index memory against query work. | Start at 32 by 32 and profile. |
| Very-low-zoom behavior | Individual cells cannot be legible indefinitely. | Support overview LOD with visible tile summaries, major rules, and decluttered rulers. |
| Render-setting scope | Determines persistence schema and UX. | Persist all viewport render settings per pattern in `ViewportStates`. |
| Completed-cell style scope | Determines whether a user sees the same completion treatment across patterns. | Persist as part of that pattern's `ViewportState`. |
| Highlight treatment | Must remain visible over color fills and completion overlays. | Use an accessible high-contrast outline plus optional accent tint. |
| Coordinate labels | Prevents off-by-one confusion. | Use zero-indexed grid-line labels: `0` is the outer border and `10` is ten cells over. |
| Region styling | Must not obscure pattern data. | Outline-only, hidden by default. |
| Text caching | Can improve dense symbol views but adds complexity. | Profile first; cache only if text layout is material. |

## Files Expected to Change

- `lib/presentation/screens/pattern_workspace_screen.dart` — compact workspace
  composition and integration point for the new viewport.
- `lib/presentation/pattern_renderer/` — new viewport, camera, painter,
  settings, geometry, and ruler components.
- `lib/domain/pattern_grid.dart` — immutable spatial/range query support.
- `lib/domain/progress_models.dart` and progress persistence adapters — only
  required for persisted camera and render-setting contracts.
- `lib/infrastructure/persistence/schema/progress_tables.dart` — persisted
  render-setting columns and database constraints for `ViewportStates`.
- `lib/infrastructure/persistence/database_migrations.dart` — schema upgrade
  and backfill defaults for existing viewport rows.
- `lib/infrastructure/persistence/progress_mapper.dart` — full domain/row
  mapping for viewport render settings.
- `test/` — domain range-query, geometry, painter, and interaction coverage.

This work requires a database migration because viewport render settings are
persisted in existing durable state. The migration must preserve legacy camera
data and assign the documented defaults to every newly added setting column.

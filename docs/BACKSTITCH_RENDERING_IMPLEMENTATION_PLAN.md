# Backstitch Rendering Implementation Plan

## Objective

Render imported backstitches as selectable line segments over the pattern grid.
Each segment has a start coordinate, an end coordinate, and a stitch color. A
segment uses its stitch color when cell colors are enabled, or solid black when
they are disabled. Selecting a segment highlights every backstitch with the
same color.

## Scope and decisions

- Store backstitches independently from `StitchCell`. A backstitch can cross
  cells, share endpoints with other lines, and have no one-to-one cell owner.
- Represent endpoints in pattern-space coordinates, where `(0, 0)` is the
  upper-left grid corner and `(columns, rows)` is the lower-right grid corner.
  Use a dedicated immutable `BackstitchCoordinate` value object with finite
  `double column` and `double row` fields. This supports normal corner-to-corner
  segments and partial-cell endpoints without losing precision.
- Associate every line with a stable `symbolId`; resolve its color through the
  existing symbol/thread definition. This preserves the current document model
  and ensures imported thread metadata remains the source of truth.
- Define "same color" by the normalized resolved thread color value, not by
  symbol ID. Different symbols that map to the same thread color must highlight
  together.
- Keep backstitch selection ephemeral, like the current symbol selection. It
  must not be written into `ProgressState` unless a later product decision adds
  persisted selection.

## 1. Extend the domain document contract

1. Add an immutable `BackstitchSegment` domain model with:
   - stable segment ID;
   - `BackstitchCoordinate start` and `BackstitchCoordinate end`;
   - `String symbolId`; and
   - optional confidence, review, and provenance fields consistent with
     imported stitch data where parser support requires them.
2. Add `List<BackstitchSegment> backstitches` to `PatternDocument` (or a
   dedicated immutable pattern-annotation aggregate owned by it). Do not add
   these segments to `PatternGrid` or encode them as `StitchCell`s.
3. Validate that IDs are unique, both endpoints are finite and inside the
   inclusive grid-corner bounds, endpoints are not identical, and each
   `symbolId` exists in the document definitions.
4. Extend document codecs, Drift mappings/migrations, fixtures, equality, and
   repository round-trip tests so segments survive import, save, reopen, and
   export unchanged.

## 2. Prepare visible-segment queries and render metadata

1. Create a segment bounds helper that calculates each line's axis-aligned
   pattern-space bounding box.
2. Index segments into fixed spatial tiles, or initially filter a compact list
   by intersection with the visible pattern bounds. The final query must include
   lines whose endpoints are off-screen but whose stroke crosses the viewport.
3. Add resolved backstitch metadata to the existing symbol render cache (or a
   small adjacent cache): segment ID, resolved opaque thread color, and bounds.
   Avoid parsing color strings during `paint`.
4. Expose an immutable visible-segment collection to the painter and reuse it
   across the normal and selected backstitch layers for a frame.

## 3. Add the rendering layer

1. Paint backstitches after cell fills and symbols, and after the grid if the
   product decision is that outlines should remain unobscured; use the same
   coordinate-to-canvas transform as the grid. Keep region and completion
   overlays visually intentional in the chosen layer order.
2. Convert each endpoint from pattern space to canvas space and submit visible
   segments with `Canvas.drawLine` or color-grouped paths.
3. Define named stroke constants. The normal backstitch stroke must be visibly
   greater than the major/sub-grid stroke weight, while retaining a practical
   maximum/minimum screen-space width during extreme zoom levels.
4. Resolve the normal stroke paint as follows:
   - `showCellColor == true`: opaque resolved stitch/thread color;
   - `showCellColor == false`: solid `Colors.black`.
5. Clip to the viewport, set butt or round caps deliberately (round is the
   preferred initial choice for hand-drawn continuity), and set joins/caps in
   one centralized paint factory.
6. Make line visibility LOD-aware. At detail and grid LOD, render individual
   segments; at overview LOD, either omit them or use a documented lightweight
   aggregate only after visual validation. Never let an overview pass scan the
   entire document each frame.

## 4. Add selection and highlighting

1. Replace the symbol-only selection representation with a discriminated
   renderer selection, for example `none`, `symbol(symbolId)`, and
   `backstitch(segmentId, colorKey)`. Preserve existing symbol behavior.
2. On a tap/click, hit-test visible backstitch segments before cell selection.
   Calculate point-to-segment distance in screen space and accept the nearest
   segment inside a touch-friendly tolerance derived from the rendered stroke
   width.
3. When a segment is selected, derive its normalized resolved `colorKey` and
   select every visible backstitch with that key, including segments mapped
   through different symbols.
4. Draw selected matching lines in a distinct highlight layer. Use a wide,
   high-contrast selection under-stroke plus the normal line on top, so the
   original thread color remains recognizable when cell colors are enabled.
   In monochrome mode, retain black normal strokes with the same highlight
   under-stroke.
5. Tapping empty space clears a backstitch selection. Tapping a cell changes
   to symbol selection; tapping another segment replaces the active backstitch
   color selection. Add accessible semantics that identify a selected
   backstitch's endpoints and thread information.
6. Update workspace details/status text to identify the selected thread color
   and report the count of matching backstitch segments.

## 5. Fixtures and tests

1. Add a representative fixture with horizontal, vertical, diagonal,
   partial-cell, shared-endpoint, and viewport-crossing backstitches. Include
   two symbols with the same resolved color and one with a different color.
2. Add domain tests for coordinate validation, endpoint bounds, duplicate IDs,
   symbol references, and serialization/persistence round trips.
3. Add spatial-query tests proving that segments crossing the visible rectangle
   are returned even when neither endpoint lies inside it.
4. Add painter tests for layer order, endpoint transforms, normal stroke width
   being greater than the sub-grid width, and color resolution in both cell
   color modes.
5. Add interaction widget tests for segment hit tolerance, nearest-line choice
   at crossings, clearing selection, cell-versus-line precedence, and
   highlighting all same-color segments across different symbol IDs.
6. Run `dart format .`, `flutter analyze`, and focused domain/painter/workspace
   tests, followed by `flutter test` before merging.

## Acceptance criteria

- Backstitch data persists as exact start/end pattern coordinates and renders
  correctly while panning and zooming.
- Every normal line is thicker than a sub-grid line.
- Enabling cell colors shows each line in its resolved stitch color; disabling
  cell colors makes every line solid black.
- Selecting a line reliably highlights every same-color backstitch, including
  those represented by different symbols.
- Rendering and hit testing operate only on viewport-relevant segments and do
  not regress the existing visible-cell rendering path.

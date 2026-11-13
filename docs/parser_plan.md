# PDF Parsing Implementation Plan

## Purpose and scope

This plan implements step 6, **PDF-parsing stack**, from
[`IMPLEMENTATION_PLAN.md`](IMPLEMENTATION_PLAN.md). Its outcome is a
cross-platform, background-safe parser that turns a supported cross-stitch PDF
into a validated `PatternDocument`, or returns actionable diagnostics and
review data when it cannot do so safely.

The parser is an import subsystem, not part of the renderer. It must preserve
the distinction between immutable imported pattern data and mutable user
progress, and it must never silently invent a stitch, thread mapping, or page
join merely to produce a successful result.

## Current integration constraints

The current domain layer already provides the principal output types:

- `PatternDocument` owns a sparse `PatternGrid`, symbols, threads,
  backstitches, regions, source metadata, checksum, and diagnostics.
- `PatternRegion` maps a source page/panel into global grid coordinates.
- `StitchCell.provenanceId` can link a parsed cell to its region.
- `ParserDiagnostic` identifies severity, parser stage, global coordinate,
  source page, region, confidence, and suggested correction.
- `SymbolDefinition` preserves source and normalized symbol forms, display
  glyphs, legend evidence, stitch type, and optional thread count.
- `ThreadDefinition` captures catalog evidence and whether color was explicit
  or inferred.

Before integrating an engine, confirm the portable JSON codec work from Phase
1 is complete. Parser output must be round-trippable through that codec before
it can be persisted by the import flow.

## Release boundary

The first release supports PDFs that meet all of the following conditions:

- Not encrypted, password-protected, malformed, or larger than configured
  resource limits.
- Contain a readable cross-stitch legend and at least one detectable regular
  grid region.
- Use either extractable native content or raster content that the selected
  engine can render and the OCR/symbol pipeline can evaluate.
- Can be mapped to a single coordinate system with no unresolved blocking
  conflict.

Unsupported content must produce a failed or review-required result with an
explicit reason. Do not promise generic support for every PDF feature.

## Architecture and package boundaries

Create a pure-Dart parser package under `packages/pattern_pdf_parser/` (or
`lib/parser/` initially if a package extraction would disrupt the current
workspace). It may depend on `lib/domain` only through a deliberately small
adapter until the domain code is extracted into its own package.

```text
Flutter import UI / application use case
             |
             v
Parser facade and isolate coordinator (Dart)
             |
             +-- source guard and job limits
             +-- PDF engine adapter interface
             +-- staged evidence pipeline
             +-- normalizer and validator
             |
             v
PatternDocument + ParseReport / review evidence
```

Keep native PDF, image, and OCR libraries behind interfaces. Dart coordinates
the work, owns normalized models and diagnostics, and must not reimplement a
general PDF engine.

## Public API and result contract

Define a narrow API before selecting platform libraries:

```dart
Future<ParseResult> parsePatternPdf(
  Uint8List bytes,
  ParserOptions options, {
  ParseProgressCallback? onProgress,
  CancellationToken? cancellationToken,
});
```

`ParseResult` must be a sealed result rather than a boolean:

| Result | Meaning | Required contents |
| --- | --- | --- |
| `ParseSucceeded` | A document is valid and has no blocking issue. | `PatternDocument`, report, review evidence for warnings. |
| `ParseNeedsReview` | A structurally valid document exists, but warnings or unresolved values require user confirmation. | Provisional document, diagnostics, corrections/evidence. |
| `ParseFailed` | A safe document cannot be produced. | Diagnostics, capability/resource report, no persisted document. |
| `ParseCancelled` | The caller cancelled the job. | Last completed stage and no partial save. |

`ParserOptions` should include only caller-controlled, validated policy:

- Supported source byte and page-count limits.
- Render-DPI and image-pixel ceilings.
- Processing timeout and stage memory budget.
- OCR enablement and supported locale set.
- Confidence thresholds for warning, review, and rejection.
- A feature-profile version, parser version, and optional test-only engine
  selection.

Use a separate immutable `ParseReport` for engine version, capability report,
stage timings, page counts, redacted source facts, and aggregate confidence.
It must never contain source bytes, extracted full text, passwords, or paths.

## Internal evidence model

Avoid converting directly from engine primitives to domain objects. Build
intermediate, immutable evidence types so every decision is testable:

```text
PdfSourceInspection
  -> ExtractedPdfPage (native text, paths, images, transforms, capabilities)
  -> ClassifiedPage / ClassifiedRegion
  -> LegendCandidate + GridCandidate + OcrEvidence + SymbolEvidence
  -> CalibratedGridRegion + PageJoinCandidate
  -> NormalizedPatternDraft
  -> PatternDocument + ParseReport
```

All source geometry should use a single page-space rectangle type with explicit
PDF-to-rendered-image transforms. Store page indexes as zero-based internally.
Use global `GridCoordinate` only after calibration and splicing. Give every
candidate a stable evidence ID, confidence, source page, bounds, transform,
and reason codes. Keep bounded image crops and thumbnails only in transient
review data; do not store full PDF pages in the document database by default.

## Phase 0 — Contracts, limits, and test harness

1. Add parser-facing value types: `ParserOptions`, cancellation token,
   progress events, result variants, capability report, and evidence handles.
2. Add a `PdfEngine` interface for inspection, extraction, raster rendering,
   and capability reporting. Its methods must accept job limits and support
   cancellation between page or region operations.
3. Add interfaces for OCR and visual-symbol classification. Provide disabled
   implementations so native PDF extraction can be developed independently.
4. Define error-to-diagnostic mapping. Expected invalid user input is returned
   as `ParseFailed`; programming errors and adapter crashes are contained and
   converted to a redacted internal-engine diagnostic at the facade boundary.
5. Define hard defaults for maximum input bytes, page count, decompressed
   stream bytes, object count, nesting depth, image dimensions/pixels, raster
   DPI, crop count, stage time, and total memory. Make them measurable and
   configurable only within application-approved ceilings.
6. Create `test/parser/` with fake engines and deterministic source-evidence
   builders. Unit tests must not require native engines, OCR models, or a UI.
7. Add a fixture manifest that labels each fixture's license, source modality,
   expected profile support, dimensions, legend mappings, joins, selected cells,
   and expected diagnostics.

Exit criteria: parser orchestration can return each result variant from fake
evidence, supports cancellation, and has no Flutter widget dependency.

## Phase 1 — PDF engine evaluation and portable adapter

Evaluate PDFium, MuPDF, and Poppler against the release profile before
committing to an implementation. Score rendering fidelity, text/vector/image
extraction, malformed-file behavior, cross-platform build availability,
licensing, binary size, API stability, crash containment, and maintenance
cost. Record the scorecard and decision in `docs/`.

Implement the selected engine as a narrow adapter:

1. Inspect header and document metadata without executing JavaScript, actions,
   links, forms, embedded files, or attachments.
2. Report encryption state, page count, page dimensions, rotations, and
   supported/omitted feature classes.
3. Extract native text spans with font identifiers, glyph codepoints,
   transforms, bounding boxes, and reading order where available.
4. Extract vector paths, paint operations, clipping, and embedded-image
   metadata where the engine supports them.
5. Render a bounded page or source rectangle at requested DPI with its exact
   transform and color-space result.
6. Surface typed adapter errors, including malformed PDF, unsupported
   encryption, password requirement, renderer failure, and native crash.

Initially expose only an adapter with identical Dart semantics for every
supported target. If a platform needs a fallback engine, it must pass the same
golden corpus and declare behavioral differences through capabilities.

Exit criteria: representative native, scanned, rotated, and malformed PDFs can
be inspected/extracted/rendered or safely rejected on every target.

## Phase 2 — Input guarding and extraction

Implement these stages in order:

1. Verify PDF signature and minimally parseable structure through the engine;
   calculate a SHA-256 source checksum after the size check.
2. Reject or diagnose size, page-count, password, encryption-handler,
   unsupported active-content, and resource-limit violations before rendering.
3. For each page, retain dimensions, crop/media boxes, rotation, native
   extraction, image inventory, and engine-capability findings.
4. Normalize all bounds into unrotated page coordinates while retaining the
   original transform for previews and diagnostics.
5. Render only regions needed by later stages. Cache bounded rendered regions
   by page, crop, DPI, color mode, and source checksum for one parse job.
6. Emit progress at inspection, extraction, and page-complete boundaries; check
   cancellation before each page and expensive rendering/OCR operation.

Use native text and vectors as the primary evidence. Raster and OCR work is a
targeted fallback, not a blanket full-document rasterization pass.

Exit criteria: each page has a deterministic extraction record and every
omitted feature is present in the report or a diagnostic.

## Phase 3 — Page and region classification

Classify at both page and region level. A page may simultaneously contain a
grid, legend, instructions, and raster labels.

1. Use heading terms, text density, tabular alignment, repeated line spacing,
   vector-line density, image density, and aspect ratio to propose regions.
2. Produce candidate labels: `cover`, `instructions`, `legend`, `grid`,
   `continuation`, and `unknown`, each with confidence and evidence IDs.
3. Split mixed pages into non-overlapping regions where possible. Preserve
   overlap only when evidence is intentionally shared, such as labels adjacent
   to a grid.
4. Apply a deterministic rule set first. Reserve a future classifier only for
   tie-breaking and always retain the explainable features behind its score.
5. Mark pages with no viable grid candidate as non-pattern pages rather than
   treating every extracted symbol as a stitch.

Exit criteria: fixture classification identifies grid and legend regions on
mixed documents and produces reviewable uncertainty on ambiguous pages.

## Phase 4 — Legend and thread interpretation

1. Detect legend tables from native spans and geometry; use OCR only for
   absent/unreliable text layers or raster-only legend cells.
2. Infer columns from header text and repeated x-alignment: symbol, brand,
   catalog number, name, color, stitch type, strand count, and notes.
3. Normalize whitespace, Unicode normalization form, common brand aliases,
   catalog formatting, and RGB values. Preserve the original strings as
   `legendEvidence` and review evidence.
4. Build provisional thread and symbol records with deterministic IDs derived
   from canonical source evidence. Resolve duplicate visual symbols only after
   checking stitch type and legend row context.
5. Detect duplicate symbols, duplicate/conflicting thread IDs, absent catalog
   values, invalid colors, inferred colors, and mappings without a usable
   symbol. Emit a diagnostic rather than overwriting the first mapping.
6. Cross-check mappings against grid symbol frequency once grid evidence is
   available. Promote or reduce confidence based on agreement.

For an unresolved legend, retain an unassigned symbol candidate only in the
draft/review model. Do not create a final `StitchCell` that references a missing
`SymbolDefinition`.

Exit criteria: vector and scanned legend fixtures yield stable mappings,
evidence, and diagnostics for intentional conflicts.

## Phase 5 — Grid detection and calibration

1. Detect horizontal/vertical line candidates from vector paths first; use edge
   detection and line fitting only within rendered grid candidates.
2. Cluster repeated line spacing to estimate row/column pitch, boundaries,
   major-grid cadence, and panel extent.
3. Detect row/column labels from native text or OCR; associate labels by
   proximity and orientation, including rotated labels.
4. Fit an affine page-to-grid transform for clean PDFs. Permit bounded deskew
   and scale correction for scans; reject perspective distortion beyond the
   explicitly supported profile.
5. Validate candidate transforms using line residuals, label consistency,
   rectangularity, expected cell count, and symbol-center distribution.
6. Support multiple calibrated grid panels on a single page. Give each one a
   provisional region ID and retain exact source bounds.

Grid calibration must return confidence plus residual/error values. A grid that
looks plausible but fails label or spacing validation is review-required, not
accepted by default.

Exit criteria: known fixture grids map source cell centers to local integer
coordinates and deliberate skew/label failures produce diagnostics.

## Phase 6 — Symbol and stitch interpretation

1. Create a pattern-specific vocabulary from legend symbols before reading grid
   cells. Prefer extracted native text/vector glyph evidence where it maps
   cleanly into calibrated cells.
2. For raster cells, render at bounded DPI, crop with a small calibrated inset,
   normalize rotation/scale/background, and compare against vocabulary
   prototypes using deterministic image features.
3. Associate a visual match only when its confidence clears the configured
   threshold and its candidate is compatible with the legend/stitch type.
4. Detect blank cells separately from unknown cells. Blank cells remain absent
   from the sparse grid; unknown cells are review evidence and diagnostics,
   never an invented symbol.
5. Capture full, half, quarter, three-quarter, French-knot, and unknown stitch
   evidence where the source distinguishes them. Defer unsupported stitch
   semantics to a warning rather than flattening them to full stitches.
6. Parse backstitch paths separately, map their endpoints through the region
   transform, and only emit a `BackstitchSegment` after its referenced
   definition and coordinate bounds validate.
7. Store candidate ranking, crop reference, source geometry, and confidence in
   transient review evidence; place a concise diagnostic on low-confidence or
   conflicting final cells.

Exit criteria: sampled cells in vector and raster fixtures meet the corpus
accuracy target, while ambiguous and unknown symbols remain visible for review.

## Phase 7 — Multi-page splicing and provenance

1. Build join candidates using row/column labels, calibrated pitch, shared
   border overlap, continuation text, and edge symbol continuity.
2. Score candidate left/right/above/below relations and solve a consistent
   global placement graph. Do not rely on PDF page order alone.
3. Select one global origin, translate local panel coordinates into global
   `GridCoordinate`s, and create a `PatternRegion` for every accepted panel.
4. Resolve exact duplicate overlap only when symbol, stitch type, and mapping
   agree. Report conflicting overlaps, unexplained gaps, reversed orientations,
   disconnected panels, and missing page sequences as review/blocking issues.
5. Assign each accepted cell and backstitch segment its region provenance.
   Retain page/panel/source-bounds details in review evidence keyed by region.
6. Confirm global bounds, coordinate continuity, and region containment before
   constructing `PatternGrid` and `PatternDocument`.

Exit criteria: multi-page fixtures produce stable global coordinates and retain
source-page attribution for every populated cell.

## Phase 8 — Normalization, validation, and import handoff

1. Convert the resolved draft into domain objects with deterministic document,
   thread, symbol, region, and backstitch IDs. Document ID generation must be
   stable for a source checksum and parser/profile version, while allowing an
   application layer to choose the repository record ID if required.
2. Populate source metadata with sanitized filename (if supplied externally),
   source checksum, page count, parser/profile/engine versions, and import
   timestamp policy. Do not persist raw paths or source bytes in metadata.
3. Translate evidence findings into existing `ParserDiagnostic` values. Extend
   `DiagnosticStage` with `ocr` only if UI/reporting genuinely needs it;
   otherwise OCR findings should use their semantic stage (`legend`, `grid`, or
   `symbols`).
4. Run `PatternDocument.validate()` and parser-specific validations for legend
   coverage, cell confidence, regions, page joins, and source capabilities.
5. Return `ParseSucceeded` only when no diagnostic is blocking and all output
   references are valid. Return `ParseNeedsReview` for recoverable warnings;
   return `ParseFailed` without a document for invalid graphs or unsafe input.
6. The application import use case persists only a user-approved, validated
   document in one transaction. Progress records are never created or replaced
   by parsing itself.

Exit criteria: valid results serialize through the portable codec, persist via
the existing repository, reload, and preserve diagnostics/provenance.

## Review-data model and UX handoff

The domain document deliberately stays compact. Put large crops, alternate
symbol candidates, transform overlays, and original legend snippets in a
temporary `ParseReviewSession`, keyed by an opaque ID. The import UI uses it to
show pages, highlight diagnostics, and accept corrections before final save.

Corrections must be explicit operations such as select legend mapping, choose
symbol candidate, alter grid orientation, or approve/reject a page join. Each
operation rebuilds and revalidates the normalized draft; it must not mutate a
saved `PatternDocument` in place. Save the approved corrections as import
provenance only if they are small, versioned, and safe to retain.

## Security, reliability, and execution model

- Run orchestration in a background isolate. Keep non-sendable engine handles
  inside a platform worker or native process boundary where required.
- Enforce time, memory, object, decoded-stream, raster-pixel, and crop limits
  at every adapter boundary; check cancellation frequently.
- Disable PDF JavaScript, launch actions, external URLs, embedded files,
  attachments, forms/XFA execution, and arbitrary font code. Never invoke a
  system shell, network resource, or external viewer for PDF content.
- Treat native crashes, corrupted images/fonts, unsupported codecs, cyclic
  references, and decompression bombs as recoverable import failures.
- Log only redacted parser version, engine version, capability code, bounded
  measurements, and non-sensitive diagnostic identifiers. Never log bytes,
  page images, full extracted text, or local paths.
- Release native image/PDF resources deterministically between pages and erase
  transient rendered crops when a session ends or is cancelled.

## Test, corpus, and quality gates

Build a legally usable corpus covering vector-native, scanned, color,
black-and-white, rotated, low-resolution, multi-page, mixed-modality, and
intentionally difficult patterns. Include PDF feature cases: missing/incorrect
`ToUnicode`, Type 0/CID and Type 3 fonts, custom CMaps, private-use symbols,
object streams, incremental and linearized PDFs, clipping/transparency/masks,
RGB/CMYK/ICCBased/Indexed/Separation color, JPEG/JPEG2000/JBIG2/CCITT images,
annotations, forms, layers, signatures, attachments, malformed xrefs, and
encrypted/password-protected files.

Add these test layers:

1. Pure unit tests for each evidence transform, confidence calculation, parser
   policy, normalization, and diagnostic mapping.
2. Fake-engine contract tests proving orchestration behavior, resource limits,
   cancellation, and adapter error containment.
3. Golden parser tests comparing expected legends, dimensions, joins, sampled
   cells, regions, diagnostics, and document JSON while avoiding brittle
   full-document snapshots where identifiers are intentionally versioned.
4. Differential tests that compare selected engine versions/adapters on the
   same corpus before upgrades.
5. Target integration tests for actual extraction/rendering/OCR and a complete
   import-review-save-reopen flow.
6. Fuzz and hostile-input tests for malformed PDFs, excessive streams, images,
   nesting, and cancellation during every expensive stage.

Track cell accuracy, legend accuracy, splice accuracy, false-positive cell
rate, unresolved-cell rate, processing time, peak memory, failures by feature,
and correction rate. Set numeric acceptance thresholds only after baseline
measurement on representative desktop and mobile hardware; require no
regression against the approved corpus without a documented reason.

## Delivery sequence

1. Phase 0 contracts, fake engine, limits, and corpus manifest.
2. Engine evaluation, licensing decision, and adapter spike on all targets.
3. Input/extraction pipeline and capability diagnostics.
4. Region classification and vector-first legend parsing.
5. Grid calibration and single-page vector symbol interpretation.
6. Raster rendering/OCR and raster symbol fallback.
7. Multi-panel/page splicing, provenance, and backstitch extraction.
8. Normalization, persistence handoff, and review-session integration.
9. Corpus expansion, cross-platform differential tests, performance hardening,
   security testing, license notices, and release-profile documentation.

Each milestone must leave the viewer usable with hand-authored fixtures. Do not
block renderer or interaction work on parser completeness.

## Definition of done

Step 6 is complete when a supported PDF can be parsed off the UI thread on all
target platforms, produce a validated and portable `PatternDocument` with
legend mappings, grid dimensions, source regions, per-cell provenance, and
diagnostics, and flow through review into persistence without reparsing on
reopen. Unsupported, unsafe, malformed, or uncertain input must remain
responsive, cancelable, redacted in logs, and explicitly explain what the user
can review or why import cannot continue.

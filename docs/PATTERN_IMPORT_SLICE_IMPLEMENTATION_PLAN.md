# Pattern Import Slice — Implementation Plan

## Decision and slice boundary

Implement the first usable import path for StitchScope's **normalized pattern
JSON document**, not PDF parsing. The library already has a prominent Import
pattern affordance, a validated immutable `PatternDocument` graph, and a
transactional persistence path. It does not yet have a portable JSON codec or
a PDF extraction/parser implementation. Treating a PDF as importable at this
point would create a UI promise with no trustworthy document-producing path.

The completed slice will let a user choose a `.stitchscope.json` file, validate
and preview its normalized document, add it to the local library without
silently replacing an existing pattern, and open it in the workspace. PDF
selection, parsing, source previews, corrections, export, progress import, and
re-import/merge behavior are deliberately out of scope.

The slice preserves the current architecture:

```text
Library Screen
  -> Flutter file-picker adapter
  -> ImportNormalizedPattern use case
  -> PatternDocumentJsonCodec + PatternDocument.validate()
  -> review confirmation -> PatternDocumentRepository.save() transaction
  -> library refresh / workspace route
```

No domain type may import Flutter, `file_picker`, `dart:io`, or a persistence
implementation. The picker only supplies a name and bytes; the application
use case owns all policy and returns UI-neutral outcomes.

## Existing integration points and constraints

- `LibraryScreen` already exposes both entry points (the app-bar action and
  empty-library button), but `_showImportComingSoon` only shows a snack bar.
- `PatternDocumentRepository.save` validates and replaces documents sharing an
  ID. Therefore the import workflow must detect collisions before calling
  `save`; direct use from the screen could otherwise overwrite imported data
  while retaining unrelated progress.
- `DriftPatternDocumentRepository.save` is already transactional, validates
  before modifying rows, and creates library metadata for a new document. No
  database migration is required for the first JSON-only import slice.
- `PatternDocument`, `PatternGrid`, `SymbolDefinition`, `ThreadDefinition`,
  `PatternRegion`, and `ParserDiagnostic` already express the required
  normalized graph and have validation. The portable codec must preserve all
  of these values, including sparse-cell source order, diagnostics, optional
  fields, and structured `sourceMetadata`.
- The app currently seeds three development fixtures whenever its library
  screen loads. Keep that behavior unchanged in this slice, but test import
  with `LibraryScreen` constructed without seeds so the tests assert only the
  user-imported item.

## Portable file contract

Create one documented, deterministic, versioned envelope. Use the extension
`.stitchscope.json` and MIME type `application/vnd.stitchscope.pattern+json`
when a platform supports MIME filtering; also permit `application/json` and
perform validation from bytes rather than trusting the extension.

```json
{
  "format": "stitchscope.pattern",
  "formatVersion": 1,
  "document": { "...": "PatternDocument wire representation" }
}
```

`formatVersion` is the file-envelope version, separate from
`document.schemaVersion`. Decoding must require the exact `format` value and
support only envelope version 1. A newer envelope must report an actionable
"created by a newer version" error; an older or malformed envelope must not be
best-effort decoded.

### Wire representation rules

Use JSON objects/lists/numbers/booleans/null only. Keep explicit field names
and do not serialize Dart class names or `toString()` values. Encode all enums
with their existing stable lower-camel enum `name` values:

- stitch type: `full`, `half`, `quarter`, `threeQuarter`, `backstitch`,
  `frenchKnot`, `unknown`;
- color evidence: `explicit`, `inferred`;
- diagnostic severity and stage by their current enum names.

Encode coordinates as `{ "row": <int>, "column": <int> }`, dimensions as
`{ "rows": <int>, "columns": <int> }`, and confidence as a JSON number.
Encode nullable members explicitly only when non-null, except collection
members, which must always be present as ordered arrays. The document object
contains `id`, `title`, `schemaVersion`, `grid`, `symbols`, `regions`,
`sourceMetadata`, optional `sourceChecksum`, and `diagnostics`; the grid
contains `dimensions` and `cells`.

The encoder must produce a stable key/order layout suitable for committed test
fixtures. The decoder must reject missing required values, null where a
non-null value is required, wrong JSON types, non-integral coordinate values,
unknown enum values, malformed colors, and unsupported metadata values. Once a
wire graph is decoded, call `PatternDocument.validate()` to enforce
cross-reference, coordinate-bound, duplicate-cell, and provenance invariants.
Do not silently drop unknown fields or invalid cells. Initially reject unknown
top-level/document fields so format evolution must be intentional; record that
compatibility policy next to the codec.

## Proposed implementation sequence

### 1. Add pure-Dart codec and typed import outcomes

1. Add `lib/domain/pattern_document_json_codec.dart` with a
   `PatternDocumentJsonCodec` that has `encode(PatternDocument)` and
   `decode(String)` methods. Keep its private JSON readers small and typed
   (`_requiredString`, `_requiredInt`, `_optionalString`, `_requiredList`,
   enum readers) so error messages name the failing JSON path, such as
   `document.grid.cells[12].symbolId`.
2. Add a domain-specific format exception in `domain_error.dart` (or a focused
   codec-error file) carrying a safe message and source path. Do not expose
   raw file contents or parser stack traces in its `toString`/UI message.
3. Add `lib/application/import_normalized_pattern.dart`. Define:
   - `ImportNormalizedPattern`, constructed with `PatternDocumentRepository`;
   - `prepareBytes({required Uint8List bytes, required String sourceName})`;
   - `savePrepared(PreparedNormalizedPattern candidate)`;
   - a sealed preparation result hierarchy for `ready`, `duplicate`, and
     `rejected`;
   - a rejection reason enum that distinguishes unreadable UTF-8, invalid JSON,
     unsupported format/version, invalid document, duplicate ID, and save
     failure.
4. `prepareBytes` decodes UTF-8 with malformed-input reporting, calls the
   codec, and checks `getById(document.id)`. If an ID already exists, it returns
   a duplicate outcome and leaves documents and progress untouched. Only
   `savePrepared`, invoked after the UI confirmation, calls `save`; it must
   recheck the ID to close a concurrent-import race. Do not use `save` as an
   upsert in this import flow.
5. Do not mutate the imported graph to add a filename, current time, or a local
   ID. It is a portable immutable document. The repository's library metadata
   already records local import timing; a later provenance schema slice can
   introduce a dedicated source-file record if retaining filename/checksum is
   required.

### 2. Add the Flutter selection adapter

1. Add the `file_picker` Flutter dependency without granting broad storage
   permissions. Configure it to request custom extensions `stitchscope.json`
   and `json`, and request in-memory bytes (`withData: true`). The app needs no
   `dart:io` read path for this slice.
2. Add `lib/infrastructure/import/file_picker_pattern_source.dart`, which
   translates the plugin result into a small application-facing value containing
   only display name and `Uint8List`. If the platform reports a selected file
   without bytes, return a typed source-read failure instead of reaching into a
   platform path.
3. Keep plugin exceptions and cancelled selection distinct: cancellation is a
   normal no-op; picker/plugin failures become a safe `rejected` result.
4. Inject an `ImportPatternSource` interface and `ImportNormalizedPattern` into
   `LibraryScreen` through optional required-at-composition dependencies rather
   than constructing plugins inside widgets. Update `AppDependencies` to create
   the production use case/source, and keep lightweight fake implementations in
   tests. This makes widget tests deterministic and lets desktop/mobile picker
   behavior be tested independently.

### 3. Replace the placeholder with the import flow

1. Replace `_showImportComingSoon` with one async handler shared by the app-bar
   and empty-state controls. Prevent concurrent imports by tracking an
   `_isImporting` state; disable both controls while selection, validation, or
   saving is active.
2. On selection cancellation, restore controls without a notification. On a
   typed rejection, show an accessible error dialog containing the filename,
   concise reason, and a `Choose another file` action. For a duplicate, show a
   non-destructive message naming the existing pattern and offer only `Close`
   in this slice.
3. Between successful decode and persistence, show a modal review dialog with
   title, dimensions, populated-cell count, symbol count, region count, and
   warning/error diagnostic counts. The user selects `Add to library` or
   `Cancel`; cancel must perform no write. Blocking `error` diagnostics may be
   displayed but are not separately reinterpreted by the UI because document
   validation remains the import gate.
4. After confirmation and a successful `savePrepared`, refresh `_summaries`, show an
   "Imported <title>" confirmation, and immediately navigate to
   `PatternWorkspaceScreen` for the imported ID. Await navigation before
   re-enabling/reloading as needed so a failed push cannot leave stale controls.
5. Keep import text honest: use “Import StitchScope pattern” in this first
   slice, update the empty-state supporting copy, and reserve generic/PDF
   wording for the later parser-backed import implementation.

### 4. Preserve boundaries and UX details

- Use `mounted` checks after every await before calling `setState`, a navigator,
  or a messenger.
- Make all buttons and dialogs keyboard reachable; add semantic labels for the
  busy state and progress indicator.
- Keep decoded bytes only for the duration of the operation. Do not log the
  content, store a raw copy, or surface JSON excerpts in error text.
- Retain the current seeded sample behavior and library ordering. The newly
  saved document will use the repository's existing imported-at metadata.
- Ensure every newly introduced Dart declaration has the repository-required
  documentation comment.

## File-level change list

| Path | Change |
| --- | --- |
| `pubspec.yaml` | Add the cross-platform picker dependency and run dependency resolution. |
| `lib/domain/pattern_document_json_codec.dart` | Add the versioned envelope codec and strict decode helpers. |
| `lib/domain/domain_error.dart` | Add the safe, typed normalized-format error if a focused codec exception is not preferable. |
| `lib/application/import_normalized_pattern.dart` | Add use case, source interface/value, results, rejection reasons, collision check, and save policy. |
| `lib/infrastructure/import/file_picker_pattern_source.dart` | Add the `file_picker` implementation of the source boundary. |
| `lib/app/app_dependencies.dart` | Compose the production picker and import use case. |
| `lib/app/stitch_scope_app.dart` | Pass import dependencies into the library route. |
| `lib/presentation/screens/library_screen.dart` | Replace the placeholder with selection, review, confirmation, errors, busy state, refresh, and workspace navigation. |
| `test/domain/pattern_document_json_codec_test.dart` | Add serialization, golden, and invalid-wire-contract coverage. |
| `test/application/import_normalized_pattern_test.dart` | Add outcome/persistence policy coverage using the in-memory repository. |
| `test/presentation/screens/library_screen_test.dart` | Add picker/use-case-driven widget coverage for the visible flow. |
| `test/domain/fixtures/*.stitchscope.json` | Add valid and intentionally invalid portable fixtures; use only non-sensitive, hand-authored test data. |
| `docs/IMPLEMENTATION_PLAN.md` | Mark the portable normalized-import slice complete only after implementation and validation; leave PDF import unchecked. |

## Test plan and acceptance criteria

### Codec tests

1. Encode/decode the representative, large, and extra-large fixtures and assert
   every domain field survives, including optional values, metadata nesting,
   source checksum, sparse cell order, provenance, confidence, and diagnostics.
2. Compare a canonical encoded fixture against a committed JSON golden file.
3. Assert rejection for malformed JSON; non-object roots; bad format; missing
   or future `formatVersion`; missing required fields; wrong primitive types;
   fractional/negative dimensions and coordinates; invalid enum values; invalid
   color text; duplicate cells; missing symbols/regions; out-of-bounds cells;
   and invalid provenance references.
4. Verify decoder errors identify a field path but never include the complete
   JSON source.

### Use-case tests

1. A valid byte stream produces `ready` without a write; saving the prepared
   candidate calls `save` once and can be loaded from the repository as the
   same document.
2. Malformed UTF-8, decode failure, validation failure, and repository failure
   return their distinct rejected outcomes and write nothing.
3. An existing identical or differing document ID returns `duplicate`, performs
   no save, and preserves its existing document and progress snapshot.
4. A user-cancelled review is tested at the UI layer and never invokes
   `savePrepared`.

### Widget tests

1. Both import controls invoke the supplied fake source.
2. Picker cancellation restores the enabled controls and shows no error.
3. A valid selection shows the review values; `Cancel` leaves the library
   unchanged; `Add to library` refreshes the list and opens the workspace.
4. Invalid, unsupported-version, read, save, and duplicate results show clear
   recoverable UI without navigation or stale busy indicators.
5. Assert all new controls have discoverable labels/keys and that rapid taps do
   not start concurrent imports.

Run `dart format .`, `flutter analyze`, and focused domain/application/widget
tests, followed by `flutter test`. Perform a manual smoke test on at least one
desktop and one mobile target: choose a valid file, cancel at each stage,
attempt invalid/future-version/duplicate files, import successfully, close and
reopen the app, and confirm the document persists and opens normally.

## PDF parsing and import slice

Build the PDF capability as a second, separately releasable import path after
the normalized-file path above. It must produce the same `PatternDocument`
that the viewer and repository already consume; no screen, painter, or Drift
table should depend on PDF engine objects. The initial PDF release has a
deliberately narrow supported profile: unencrypted, locally selected PDFs with
native text/vector grid content, one recognizable legend, and one or more
axis-aligned grid regions that can be placed in a common coordinate system.

Scanned-only PDFs, bitmap-only symbols, encrypted/password-protected files,
OCR, arbitrary page layouts, editable correction, and server-side parsing are
not part of the first parser release. They must receive a specific diagnostic
instead of a guessed document. This boundary lets the team establish parser
accuracy against a small golden corpus before adding probabilistic recognition.

### PDF architecture

```text
PDF picker bytes
  -> ImportPdfPattern use case (limits, checksum, lifecycle, cancellation)
  -> PdfPatternParser interface
       -> PdfDocumentEngine adapter (native PDF engine behind FFI/platform code)
       -> extraction model (pages, text spans, paths, images, transforms)
       -> page/region classifier
       -> legend parser + grid calibrator + symbol interpreter + splicer
       -> ParseResult (PatternDocument candidate + structured diagnostics)
  -> review dialog/screen
  -> PatternDocumentRepository.save()
  -> library / workspace
```

Create parser-domain DTOs that are pure Dart and deliberately lower-level than
`PatternDocument`: `ExtractedPdfDocument`, `ExtractedPdfPage`, `PdfTextSpan`,
`PdfPath`, `PdfImageRegion`, `PdfTransform`, and an immutable
`PdfEngineCapabilities`. Coordinates must retain the original PDF page space
and rotation; all parsing stages must record enough source-page/region evidence
to construct the existing `PatternRegion` and `ParserDiagnostic` values.

Define these narrow interfaces in `lib/parser/` (or a nested pure-Dart parser
package if introduced during implementation):

- `PdfDocumentEngine.open(Uint8List bytes, PdfParseLimits limits)`, which
  performs safe structural inspection and produces extraction data but never
  executes PDF actions, JavaScript, links, attachments, or forms;
- `PdfPatternParser.parse(...)`, returning a `Stream<PdfParseEvent>` followed
  by exactly one typed terminal result (`success`, `needsReview`, `unsupported`,
  `rejected`, `cancelled`, or `failed`);
- `ParserCancellationToken`, owned by the application layer and checked between
  every expensive stage; and
- a test-only fake parser/engine, so domain/application tests never need a
  native PDF binary.

The stream supports user-facing phases (`inspecting`, `extracting`,
`classifying`, `readingLegend`, `calibratingGrid`, `interpretingSymbols`,
`splicing`, `validating`) with bounded progress only where a denominator is
known. Do not invent percentage progress for an open-ended stage. The terminal
result carries the candidate only after it passes `PatternDocument.validate()`.

### Engine-selection and packaging gate

Before implementing the production adapter, perform a short spike comparing
PDFium, MuPDF, and Poppler (or another mature engine) against the target
platforms. Record extraction fidelity for native text, Type 0/CID and Type 3
fonts, vector paths, images, rotations, clipping, and color spaces; licensing;
binary size; build/FFI complexity; crash behavior; and Android/iOS/Windows/
macOS/Linux availability. Select one engine only when it can meet the initial
profile on every supported target and its license fits the application.

The selected engine is an implementation detail behind `PdfDocumentEngine`.
Pin its version, package the binaries with the app, expose engine/version and
capability data only in redacted diagnostics, and add a CI smoke test for every
target. If an engine lacks a target, return an explicit unavailable-capability
result on that target; do not silently choose a different parsing algorithm.

### PDF parse pipeline

1. **Admission and resource guard.** Enforce configurable limits before and
   during open: allowed PDF header/structure, file bytes, page count, object
   count, recursion/nesting, decompressed stream bytes, render DPI, image pixel
   count, elapsed time, and memory. Reject encryption/password requirements,
   malformed cross references, unsupported features, and active content safely.
   Calculate SHA-256 while the bytes are in memory; retain only the checksum,
   file display name, page count, parser version, and engine capability summary
   in `sourceMetadata`, never the raw PDF.
2. **Extraction.** Extract page size, effective rotation, native text spans
   (text, font identity, bounds, transform), vector path geometry/styling, and
   image regions. Normalize transforms into a top-left page coordinate system
   while retaining original coordinates for evidence. If any required source
   modality cannot be extracted, emit a stage-specific diagnostic.
3. **Page and region classification.** Score page regions as grid, legend,
   cover/instructions, continuation, or unknown from geometry and native text.
   Permit a page to contain both a legend and grid. An ambiguous classification
   is a review/unsupported result, not an implicit selection.
4. **Legend parsing.** Identify tabular rows from aligned text/path boundaries;
   extract a symbol, brand, catalog number, name, and color when present;
   normalize whitespace and Unicode; and construct `SymbolDefinition`/
   `ThreadDefinition` records with `explicit` versus `inferred` evidence. Flag
   duplicate symbols, missing mappings, and contradictory colors. Preserve
   short source evidence in the existing `legendEvidence` field.
5. **Grid calibration.** Detect repeated horizontal/vertical rules and labels,
   infer cell pitch/origin/orientation, then verify dimensions against labels
   and region extents. Support only axis-aligned grids in this release. Reject
   skewed/raster layouts and grids whose residual alignment error exceeds the
   documented threshold.
6. **Symbol interpretation.** Prefer native text or vector glyph identity.
   Build a document-local symbol vocabulary from the legend, map each populated
   calibrated cell to that vocabulary, and emit per-cell confidence and
   `needsReview` for low-confidence or unrecognized cells. Do not fabricate
   stitches in empty cells. Low-confidence cells may create a candidate only if
   all structural invariants remain valid; unknown symbol IDs require a defined
   placeholder symbol with inferred thread data and a blocking diagnostic.
7. **Multi-page splicing.** For each accepted grid region, derive its global
   offset using row/column labels, continuation labels, overlap cells, and
   page order. Create a `PatternRegion` for every source panel. Verify overlap
   cells agree, detect gaps/reversed orientation/conflicts, and fail closed on
   an unresolvable join. Do not merely concatenate page dimensions.
8. **Output validation.** Validate symbol coverage, coordinate continuity,
   region bounds, referenced diagnostics, colors, and the completed
   `PatternDocument`. Emit all non-fatal findings in its `diagnostics` list;
   return fatal conditions as typed terminal outcomes with a user-safe reason.

### PDF application and review UX

1. Extend the picker adapter to admit `.pdf` and offer two explicit choices:
   “Import StitchScope pattern file” and “Import PDF pattern.” Keep the source
   type visible so users do not expect a PDF to be accepted by the JSON codec.
2. Add `ImportPdfPattern` as an application use case constructed from the
   parser, document repository, checksum service, clock, and injected document
   ID factory. The ID factory makes parser tests deterministic. A successfully
   parsed PDF receives a new local document ID; the original source checksum is
   retained in `PatternDocument.sourceChecksum` and metadata. It must not
   replace an existing document merely because its source filename matches.
3. Before saving, compare source checksums through a repository query designed
   for this purpose (add `findBySourceChecksum` rather than scanning summaries).
   If the checksum already exists, report an existing import and offer `Open
   existing`. Re-import/replacement and progress migration remain deferred.
4. Use a dedicated modal import-progress route with phase text, indeterminate
   or bounded progress, a Cancel action, and a safe error state. Disable exit
   paths that could leave a parser event subscription orphaned; dispose the
   subscription and signal cancellation when the route is dismissed.
5. On `success` or `needsReview`, open a review screen before persistence. Show
   title, dimensions, populated cells, parsed symbol/thread counts, pages and
   grid regions, capability warnings, and diagnostics grouped by severity and
   stage. Provide source-page/region and global-cell links where coordinates
   exist. The first release allows only `Save to library` or `Cancel`; it does
   not let users edit parser output.
6. A result containing any fatal error, unsupported feature, or ambiguous
   structural page join cannot reach Save. A candidate with warnings can be
   saved only after the user confirms the warning summary. On save, use the
   same repository transaction and workspace navigation flow as JSON import.

### PDF testing, corpus, and release gates

1. Create a legally usable, version-controlled corpus with a manifest that
   identifies each file, source class, expected page/region arrangement,
   dimensions, legend mappings, sampled cell values, and known diagnostics.
   Include native-vector single page, multi-page continuation, rotated page,
   missing legend field, unsupported encryption, malformed PDF, clipped/vector
   symbol, and a scan/raster file that is explicitly rejected by the initial
   profile.
2. Unit-test every parser stage against extracted-model fixtures, without an
   engine. Test grid transformations, legend row association, symbol vocabulary
   matching, page offsets, overlap conflict detection, diagnostics, cancellation,
   limits, and document construction.
3. Run engine integration/golden tests against the corpus on each target.
   Compare dimensions, regions, symbol/thread mappings, selected cells,
   diagnostics, and outcome category; do not compare engine-specific raw text
   ordering unless it is part of the adapter contract.
4. Add application/widget tests with a scripted parser stream to verify phase
   progress, cancellation, review gating, duplicate-checksum opening, fatal
   rejection, warning confirmation, successful persistence, and no navigation
   before a completed save.
5. Establish measured initial thresholds per corpus category (legend accuracy,
   sampled-cell accuracy, page-splice accuracy, unresolved-cell rate, runtime,
   and peak memory). A corpus regression blocks release; it must be classified
   as a deliberate supported-profile change rather than hidden by a lower
   threshold.

### PDF file-level plan

| Path / area | Change |
| --- | --- |
| `lib/parser/` | Add pure-Dart parser contracts, extracted PDF model, limits, events, cancellation, pipeline stages, and test fakes. |
| `lib/infrastructure/pdf/` | Add the selected engine adapter and its platform build/package configuration behind `PdfDocumentEngine`. |
| `lib/application/import_pdf_pattern.dart` | Add checksum/duplicate policy, parser orchestration, review candidate, cancellation, and persistence outcomes. |
| `lib/domain/repositories.dart` and Drift repository | Add targeted checksum lookup and tests; no raw-PDF storage. |
| `lib/infrastructure/import/` | Extend source selection with an explicit PDF path and typed selected source kind. |
| `lib/presentation/screens/` | Add source-choice, progress, and parser-review UI; update library import entry points. |
| `test/parser/`, `test/application/`, `test/presentation/` | Add unit, fake-engine, use-case, and widget coverage described above. |
| `test/parser/corpus/` and `docs/pdf-capability-matrix.md` | Add controlled corpus/manifest, expected results, supported-profile matrix, licensing/provenance notes, and engine comparison decision record. |

## Deferred decisions

- Portable progress export/import stays separate from document import so a
  pattern file cannot unexpectedly modify user completion, markers, or viewport
  state.
- Re-import and replacement require an explicit conflict-resolution design:
  source checksum comparison, stable-cell compatibility checks, progress
  preservation/review, and an opt-in replacement action. Do not infer that
  behavior from the current repository's low-level replacement semantics.
- OCR/raster-symbol support is a later parser profile. It will need bounded
  rendering, a pattern-specific symbol classifier, OCR confidence/evidence,
  visual correction UI, and separate corpus thresholds; it must not weaken the
  deterministic vector-native profile.
- Signed packages and compression can be added in a later normalized-file
  format version once the initial interoperable JSON fixture corpus exists.

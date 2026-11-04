# Cross Stitch Pattern Viewer — Implementation Plan

## Project name: StitchScope

## 1. Product objective

Build a cross-platform Flutter application that can import a cross-stitch pattern, render it clearly at any scale, help the user mark completed stitches, expose thread information, highlight related colors, and preserve the user's location and progress. A separate PDF-processing stack will convert supported pattern PDFs into a normalized pattern document that the viewer can consume.

The current repository is a new Flutter application. The implementation should keep the viewer and parser as independent layers so the parser can be tested, evolved, and eventually packaged with the compiled Android, iOS, Windows, macOS, and Linux applications without platform-specific parsing logic.

## 2. Guiding decisions

- Use Flutter/Dart for the application and shared domain code.
- Keep all core pattern, progress, selection, highlighting, marker, and parser-domain logic platform-independent Dart.
- Treat parsed pattern data as a versioned, portable document format rather than passing UI-specific objects from the parser to the viewer.
- Prefer deterministic, explainable parsing steps and confidence/error reporting over opaque image-recognition behavior.
- Perform parsing off the UI isolate and persist imported documents and progress locally.
- Make imported source files immutable; store normalized pattern data and user state separately so progress survives re-imports and application upgrades.

## 3. Proposed architecture

```text
Flutter UI
  ├─ Pattern workspace (grid renderer, controls, selection, markers)
  ├─ Import/review flow (PDF/file picker, parse progress, warnings)
  └─ Progress/thread panels

Application layer
  ├─ ImportPattern use case
  ├─ UpdateProgress use case
  ├─ Select/highlight use cases
  └─ Marker and viewport state

Domain layer
  ├─ PatternDocument, PatternPage, PatternGrid
  ├─ StitchCell, SymbolDefinition, ThreadDefinition
  ├─ ProgressState, LocationMarker, ViewportState
  └─ Parser diagnostics and confidence values

Infrastructure layer
  ├─ PDF parser pipeline
  ├─ Document/progress repositories
  ├─ File-system and PDF adapters
  └─ Isolate/background execution adapters
```

Suggested project structure:

```text
lib/
  app/
  domain/
  application/
  presentation/
  infrastructure/
  parser/
test/
  domain/
  application/
  parser/
  presentation/
integration_test/
```

The exact state-management package can be selected during the foundation phase. Whichever package is chosen, domain and parser packages must not depend on Flutter widgets.

## 4. Core domain model

Define and serialize these concepts before building the renderer:

- `PatternDocument`: stable ID, title, source metadata, schema version, dimensions, pages/regions, symbols, threads, grid data, parser diagnostics, and optional source checksum.
- `StitchCell`: row, column, symbol ID, thread/color ID, stitch type, and optional confidence/ambiguity flags.
- `SymbolDefinition`: source symbol, normalized symbol key, display glyph, associated thread, and any legend evidence.
- `ThreadDefinition`: brand, catalog number, name, color value, conversion notes, and whether the color was explicitly read or inferred.
- `ProgressState`: completed cells, optional partial/needs-review state, last opened viewport, and last interaction time.
- `LocationMarker`: ID, row/column or region coordinate, label, color, opacity, visibility, and optional note.
- `ViewportState`: zoom, pan, visible bounds, and a stable anchor cell for restoring the view.
- `ParserDiagnostic`: severity, stage, message, affected page/region/cell, confidence, and suggested correction.

Use a sparse representation for empty cells and a compact representation for populated cells. The model must support multi-page patterns without requiring the UI to know how pages were spliced.

## 5. Viewer implementation plan

### Phase 1 — Foundation and domain contracts

1. [x] Replace the starter app with a basic application shell and navigation, and establish Drift as the app's local persistence stack. Drift/SQLite dependencies, the database lifecycle boundary, development configuration, migrations, and an in-memory test database are present. Repository interfaces keep persistence outside the domain layer.
2. [x] Add the domain models, schema versioning, and repository interfaces. Symbols now embed their exact thread definition; cells reference only their symbol.
3. [ ] Add versioned JSON serialization and portable import/export codecs for the normalized document and progress graphs.
4. [ ] Add sample normalized pattern fixtures, including empty cells, multiple colors, page boundaries, symbols, and malformed/ambiguous cells.
5. [x] Implement Drift adapters for documents and progress. Document, progress, marker, viewport, provenance, diagnostics, and metadata are mapped through separate tables. Saves replace each graph atomically, and the document/progress graphs remain independent.
6. [x] Add focused unit, repository round-trip, foreign-key, rollback, deletion-cascade, and schema-migration tests. Schema version 3 migrates prior thread catalog data into symbol-owned thread definitions.
7. [ ] Validate production persistence on Android, iOS, Windows, macOS, and Linux; add file-picker and state-management boundaries after those checks.
8. [ ] Add project-wide formatting, linting, test, migration-test, and CI commands.

Exit criteria: a fixture can be loaded through a repository backed by Drift, persisted and reopened through SQLite, and round-tripped through the versioned portable serialization format on every target platform.

### Next slice — Fixture-backed library and workspace entry

Create one representative hand-authored `PatternDocument` fixture and a small application composition root that opens `AppDatabase` and injects the two Drift repositories. Update the library screen to seed the fixture only when the local library is empty, list repository summaries, and open a placeholder workspace route for a selected document.

This slice establishes the real application data path before canvas work: fixture → document repository → library list → document load → workspace route. It should include widget tests for empty and populated library states plus repository integration coverage for reopening persisted data. Keep PDF/file import, portable JSON codecs, and state-management package selection outside this slice.

### Phase 2 — Pattern workspace and rendering

1. Implement a zoomable/pannable canvas with a clear grid and stable row/column coordinates.
2. Render only the visible region when patterns are large; avoid one widget per stitch.
3. Render symbols, optional color fills, completed-stitch overlays, and page/region boundaries through a custom painter or equivalent batched renderer.
4. Add fit-to-pattern, fit-to-selection, reset viewport, and viewport restoration.
5. Ensure touch gestures work on mobile and mouse/trackpad/wheel interactions work on desktop.
6. Add accessibility labels and non-color cues for symbols and completion state.

Exit criteria: a large fixture remains responsive while zooming and panning, and the same normalized data produces equivalent results on mobile and desktop.

### Phase 3 — Interaction and progress

1. Select a stitch by tapping/clicking; show row/column, symbol, thread brand/number/name/color, and parser confidence where applicable.
2. Support marking one or many selected stitches complete and undo/redo for progress changes.
3. Support clear/unmark, bulk completion for a selection, and optional filtering of completed stitches.
4. Highlight all stitches sharing the selected color/thread, with a legend entry and count.
5. Add transparent, movable location markers that can be created, renamed, recolored, hidden, deleted, and persisted.
6. Save progress incrementally and restore it when reopening a document.
7. Define behavior for edits after a pattern is re-imported: match by stable cell coordinates and source checksum when safe, otherwise require review.

Exit criteria: a user can complete a representative section, close/reopen the app, return to the same viewport, and see progress, selected thread, highlights, and markers intact.

### Phase 4 — Import UX and document management

1. Add file import for supported PDF files and, where useful, a normalized pattern file for debugging and future integrations.
2. Show parsing stages, progress, cancelation, warnings, and a review screen before saving the imported pattern.
3. Display page previews and diagnostics linked to affected areas.
4. Allow the user to correct unresolved symbols, thread mappings, orientation, or page alignment before finalizing.
5. Add a recent-pattern library with rename, delete, duplicate/export, and storage-size handling.

Exit criteria: a user can import a PDF, review any warnings, correct supported ambiguities, open it in the viewer, and later reopen it without reparsing.

## 6. PDF-parsing stack

The parser should be a separately testable pipeline with a narrow API such as:

```dart
Future<ParseResult> parsePatternPdf(
  Uint8List bytes,
  ParserOptions options,
);
```

`ParseResult` should contain either a normalized `PatternDocument` or structured diagnostics that identify what needs review. Do not make parser success a boolean-only outcome.

### Parser stages

1. **Input and security checks**
   - Validate file type, size, page count, encryption status, and readable PDF structure.
   - Keep source bytes out of logs and do not execute embedded content.

2. **PDF extraction**
   - Extract page dimensions, text spans, vector paths, embedded images, fonts, annotations/forms where supported, and coordinates using a mature PDF engine exposed through a portable library or a small native adapter behind a Dart interface.
   - Preserve the engine capability report and explicitly record unsupported or omitted PDF features in parser diagnostics.
   - Preserve page coordinate systems and rendering resolution for later diagnostics.

3. **Page classification**
   - Classify pages and regions as cover, instructions, legend, grid, continuation, or unknown.
   - Treat a page as potentially mixed-modality: native text/vector content, raster content, OCR text, annotations, and embedded symbol images may coexist.
   - Use text and layout evidence first; use raster analysis and OCR only where semantic extraction is absent, unreliable, or contradicted by visual evidence.

4. **OCR and raster evidence**
   - Distinguish native PDF text extraction, extraction of an existing OCR text layer, new OCR over rendered image regions, and visual symbol classification.
   - Use OCR for scanned legends, row/column labels, page continuation labels, thread numbers/names, and rotated or low-quality text where no reliable text layer exists.
   - Render raster regions at controlled, bounded resolutions; retain the source crop, transformation, OCR confidence, and recognition evidence for review.
   - Do not treat OCR output as authoritative. Preserve uncertainty and cross-check OCR against geometry, legend structure, known thread identifiers, and visual evidence.

5. **Thread legend parsing**
   - Detect legend tables and associate symbol, thread brand, catalog number, name, and color columns by geometry and text labels.
   - Normalize whitespace, Unicode symbols, color formats, and brand aliases.
   - Preserve the original legend text and confidence for each mapping.
   - Flag duplicate symbols, missing thread IDs, conflicting colors, and inferred mappings.

6. **Grid detection and calibration**
   - Detect grid lines, cell boundaries, row/column labels, orientation, and scale.
   - Determine whether the page contains one grid, multiple panels, or a continuation section.
   - Use known labels and repeated spacing to correct skew, scaling, and small scan distortions.

7. **Symbol interpretation**
   - Prefer extracted vector/text symbols when available.
   - For raster scans, render at a controlled resolution, segment cells, normalize each symbol crop, and compare against a pattern-specific symbol vocabulary.
   - Keep unknown and low-confidence cells instead of silently assigning a color.

8. **Multi-page splicing**
   - Match adjacent pages using row/column labels, overlap, grid spacing, continuation markers, and edge geometry.
   - Build a single global coordinate system and retain provenance from global cells back to source page/region/crop.
   - Detect duplicate overlap cells, gaps, conflicting symbols, reversed order, and missing pages.

9. **Validation and output**
   - Validate dimensions, coordinate continuity, legend references, symbol coverage, color mappings, and page provenance.
   - Emit diagnostics with severity and confidence.
   - Serialize a versioned normalized document that the viewer can consume without PDF dependencies.

### Parser quality strategy

- Build a golden corpus of legally usable PDFs: vector-native, scanned, color, black-and-white, multi-page, rotated, low-resolution, and intentionally difficult examples.
- Store expected legend mappings, grid dimensions, page joins, and sampled cell interpretations.
- Measure cell accuracy, legend accuracy, page-splice accuracy, false-positive cells, unresolved-cell rate, and processing time/memory.
- Require a review workflow for uncertain output; never hide uncertainty behind a guessed stitch.
- Add differential tests when parser libraries or platform adapters change.
- Maintain a PDF capability matrix covering at least native text, missing/incorrect `ToUnicode` maps, Type 0/CID and Type 3 fonts, custom CMaps, symbol/private-use fonts, object streams, compressed streams, malformed cross-reference data, incremental updates, linearized files, rotations, transparency, clipping, masks, patterns, DeviceRGB/CMYK/ICCBased/Indexed/Separation colors, JPEG/JPEG2000/JBIG2/CCITT images, annotations, forms/XFA, layers, attachments, signatures, and encrypted/password-protected files.
- Test mixed pages in which the grid, legend, symbols, and labels use different PDF modalities rather than classifying only at whole-page granularity.
- Define an explicit supported-PDF profile for release. “PDF” alone is not a sufficient compatibility promise; unsupported features must produce actionable diagnostics or a safe review path.

## 7. Portability and packaging

- Keep the parser API and normalized document format in a pure Dart package under the repository, with the option to split it into a package later.
- Keep Dart responsible for Flutter integration, parser orchestration, normalized models, diagnostics, persistence, and review UI; do not reimplement a complete PDF engine in application-level Dart.
- Isolate any platform-specific PDF implementation behind interfaces. Prefer a mature engine with builds for all targets; if a native dependency is unavoidable, provide Android/iOS/Windows/macOS/Linux adapters with identical behavior and a documented build matrix.
- Evaluate native engines such as PDFium, MuPDF, and Poppler for extraction, rendering fidelity, feature coverage, licensing, binary size, build complexity, and API stability. Treat the engine choice as replaceable behind the adapter.
- Consider Rust for a memory-safer native façade or isolated parser worker, especially if resource limits and crash containment are priorities; expect FFI or bindings to remain necessary for some mature engines.
- Consider Python for offline corpus tooling, OCR experiments, differential testing, or a desktop/server worker; do not assume it is a good embedded mobile runtime without validating size, startup, packaging, and sandbox costs.
- Consider Java/Kotlin for an Android-specific adapter, Swift/Objective-C for Apple-specific PDFKit fallback behavior, and JavaScript/TypeScript with PDF.js or PDFium-WASM for web/WASM targets. None should become the canonical cross-platform parser without an identical behavior and fixture test strategy.
- Treat C/C++ as a practical native-engine implementation option because the leading engines expose native APIs, while isolating unsafe code and minimizing the FFI surface.
- Avoid dynamic runtime downloads, server-side parsing, and platform-only filesystem assumptions.
- Bundle required fonts, symbol resources, and native libraries with the application where licensing permits.
- Run parser tests in CI for each supported target and run release-mode smoke tests for Android, iOS, Windows, macOS, and Linux.
- Verify app sandbox permissions, iOS/Android file-provider behavior, Windows/macOS/Linux file paths, large-file memory limits, and offline operation.
- Record licenses and notices for PDF, image, OCR, font, and color-data dependencies.

### PDF security and resource limits

- Do not execute PDF JavaScript, actions, external links, embedded files, or other active content during parsing.
- Parse in a bounded environment where practical, with cancellation, timeouts, maximum object counts, maximum nesting depth, maximum decompressed stream size, maximum image dimensions/pixel count, maximum rendered DPI, and memory budgets.
- Handle malformed PDFs, decompression bombs, cyclic references, oversized content streams, corrupted fonts/images, unsupported encryption handlers, and password-protected documents without crashing or blocking the UI.
- Keep source bytes and extracted sensitive content out of logs. Record redacted diagnostics, parser version, engine version, and capability failures instead.
- Prefer a worker/isolate or native process boundary for parsing and OCR where supported, and treat native parser crashes as recoverable import failures.

## 8. Persistence and recovery

Use separate storage for:

1. The normalized pattern document and provenance.
2. User progress, markers, notes, and viewport state.
3. Import history, parser version, and diagnostics.

Use Drift over SQLite for the local application store. The normalized pattern document and mutable progress must remain separate at both the domain and persistence boundaries so progress updates do not rewrite imported pattern data. Index document IDs, pattern summaries, and populated grid coordinates for quick lookup; use transactions for document replacement and progress saves.

SQLite is the operational format, not the long-term backup contract. Keep the existing versioned JSON codecs as the first portable export/import format, with the option to add compressed JSON, CBOR, or another binary representation later. Export/import must include the normalized document and progress as logically separate records, plus checksums and schema versions where needed.

Writes should be atomic or journaled, with Drift migration code for schema changes. Test interrupted writes, corrupt databases and export files, duplicate imports, migration from each supported schema version, and insufficient storage.

## 9. Testing and acceptance criteria

### Automated tests

- Domain serialization, migrations, coordinate transforms, selection, highlighting, progress, markers, and undo/redo.
- Parser unit tests for each pipeline stage and failure mode.
- Golden-file parser tests across all supported PDF classes.
- Property tests for grid transforms, page splicing, and sparse/dense model equivalence.
- Widget tests for controls, diagnostics, accessibility semantics, and responsive layouts.
- Integration tests for import → review → save → reopen → progress persistence.

### Performance targets to validate

- Panning and zooming remain visually smooth on a representative large pattern.
- Parsing runs off the UI thread and provides cancelation/progress feedback.
- Opening an already normalized pattern is substantially faster than reparsing its PDF.
- Memory usage remains bounded for large multi-page patterns by using tiled/lazy rendering and compact cell storage.

### Definition of done for the first complete release

- A user can import a supported PDF on every target platform.
- The parser produces a normalized document with page provenance, legend mappings, grid dimensions, and diagnostics.
- The user can inspect and correct supported ambiguities before opening the pattern.
- The viewer supports selection, thread details, same-color highlighting, zoom/pan, completion tracking, and transparent location markers.
- Progress and viewport state survive restart and are recoverable from an export.
- Automated and cross-platform smoke tests pass, and all bundled dependencies have compatible licenses.

## 10. Risks and mitigations

| Risk                                             | Mitigation                                                                                       |
| ------------------------------------------------ | ------------------------------------------------------------------------------------------------ |
| PDFs vary widely in layout and quality           | Use staged evidence-based parsing, confidence scores, diagnostics, and a correction UI.          |
| Raster symbol recognition is ambiguous           | Preserve unknown cells, use pattern-specific vocabularies, and require review below a threshold. |
| Multi-page joins create silent coordinate errors | Use labels/overlap/provenance, validate continuity, and show page boundaries during review.      |
| Native PDF libraries differ by platform          | Keep adapters narrow, pin versions, build all targets in CI, and retain parser golden tests.     |
| Large patterns cause rendering or memory issues  | Use custom batched rendering, visible-region culling, compact storage, and tiled assets.         |
| Parser upgrades invalidate saved progress        | Version documents, retain stable coordinates/checksums, and provide migration/review behavior.   |
| Color-only UI is inaccessible or confusing       | Always show symbols, labels, thread IDs, and non-color completion/selection indicators.          |

## 11. Recommended delivery order

1. Domain model, normalized document schema, fixtures, and persistence contracts.
2. Viewer rendering with a hand-authored sample document.
3. Selection, thread panel, color highlighting, progress, and markers.
4. Cross-platform file and persistence validation.
5. PDF extraction, legend parsing, and diagnostics.
6. Grid/symbol interpretation and multi-page splicing.
7. Import review/correction flow.
8. Golden corpus, performance hardening, packaging, licensing, and release QA.

This order ensures the viewer can be validated independently while the parser is still being developed, and it keeps the parser's output contract stable enough for both in-app use and future tooling.

## 12. Potential future work

- **Example render of the finished project:** Add a polished sample pattern, screenshots, and/or an in-app demo mode showing the completed viewer experience, including zooming, progress overlays, thread details, color highlighting, and location markers. This can support documentation, onboarding, demos, and release validation without requiring the user to import a file first.
- **Cross-platform sync:** Add optional synchronization of normalized patterns, progress, markers, notes, and viewport state across Android, iOS, Windows, macOS, and Linux. Define account/authentication, conflict resolution, offline-first behavior, encryption, storage limits, and privacy expectations before implementation. Keep local-only use fully functional.
- **Additional standard pattern file types:** Extend the import layer to support other established pattern formats beyond PDF. Each format should have an adapter that converts into the same versioned `PatternDocument`, preserves source provenance and unsupported features, reports confidence/diagnostics, and uses format-specific golden fixtures. Candidate formats should be selected based on documented specifications, licensing, user demand, and cross-platform parser availability.

import 'package:drift/drift.dart';

/// Stores one normalized imported pattern and its root-level metadata.
@DataClassName('PatternDocumentRow')
@TableIndex(name: 'pattern_documents_title', columns: {#title})
@TableIndex(
  name: 'pattern_documents_source_checksum',
  columns: {#sourceChecksum},
)
class PatternDocuments extends Table {
  /// Defines the stable document identifier.
  TextColumn get id => text()();

  /// Defines the user-facing document title.
  TextColumn get title => text()();

  /// Defines the portable pattern JSON schema version.
  IntColumn get schemaVersion => integer()();

  /// Defines the total number of rows in the global pattern grid.
  IntColumn get rowCount => integer()();

  /// Defines the total number of columns in the global pattern grid.
  IntColumn get columnCount => integer()();

  /// Defines the optional checksum of the immutable imported source.
  TextColumn get sourceChecksum => text().nullable()();

  /// Uses the stable document identifier as the table key.
  @override
  Set<Column<Object>> get primaryKey => {id};

  /// Enforces root-level domain invariants inside SQLite.
  @override
  List<String> get customConstraints => const [
    'CHECK (length(id) > 0)',
    'CHECK (length(title) > 0)',
    'CHECK (schema_version > 0)',
    'CHECK (row_count > 0)',
    'CHECK (column_count > 0)',
  ];
}

/// Stores source metadata entries associated with one imported pattern.
@DataClassName('SourceMetadataEntryRow')
class SourceMetadataEntries extends Table {
  /// Defines the parent pattern document.
  TextColumn get documentId =>
      text().references(PatternDocuments, #id, onDelete: KeyAction.cascade)();

  /// Defines the metadata field name.
  TextColumn get key => text()();

  /// Defines the JSON-encoded metadata value, including strings and null.
  TextColumn get value => text()();

  /// Allows one value for each metadata key in a document.
  @override
  Set<Column<Object>> get primaryKey => {documentId, key};
}

/// Stores mutable library metadata for one imported pattern document.
@DataClassName('LibraryMetadataRow')
@TableIndex(name: 'library_metadata_last_opened', columns: {#lastOpenedAt})
@TableIndex(name: 'library_metadata_last_modified', columns: {#lastModifiedAt})
class LibraryMetadata extends Table {
  /// Defines the pattern document represented in the user's library.
  TextColumn get documentId =>
      text().references(PatternDocuments, #id, onDelete: KeyAction.cascade)();

  /// Defines when the library entry was first created locally.
  DateTimeColumn get createdAt => dateTime()();

  /// Defines when the normalized pattern was imported into the library.
  DateTimeColumn get importedAt => dateTime()();

  /// Defines the most recent open time, or null before the first open.
  DateTimeColumn get lastOpenedAt => dateTime().nullable()();

  /// Defines when library metadata or progress was last modified.
  DateTimeColumn get lastModifiedAt => dateTime()();

  /// Defines an optional user-defined title distinct from the imported title.
  TextColumn get userTitle => text().nullable()();

  /// Allows exactly one library metadata record per pattern document.
  @override
  Set<Column<Object>> get primaryKey => {documentId};
}

/// Stores reusable thread catalog and color information for one pattern.
@DataClassName('PatternThreadRow')
class PatternThreads extends Table {
  /// Defines the parent pattern document.
  TextColumn get documentId => text()();

  /// Defines the stable thread identifier within the document.
  TextColumn get id => text()();

  /// Preserves the thread's order in the portable document.
  IntColumn get sortOrder => integer()();

  /// Defines the optional thread manufacturer.
  TextColumn get brand => text().nullable()();

  /// Defines the optional manufacturer catalog number.
  TextColumn get catalogNumber => text().nullable()();

  /// Defines the optional human-readable thread color name.
  TextColumn get name => text().nullable()();

  /// Defines the canonical thread color in `#RRGGBB` notation.
  TextColumn get color => text()();

  /// Defines optional substitution or conversion notes.
  TextColumn get conversionNotes => text().nullable()();

  /// Defines whether the thread color was explicit or inferred.
  TextColumn get evidence => text()();

  /// Uniquely identifies a thread within its parent document.
  @override
  Set<Column<Object>> get primaryKey => {documentId, id};

  /// Links threads to their document and validates catalog data.
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY (document_id) REFERENCES pattern_documents(id) '
        'ON DELETE CASCADE',
    'UNIQUE (document_id, sort_order)',
    'CHECK (length(id) > 0)',
    'CHECK (sort_order >= 0)',
    "CHECK (color GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]"
        "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')",
    "CHECK (evidence IN ('explicit', 'inferred'))",
  ];
}

/// Stores symbol definitions belonging to a normalized pattern.
@DataClassName('PatternSymbolRow')
@TableIndex(
  name: 'pattern_symbols_document_thread',
  columns: {#documentId, #threadId},
)
class PatternSymbols extends Table {
  /// Defines the parent pattern document.
  TextColumn get documentId => text()();

  /// Defines the stable symbol identifier within the document.
  TextColumn get id => text()();

  /// Preserves the symbol's order in the portable document.
  IntColumn get sortOrder => integer()();

  /// Defines the symbol text found in the imported source.
  TextColumn get sourceSymbol => text()();

  /// Defines the canonical symbol lookup key.
  TextColumn get normalizedKey => text()();

  /// Defines the glyph rendered in the pattern grid.
  TextColumn get displayGlyph => text()();

  /// Defines the exact thread identifier used by the symbol.
  TextColumn get threadId => text()();

  /// Defines the stitch technique shared by cells using this symbol.
  TextColumn get stitchType => text()();

  /// Defines the optional strand count shared by cells using this symbol.
  IntColumn get threadCount => integer().nullable()();

  /// Defines optional source legend evidence for the mapping.
  TextColumn get legendEvidence => text().nullable()();

  /// Uniquely identifies a symbol within its parent document.
  @override
  Set<Column<Object>> get primaryKey => {documentId, id};

  /// Links symbols to their document and separately stored thread.
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY (document_id) REFERENCES pattern_documents(id) '
        'ON DELETE CASCADE',
    'FOREIGN KEY (document_id, thread_id) '
        'REFERENCES pattern_threads(document_id, id)',
    'UNIQUE (document_id, sort_order)',
    'CHECK (length(id) > 0)',
    'CHECK (sort_order >= 0)',
    'CHECK (length(source_symbol) > 0)',
    'CHECK (length(normalized_key) > 0)',
    'CHECK (length(display_glyph) > 0)',
    'CHECK (length(thread_id) > 0)',
    "CHECK (stitch_type IN ('full', 'half', 'quarter', 'threeQuarter', "
        "'frenchKnot', 'unknown'))",
    'CHECK (thread_count IS NULL OR thread_count > 0)',
  ];
}

/// Stores reusable thread and strand choices for backstitch linework.
@DataClassName('PatternBackstitchDefinitionRow')
@TableIndex(
  name: 'pattern_backstitch_definitions_document_thread',
  columns: {#documentId, #threadId},
)
class PatternBackstitchDefinitions extends Table {
  /// Defines the parent pattern document.
  TextColumn get documentId => text()();

  /// Defines the stable backstitch definition identifier.
  TextColumn get id => text()();

  /// Preserves definition order in the portable document.
  IntColumn get sortOrder => integer()();

  /// Defines the separately stored thread used by this definition.
  TextColumn get threadId => text()();

  /// Defines the optional number of thread strands.
  IntColumn get threadCount => integer().nullable()();

  /// Uniquely identifies a definition within its parent document.
  @override
  Set<Column<Object>> get primaryKey => {documentId, id};

  /// Links definitions to documents and threads and validates strand data.
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY (document_id) REFERENCES pattern_documents(id) '
        'ON DELETE CASCADE',
    'FOREIGN KEY (document_id, thread_id) '
        'REFERENCES pattern_threads(document_id, id)',
    'UNIQUE (document_id, sort_order)',
    'CHECK (length(id) > 0)',
    'CHECK (sort_order >= 0)',
    'CHECK (thread_count IS NULL OR thread_count > 0)',
  ];
}

/// Stores linear backstitch segments belonging to a normalized pattern.
@DataClassName('PatternBackstitchRow')
@TableIndex(
  name: 'pattern_backstitches_document_provenance',
  columns: {#documentId, #provenanceId},
)
class PatternBackstitches extends Table {
  /// Defines the parent pattern document.
  TextColumn get documentId => text()();

  /// Defines the stable segment identifier within the document.
  TextColumn get id => text()();

  /// Preserves segment order in the portable document.
  IntColumn get sortOrder => integer()();

  /// Defines the segment's starting row on the grid line lattice.
  RealColumn get startRow => real()();

  /// Defines the segment's starting column on the grid line lattice.
  RealColumn get startColumn => real()();

  /// Defines the segment's ending row on the grid line lattice.
  RealColumn get endRow => real()();

  /// Defines the segment's ending column on the grid line lattice.
  RealColumn get endColumn => real()();

  /// Defines the reusable backstitch definition used by the segment.
  TextColumn get definitionId => text()();

  /// Defines the optional parser confidence for the segment.
  RealColumn get confidence => real().nullable()();

  /// Defines whether the segment requires confirmation.
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();

  /// Defines the optional source region that supplied the segment.
  TextColumn get provenanceId => text().nullable()();

  /// Uniquely identifies a segment within its parent document.
  @override
  Set<Column<Object>> get primaryKey => {documentId, id};

  /// Links segments to their document and provenance and validates their data.
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY (document_id) REFERENCES pattern_documents(id) '
        'ON DELETE CASCADE',
    'FOREIGN KEY (document_id, definition_id) '
        'REFERENCES pattern_backstitch_definitions(document_id, id)',
    'FOREIGN KEY (document_id, provenance_id) '
        'REFERENCES pattern_regions(document_id, id)',
    'UNIQUE (document_id, sort_order)',
    'CHECK (length(id) > 0)',
    'CHECK (sort_order >= 0)',
    'CHECK (start_row >= 0)',
    'CHECK (start_column >= 0)',
    'CHECK (end_row >= 0)',
    'CHECK (end_column >= 0)',
    'CHECK (start_row != end_row OR start_column != end_column)',
    'CHECK (length(definition_id) > 0)',
    'CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1))',
  ];
}

/// Stores source-page regions mapped into global pattern coordinates.
@DataClassName('PatternRegionRow')
@TableIndex(
  name: 'pattern_regions_document_page',
  columns: {#documentId, #sourcePage},
)
class PatternRegions extends Table {
  /// Defines the parent pattern document.
  TextColumn get documentId => text()();

  /// Defines the stable provenance region identifier.
  TextColumn get id => text()();

  /// Preserves the region's order in the portable document.
  IntColumn get sortOrder => integer()();

  /// Defines the zero-based source page number.
  IntColumn get sourcePage => integer()();

  /// Defines the region's top-most global grid row.
  IntColumn get originRow => integer()();

  /// Defines the region's left-most global grid column.
  IntColumn get originColumn => integer()();

  /// Defines the number of global rows covered by the region.
  IntColumn get rowCount => integer()();

  /// Defines the number of global columns covered by the region.
  IntColumn get columnCount => integer()();

  /// Defines the optional source page or panel label.
  TextColumn get label => text().nullable()();

  /// Uniquely identifies a provenance region within its document.
  @override
  Set<Column<Object>> get primaryKey => {documentId, id};

  /// Links regions to their document and validates their positive extent.
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY (document_id) REFERENCES pattern_documents(id) '
        'ON DELETE CASCADE',
    'UNIQUE (document_id, sort_order)',
    'CHECK (length(id) > 0)',
    'CHECK (sort_order >= 0)',
    'CHECK (source_page >= 0)',
    'CHECK (origin_row >= 0)',
    'CHECK (origin_column >= 0)',
    'CHECK (row_count > 0)',
    'CHECK (column_count > 0)',
  ];
}

/// Stores only populated cells from a pattern's sparse global grid.
@DataClassName('PatternCellRow')
@TableIndex(
  name: 'pattern_cells_document_symbol',
  columns: {#documentId, #symbolId},
)
class PatternCells extends Table {
  /// Defines the parent pattern document.
  TextColumn get documentId => text()();

  /// Preserves sparse cell order in the portable document.
  IntColumn get sortOrder => integer()();

  /// Defines the cell's zero-based global grid row.
  IntColumn get gridRow => integer()();

  /// Defines the cell's zero-based global grid column.
  IntColumn get gridColumn => integer()();

  /// Defines the symbol rendered for this stitch.
  TextColumn get symbolId => text()();

  /// Defines the optional normalized parser confidence.
  RealColumn get confidence => real().nullable()();

  /// Defines whether this imported cell requires confirmation.
  BoolColumn get needsReview => boolean().withDefault(const Constant(false))();

  /// Defines the optional source region that supplied the cell.
  TextColumn get provenanceId => text().nullable()();

  /// Guarantees at most one populated stitch at a global coordinate.
  @override
  Set<Column<Object>> get primaryKey => {documentId, gridRow, gridColumn};

  /// Links cell references and validates coordinate and enum wire values.
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY (document_id) REFERENCES pattern_documents(id) '
        'ON DELETE CASCADE',
    'FOREIGN KEY (document_id, symbol_id) '
        'REFERENCES pattern_symbols(document_id, id)',
    'FOREIGN KEY (document_id, provenance_id) '
        'REFERENCES pattern_regions(document_id, id)',
    'UNIQUE (document_id, sort_order)',
    'CHECK (sort_order >= 0)',
    'CHECK (grid_row >= 0)',
    'CHECK (grid_column >= 0)',
    'CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1))',
  ];
}

/// Stores ordered parser findings retained with an imported pattern.
@DataClassName('ParserDiagnosticRow')
class ParserDiagnostics extends Table {
  /// Defines the parent pattern document.
  TextColumn get documentId => text()();

  /// Preserves diagnostic order in the portable document.
  IntColumn get diagnosticIndex => integer()();

  /// Defines the user-facing diagnostic severity.
  TextColumn get severity => text()();

  /// Defines the parser stage that produced the diagnostic.
  TextColumn get stage => text()();

  /// Defines the user-safe diagnostic explanation.
  TextColumn get message => text()();

  /// Defines the optional affected global grid row.
  IntColumn get gridRow => integer().nullable()();

  /// Defines the optional affected global grid column.
  IntColumn get gridColumn => integer().nullable()();

  /// Defines the optional affected zero-based source page.
  IntColumn get sourcePage => integer().nullable()();

  /// Defines the optional affected provenance region.
  TextColumn get regionId => text().nullable()();

  /// Defines the optional normalized parser confidence.
  RealColumn get confidence => real().nullable()();

  /// Defines the optional action suggested to resolve the finding.
  TextColumn get suggestedCorrection => text().nullable()();

  /// Uniquely identifies an ordered diagnostic within its document.
  @override
  Set<Column<Object>> get primaryKey => {documentId, diagnosticIndex};

  /// Links diagnostics and validates their optional location and wire values.
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY (document_id) REFERENCES pattern_documents(id) '
        'ON DELETE CASCADE',
    'FOREIGN KEY (document_id, region_id) '
        'REFERENCES pattern_regions(document_id, id)',
    'CHECK (diagnostic_index >= 0)',
    "CHECK (severity IN ('info', 'warning', 'error'))",
    "CHECK (stage IN ('input', 'extraction', 'classification', 'legend', "
        "'grid', 'symbols', 'splicing', 'validation'))",
    'CHECK (length(message) > 0)',
    'CHECK ((grid_row IS NULL) = (grid_column IS NULL))',
    'CHECK (grid_row IS NULL OR grid_row >= 0)',
    'CHECK (grid_column IS NULL OR grid_column >= 0)',
    'CHECK (source_page IS NULL OR source_page >= 0)',
    'CHECK (confidence IS NULL OR (confidence >= 0 AND confidence <= 1))',
  ];
}

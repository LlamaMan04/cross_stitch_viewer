import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/pattern_backstitch.dart';
import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/pattern_provenance.dart';
import '../../domain/value_objects.dart';
import 'app_database.dart';

/// Converts normalized pattern graphs to and from Drift's typed rows.
abstract final class PatternMapper {
  /// Maps the document's identity and grid extent.
  static PatternDocumentsCompanion document(PatternDocument value) =>
      PatternDocumentsCompanion.insert(
        id: value.id,
        title: value.title,
        schemaVersion: value.schemaVersion,
        rowCount: value.grid.dimensions.rows,
        columnCount: value.grid.dimensions.columns,
        sourceChecksum: Value(value.sourceChecksum),
      );

  /// Encodes each source metadata value as JSON to retain its type.
  static List<SourceMetadataEntriesCompanion> metadata(PatternDocument value) =>
      [
        for (final entry in value.sourceMetadata.entries)
          SourceMetadataEntriesCompanion.insert(
            documentId: value.id,
            key: entry.key,
            value: jsonEncode(entry.value),
          ),
      ];

  /// Maps ordered reusable thread definitions.
  static List<PatternThreadsCompanion> threads(PatternDocument value) => [
    for (var index = 0; index < value.threads.length; index++)
      PatternThreadsCompanion.insert(
        documentId: value.id,
        id: value.threads[index].id,
        sortOrder: index,
        brand: Value(value.threads[index].brand),
        catalogNumber: Value(value.threads[index].catalogNumber),
        name: Value(value.threads[index].name),
        color: value.threads[index].color,
        conversionNotes: Value(value.threads[index].conversionNotes),
        evidence: value.threads[index].evidence.name,
      ),
  ];

  /// Maps ordered symbol definitions.
  static List<PatternSymbolsCompanion> symbols(PatternDocument value) => [
    for (var index = 0; index < value.symbols.length; index++)
      PatternSymbolsCompanion.insert(
        documentId: value.id,
        id: value.symbols[index].id,
        sortOrder: index,
        sourceSymbol: value.symbols[index].sourceSymbol,
        normalizedKey: value.symbols[index].normalizedKey,
        displayGlyph: value.symbols[index].displayGlyph,
        threadId: value.symbols[index].threadId,
        stitchType: value.symbols[index].stitchType.name,
        threadCount: Value(value.symbols[index].threadCount),
        legendEvidence: Value(value.symbols[index].legendEvidence),
      ),
  ];

  /// Maps ordered reusable backstitch definitions.
  static List<PatternBackstitchDefinitionsCompanion> backstitchDefinitions(
    PatternDocument value,
  ) => [
    for (var index = 0; index < value.backstitchDefinitions.length; index++)
      PatternBackstitchDefinitionsCompanion.insert(
        documentId: value.id,
        id: value.backstitchDefinitions[index].id,
        sortOrder: index,
        threadId: value.backstitchDefinitions[index].threadId,
        threadCount: Value(value.backstitchDefinitions[index].threadCount),
      ),
  ];

  /// Maps ordered page provenance regions.
  static List<PatternRegionsCompanion> regions(PatternDocument value) => [
    for (var index = 0; index < value.regions.length; index++)
      PatternRegionsCompanion.insert(
        documentId: value.id,
        id: value.regions[index].id,
        sortOrder: index,
        sourcePage: value.regions[index].sourcePage,
        originRow: value.regions[index].origin.row,
        originColumn: value.regions[index].origin.column,
        rowCount: value.regions[index].rows,
        columnCount: value.regions[index].columns,
        label: Value(value.regions[index].label),
      ),
  ];

  /// Maps populated grid cells in source order.
  static List<PatternCellsCompanion> cells(PatternDocument value) => [
    for (var index = 0; index < value.grid.cells.length; index++)
      PatternCellsCompanion.insert(
        documentId: value.id,
        sortOrder: index,
        gridRow: value.grid.cells[index].coordinate.row,
        gridColumn: value.grid.cells[index].coordinate.column,
        symbolId: value.grid.cells[index].symbolId,
        confidence: Value(value.grid.cells[index].confidence?.value),
        needsReview: Value(value.grid.cells[index].needsReview),
        provenanceId: Value(value.grid.cells[index].provenanceId),
      ),
  ];

  /// Maps ordered linear backstitch segments and definition references.
  static List<PatternBackstitchesCompanion> backstitches(
    PatternDocument value,
  ) => [
    for (var index = 0; index < value.backstitches.length; index++)
      PatternBackstitchesCompanion.insert(
        documentId: value.id,
        id: value.backstitches[index].id,
        sortOrder: index,
        startRow: value.backstitches[index].start.row,
        startColumn: value.backstitches[index].start.column,
        endRow: value.backstitches[index].end.row,
        endColumn: value.backstitches[index].end.column,
        definitionId: value.backstitches[index].definitionId,
        confidence: Value(value.backstitches[index].confidence?.value),
        needsReview: Value(value.backstitches[index].needsReview),
        provenanceId: Value(value.backstitches[index].provenanceId),
      ),
  ];

  /// Maps ordered parser diagnostics.
  static List<ParserDiagnosticsCompanion> diagnostics(PatternDocument value) =>
      [
        for (var index = 0; index < value.diagnostics.length; index++)
          ParserDiagnosticsCompanion.insert(
            documentId: value.id,
            diagnosticIndex: index,
            severity: value.diagnostics[index].severity.name,
            stage: value.diagnostics[index].stage.name,
            message: value.diagnostics[index].message,
            gridRow: Value(value.diagnostics[index].coordinate?.row),
            gridColumn: Value(value.diagnostics[index].coordinate?.column),
            sourcePage: Value(value.diagnostics[index].sourcePage),
            regionId: Value(value.diagnostics[index].regionId),
            confidence: Value(value.diagnostics[index].confidence?.value),
            suggestedCorrection: Value(
              value.diagnostics[index].suggestedCorrection,
            ),
          ),
      ];

  /// Reconstructs a complete normalized document from its related rows.
  static PatternDocument fromRows({
    required PatternDocumentRow document,
    required List<SourceMetadataEntryRow> metadata,
    required List<PatternThreadRow> threads,
    required List<PatternSymbolRow> symbols,
    required List<PatternBackstitchDefinitionRow> backstitchDefinitions,
    required List<PatternRegionRow> regions,
    required List<PatternCellRow> cells,
    required List<PatternBackstitchRow> backstitches,
    required List<ParserDiagnosticRow> diagnostics,
  }) {
    final value = PatternDocument(
      id: document.id,
      title: document.title,
      schemaVersion: document.schemaVersion,
      grid: PatternGrid(
        dimensions: PatternDimensions(document.rowCount, document.columnCount),
        cells: [
          for (final row in cells)
            StitchCell(
              coordinate: GridCoordinate(row.gridRow, row.gridColumn),
              symbolId: row.symbolId,
              confidence: row.confidence == null
                  ? null
                  : Confidence(row.confidence!),
              needsReview: row.needsReview,
              provenanceId: row.provenanceId,
            ),
        ],
      ),
      threads: [
        for (final row in threads)
          ThreadDefinition(
            id: row.id,
            color: row.color,
            brand: row.brand,
            catalogNumber: row.catalogNumber,
            name: row.name,
            conversionNotes: row.conversionNotes,
            evidence: ColorEvidence.values.byName(row.evidence),
          ),
      ],
      symbols: [
        for (final row in symbols)
          SymbolDefinition(
            id: row.id,
            sourceSymbol: row.sourceSymbol,
            normalizedKey: row.normalizedKey,
            displayGlyph: row.displayGlyph,
            threadId: row.threadId,
            stitchType: StitchType.values.byName(row.stitchType),
            threadCount: row.threadCount,
            legendEvidence: row.legendEvidence,
          ),
      ],
      backstitchDefinitions: [
        for (final row in backstitchDefinitions)
          BackstitchDefinition(
            id: row.id,
            threadId: row.threadId,
            threadCount: row.threadCount,
          ),
      ],
      backstitches: [
        for (final row in backstitches)
          BackstitchSegment(
            id: row.id,
            start: BackstitchCoordinate(
              row: row.startRow,
              column: row.startColumn,
            ),
            end: BackstitchCoordinate(row: row.endRow, column: row.endColumn),
            definitionId: row.definitionId,
            confidence: row.confidence == null
                ? null
                : Confidence(row.confidence!),
            needsReview: row.needsReview,
            provenanceId: row.provenanceId,
          ),
      ],
      regions: [
        for (final row in regions)
          PatternRegion(
            id: row.id,
            sourcePage: row.sourcePage,
            origin: GridCoordinate(row.originRow, row.originColumn),
            rows: row.rowCount,
            columns: row.columnCount,
            label: row.label,
          ),
      ],
      sourceMetadata: {
        for (final row in metadata) row.key: jsonDecode(row.value),
      },
      sourceChecksum: document.sourceChecksum,
      diagnostics: [
        for (final row in diagnostics)
          ParserDiagnostic(
            severity: DiagnosticSeverity.values.byName(row.severity),
            stage: DiagnosticStage.values.byName(row.stage),
            message: row.message,
            coordinate: row.gridRow == null
                ? null
                : GridCoordinate(row.gridRow!, row.gridColumn!),
            sourcePage: row.sourcePage,
            regionId: row.regionId,
            confidence: row.confidence == null
                ? null
                : Confidence(row.confidence!),
            suggestedCorrection: row.suggestedCorrection,
          ),
      ],
    );
    value.validate();
    return value;
  }
}

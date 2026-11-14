import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/pattern_backstitch.dart';
import 'package:stitch_scope/domain/pattern_definitions.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/pattern_provenance.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/json/pattern_document_json_export.dart';
import 'package:stitch_scope/json/pattern_document_json_import.dart';

/// Verifies portable import and export of existing domain objects.
void main() {
  test('round trips the complete normalized document graph', () {
    final decoded = decodePatternDocumentJson(
      encodePatternDocumentJson(_document()),
    );

    expect(decoded.id, 'garden');
    expect(decoded.grid.dimensions.rows, 3);
    expect(
      decoded.grid.cellAt(const GridCoordinate(1, 2))?.needsReview,
      isTrue,
    );
    expect(decoded.threads.single.evidence, ColorEvidence.inferred);
    expect(decoded.symbols.single.stitchType, StitchType.threeQuarter);
    expect(decoded.backstitches.single.end.column, 3.5);
    expect(decoded.regions.single.label, 'Page 1');
    expect(decoded.sourceMetadata['source'], 'garden.pdf');
    expect(decoded.diagnostics.single.stage, DiagnosticStage.symbols);
  });

  test('rejects unsupported versions and malformed domain values', () {
    expect(
      () => patternDocumentFromJson(<String, Object?>{
        ...patternDocumentToJson(_document()),
        'formatVersion': 2,
      }),
      throwsFormatException,
    );

    final invalid = jsonDecode(
      encodePatternDocumentJson(_document()),
    ) as Map<String, Object?>;
    (invalid['grid'] as Map<String, Object?>)['rows'] = 0;
    expect(() => patternDocumentFromJson(invalid), throwsFormatException);
  });
}

/// Creates a representative document with every optional imported feature.
PatternDocument _document() => PatternDocument(
  id: 'garden',
  title: 'Garden',
  schemaVersion: 1,
  grid: PatternGrid(
    dimensions: const PatternDimensions(3, 4),
    cells: const [
      StitchCell(
        coordinate: GridCoordinate(1, 2),
        symbolId: 'flower',
        confidence: Confidence(0.75),
        needsReview: true,
        provenanceId: 'page-1',
      ),
    ],
  ),
  threads: const [
    ThreadDefinition(
      id: 'red',
      color: '#C0392B',
      evidence: ColorEvidence.inferred,
    ),
  ],
  symbols: const [
    SymbolDefinition(
      id: 'flower',
      sourceSymbol: 'X',
      normalizedKey: 'x',
      displayGlyph: '×',
      threadId: 'red',
      stitchType: StitchType.threeQuarter,
      threadCount: 2,
    ),
  ],
  backstitchDefinitions: const [
    BackstitchDefinition(id: 'outline', threadId: 'red', threadCount: 1),
  ],
  backstitches: const [
    BackstitchSegment(
      id: 'outline-1',
      start: BackstitchCoordinate(row: 0, column: 0),
      end: BackstitchCoordinate(row: 2, column: 3.5),
      definitionId: 'outline',
      provenanceId: 'page-1',
    ),
  ],
  regions: const [
    PatternRegion(
      id: 'page-1',
      sourcePage: 0,
      origin: GridCoordinate(0, 0),
      rows: 3,
      columns: 4,
      label: 'Page 1',
    ),
  ],
  sourceMetadata: const <String, Object?>{
    'source': 'garden.pdf',
    'pages': <Object?>[1, 2],
  },
  sourceChecksum: 'abc123',
  diagnostics: const [
    ParserDiagnostic(
      severity: DiagnosticSeverity.warning,
      stage: DiagnosticStage.symbols,
      message: 'Review symbol',
    ),
  ],
);

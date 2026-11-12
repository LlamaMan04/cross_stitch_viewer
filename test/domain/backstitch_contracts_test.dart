import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/domain_error.dart';
import 'package:stitch_scope/domain/pattern_backstitch.dart';
import 'package:stitch_scope/domain/pattern_definitions.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/value_objects.dart';

/// Thread rendered by the valid backstitch segments in this test fixture.
const ThreadDefinition _outlineThread = ThreadDefinition(
  id: 'outline-red',
  color: '#C72C41',
);

/// Verifies the normalized domain contract for linear backstitch data.
void main() {
  test(
    'preserves independent backstitch segments with fractional endpoints',
    () {
      final document = _document(
        backstitches: const [
          BackstitchSegment(
            id: 'outline-a',
            start: BackstitchCoordinate(row: 0, column: 0),
            end: BackstitchCoordinate(row: 1.5, column: 2),
            definitionId: 'outline',
          ),
        ],
      );

      document.validate();

      expect(document.grid.cells, isEmpty);
      expect(document.symbols, isEmpty);
      expect(document.backstitchById('outline-a')?.end.column, 2);
    },
  );

  test('accepts endpoints on the inclusive outer grid corners', () {
    final document = _document(
      backstitches: const [
        BackstitchSegment(
          id: 'outer-edge',
          start: BackstitchCoordinate(row: 0, column: 0),
          end: BackstitchCoordinate(row: 3, column: 4),
          definitionId: 'outline',
        ),
      ],
    );

    expect(document.validate, returnsNormally);
  });

  test('rejects nonpositive thread counts in stitch definitions', () {
    const symbol = SymbolDefinition(
      id: 'invalid-symbol',
      sourceSymbol: 'X',
      normalizedKey: 'x',
      displayGlyph: 'X',
      threadId: 'outline-red',
      threadCount: 0,
    );
    const backstitch = BackstitchDefinition(
      id: 'invalid-backstitch',
      threadId: 'outline-red',
      threadCount: 0,
    );

    expect(symbol.validate, throwsA(isA<DocumentValidationException>()));
    expect(backstitch.validate, throwsA(isA<DocumentValidationException>()));
  });

  test('rejects invalid backstitch geometry and thread data', () {
    final invalidDocuments = <PatternDocument>[
      _document(
        backstitches: const [
          BackstitchSegment(
            id: 'outside',
            start: BackstitchCoordinate(row: 0, column: 0),
            end: BackstitchCoordinate(row: 3.1, column: 4),
            definitionId: 'outline',
          ),
        ],
      ),
      _document(
        backstitches: const [
          BackstitchSegment(
            id: 'zero-length',
            start: BackstitchCoordinate(row: 1, column: 1),
            end: BackstitchCoordinate(row: 1, column: 1),
            definitionId: 'outline',
          ),
        ],
      ),
      _document(
        backstitches: const [
          BackstitchSegment(
            id: 'non-finite',
            start: BackstitchCoordinate(row: double.nan, column: 0),
            end: BackstitchCoordinate(row: 1, column: 1),
            definitionId: 'outline',
          ),
        ],
      ),
      _document(
        thread: const ThreadDefinition(id: 'outline-red', color: '#invalid'),
        backstitches: const [
          BackstitchSegment(
            id: 'invalid-thread',
            start: BackstitchCoordinate(row: 0, column: 0),
            end: BackstitchCoordinate(row: 1, column: 1),
            definitionId: 'outline',
          ),
        ],
      ),
      _document(
        backstitches: const [
          BackstitchSegment(
            id: 'duplicate',
            start: BackstitchCoordinate(row: 0, column: 0),
            end: BackstitchCoordinate(row: 1, column: 1),
            definitionId: 'outline',
          ),
          BackstitchSegment(
            id: 'duplicate',
            start: BackstitchCoordinate(row: 1, column: 1),
            end: BackstitchCoordinate(row: 2, column: 2),
            definitionId: 'outline',
          ),
        ],
      ),
    ];

    for (final document in invalidDocuments) {
      expect(document.validate, throwsA(isA<DocumentValidationException>()));
    }
  });
}

/// Creates a minimal document with optional line-segment data for validation.
PatternDocument _document({
  required Iterable<BackstitchSegment> backstitches,
  ThreadDefinition thread = _outlineThread,
}) => PatternDocument(
  id: 'backstitch-contract',
  title: 'Backstitch contract',
  schemaVersion: 1,
  grid: PatternGrid(dimensions: const PatternDimensions(3, 4), cells: const []),
  threads: [thread],
  symbols: const [],
  backstitchDefinitions: const [
    BackstitchDefinition(id: 'outline', threadId: 'outline-red'),
  ],
  backstitches: backstitches,
);

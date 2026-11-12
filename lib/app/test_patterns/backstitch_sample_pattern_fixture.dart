import '../../domain/pattern_backstitch.dart';
import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/value_objects.dart';

/// Supplies deterministic line geometry for backstitch rendering tests.
abstract final class BackstitchSamplePatternFixture {
  /// Number of segments covering the geometry cases in the rendering plan.
  static const int backstitchCount = 8;

  /// Number of definitions that resolve to the same red thread color.
  static const int sameColorDefinitionCount = 2;

  /// Creates a ten-by-ten document containing representative line geometry.
  static PatternDocument create() => PatternDocument(
    id: 'backstitch-rendering-sample',
    title: 'Backstitch Rendering Sample',
    schemaVersion: 1,
    grid: PatternGrid(
      dimensions: const PatternDimensions(10, 10),
      cells: const [
        StitchCell(coordinate: GridCoordinate(2, 2), symbolId: 'red-a'),
        StitchCell(coordinate: GridCoordinate(5, 5), symbolId: 'red-b'),
        StitchCell(coordinate: GridCoordinate(7, 7), symbolId: 'blue'),
      ],
    ),
    threads: const [
      ThreadDefinition(id: 'thread-red', color: '#C72C41', name: 'Red'),
      ThreadDefinition(id: 'thread-blue', color: '#2F5DA8', name: 'Blue'),
    ],
    symbols: const [
      SymbolDefinition(
        id: 'red-a',
        sourceSymbol: 'A',
        normalizedKey: 'a',
        displayGlyph: 'A',
        threadId: 'thread-red',
      ),
      SymbolDefinition(
        id: 'red-b',
        sourceSymbol: 'B',
        normalizedKey: 'b',
        displayGlyph: 'B',
        threadId: 'thread-red',
      ),
      SymbolDefinition(
        id: 'blue',
        sourceSymbol: 'C',
        normalizedKey: 'c',
        displayGlyph: 'C',
        threadId: 'thread-blue',
      ),
    ],
    backstitchDefinitions: const [
      BackstitchDefinition(id: 'red-outline', threadId: 'thread-red'),
      BackstitchDefinition(id: 'red-detail', threadId: 'thread-red'),
      BackstitchDefinition(id: 'blue-detail', threadId: 'thread-blue'),
    ],
    backstitches: const [
      // Horizontal segment with both endpoints on grid corners.
      BackstitchSegment(
        id: 'horizontal',
        start: BackstitchCoordinate(row: 2, column: 0),
        end: BackstitchCoordinate(row: 2, column: 10),
        definitionId: 'red-outline',
      ),
      // Vertical segment with both endpoints on grid corners.
      BackstitchSegment(
        id: 'vertical',
        start: BackstitchCoordinate(row: 0, column: 4),
        end: BackstitchCoordinate(row: 10, column: 4),
        definitionId: 'red-detail',
      ),
      // Diagonal segment for transform and slope coverage.
      BackstitchSegment(
        id: 'diagonal',
        start: BackstitchCoordinate(row: 0, column: 0),
        end: BackstitchCoordinate(row: 10, column: 10),
        definitionId: 'blue-detail',
      ),
      // Fractional endpoints exercise partial-cell precision.
      BackstitchSegment(
        id: 'partial-cell',
        start: BackstitchCoordinate(row: 1.5, column: 0.5),
        end: BackstitchCoordinate(row: 2.5, column: 3.25),
        definitionId: 'red-outline',
      ),
      // These two segments deliberately share an endpoint.
      BackstitchSegment(
        id: 'shared-endpoint-a',
        start: BackstitchCoordinate(row: 6, column: 2),
        end: BackstitchCoordinate(row: 6, column: 5),
        definitionId: 'red-detail',
      ),
      BackstitchSegment(
        id: 'shared-endpoint-b',
        start: BackstitchCoordinate(row: 6, column: 5),
        end: BackstitchCoordinate(row: 8, column: 7),
        definitionId: 'red-outline',
      ),
      // Neither endpoint is in a central viewport, but the line crosses it.
      BackstitchSegment(
        id: 'crossing-viewport',
        start: BackstitchCoordinate(row: 1, column: 0),
        end: BackstitchCoordinate(row: 9, column: 10),
        definitionId: 'blue-detail',
      ),
      // A second same-color line keeps cross-definition highlighting explicit.
      BackstitchSegment(
        id: 'same-color-other-definition',
        start: BackstitchCoordinate(row: 8.5, column: 1.5),
        end: BackstitchCoordinate(row: 9.5, column: 3.5),
        definitionId: 'red-detail',
      ),
    ],
    sourceMetadata: const {'origin': 'backstitch rendering test fixture'},
  );
}

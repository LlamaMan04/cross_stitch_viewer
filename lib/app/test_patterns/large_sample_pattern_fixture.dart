import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/pattern_provenance.dart';
import '../../domain/value_objects.dart';

/// Supplies a deterministic, densely populated pattern for performance tests.
abstract final class LargeSamplePatternFixture {
  /// Number of rows in the generated test pattern.
  static const int rows = 100;

  /// Number of columns in the generated test pattern.
  static const int columns = 200;

  /// Number of populated cells in the generated test pattern.
  static const int populatedCellCount = 19000;

  /// Number of rows contained in each fixture source region.
  static const int regionRows = 50;

  /// Number of columns contained in each fixture source region.
  static const int regionColumns = 100;

  /// Creates a 100-by-200 pattern with 95% of its cells populated.
  static PatternDocument create() => PatternDocument(
    id: 'sample-large-test-pattern',
    title: 'Large Test Pattern',
    schemaVersion: 1,
    grid: PatternGrid(
      dimensions: const PatternDimensions(rows, columns),
      cells: _buildCells(),
    ),
    symbols: symbols,
    regions: const [
      PatternRegion(
        id: 'large-top-left',
        sourcePage: 0,
        origin: GridCoordinate(0, 0),
        rows: regionRows,
        columns: regionColumns,
        label: 'Large test grid: top left',
      ),
      PatternRegion(
        id: 'large-top-right',
        sourcePage: 1,
        origin: GridCoordinate(0, regionColumns),
        rows: regionRows,
        columns: regionColumns,
        label: 'Large test grid: top right',
      ),
      PatternRegion(
        id: 'large-bottom-left',
        sourcePage: 2,
        origin: GridCoordinate(regionRows, 0),
        rows: regionRows,
        columns: regionColumns,
        label: 'Large test grid: bottom left',
      ),
      PatternRegion(
        id: 'large-bottom-right',
        sourcePage: 3,
        origin: GridCoordinate(regionRows, regionColumns),
        rows: regionRows,
        columns: regionColumns,
        label: 'Large test grid: bottom right',
      ),
    ],
    sourceMetadata: const {
      'origin': 'built-in performance test fixture',
      'coverage': '95%',
    },
    diagnostics: const [
      ParserDiagnostic(
        severity: DiagnosticSeverity.info,
        stage: DiagnosticStage.validation,
        message: 'Deterministic large-grid test fixture.',
      ),
    ],
  );

  /// Generates cells in row-major order, leaving every twentieth cell empty.
  static Iterable<StitchCell> _buildCells() sync* {
    var populated = 0;
    for (var row = 0; row < rows; row++) {
      for (var column = 0; column < columns; column++) {
        final linearIndex = row * columns + column;
        if (linearIndex % 20 == 0) continue;
        yield StitchCell(
          coordinate: GridCoordinate(row, column),
          symbolId: symbols[populated % symbols.length].id,
          provenanceId: _regionIdFor(row, column),
        );
        populated++;
      }
    }
  }

  /// Returns the source region that contains one generated grid coordinate.
  static String _regionIdFor(int row, int column) {
    final isBottom = row >= regionRows;
    final isRight = column >= regionColumns;
    if (isBottom && isRight) return 'large-bottom-right';
    if (isBottom) return 'large-bottom-left';
    if (isRight) return 'large-top-right';
    return 'large-top-left';
  }

  /// Thread and glyph definitions shared by the built-in performance fixtures.
  static const List<SymbolDefinition> symbols = [
    SymbolDefinition(
      id: 'large-red',
      sourceSymbol: 'A',
      normalizedKey: 'a',
      displayGlyph: 'A',
      thread: ThreadDefinition(
        id: 'dmc-321',
        color: '#C72C41',
        brand: 'DMC',
        catalogNumber: '321',
        name: 'Red',
      ),
    ),
    SymbolDefinition(
      id: 'large-orange',
      sourceSymbol: 'B',
      normalizedKey: 'b',
      displayGlyph: 'B',
      thread: ThreadDefinition(
        id: 'dmc-740',
        color: '#F58220',
        brand: 'DMC',
        catalogNumber: '740',
        name: 'Tangerine',
      ),
    ),
    SymbolDefinition(
      id: 'large-yellow',
      sourceSymbol: 'C',
      normalizedKey: 'c',
      displayGlyph: 'C',
      thread: ThreadDefinition(
        id: 'dmc-726',
        color: '#F4C430',
        brand: 'DMC',
        catalogNumber: '726',
        name: 'Topaz',
      ),
    ),
    SymbolDefinition(
      id: 'large-green',
      sourceSymbol: 'D',
      normalizedKey: 'd',
      displayGlyph: 'D',
      thread: ThreadDefinition(
        id: 'dmc-704',
        color: '#5B8C3A',
        brand: 'DMC',
        catalogNumber: '704',
        name: 'Chartreuse',
      ),
    ),
    SymbolDefinition(
      id: 'large-teal',
      sourceSymbol: 'E',
      normalizedKey: 'e',
      displayGlyph: 'E',
      thread: ThreadDefinition(
        id: 'dmc-3847',
        color: '#1C9A9A',
        brand: 'DMC',
        catalogNumber: '3847',
        name: 'Teal Green',
      ),
    ),
    SymbolDefinition(
      id: 'large-blue',
      sourceSymbol: 'F',
      normalizedKey: 'f',
      displayGlyph: 'F',
      thread: ThreadDefinition(
        id: 'dmc-798',
        color: '#2F5DA8',
        brand: 'DMC',
        catalogNumber: '798',
        name: 'Delft Blue',
      ),
    ),
    SymbolDefinition(
      id: 'large-purple',
      sourceSymbol: 'G',
      normalizedKey: 'g',
      displayGlyph: 'G',
      thread: ThreadDefinition(
        id: 'dmc-550',
        color: '#6F3F8F',
        brand: 'DMC',
        catalogNumber: '550',
        name: 'Violet',
      ),
    ),
    SymbolDefinition(
      id: 'large-pink',
      sourceSymbol: 'H',
      normalizedKey: 'h',
      displayGlyph: 'H',
      thread: ThreadDefinition(
        id: 'dmc-604',
        color: '#D94F8A',
        brand: 'DMC',
        catalogNumber: '604',
        name: 'Cranberry',
      ),
    ),
    SymbolDefinition(
      id: 'large-brown',
      sourceSymbol: 'I',
      normalizedKey: 'i',
      displayGlyph: 'I',
      thread: ThreadDefinition(
        id: 'dmc-801',
        color: '#7A4B2A',
        brand: 'DMC',
        catalogNumber: '801',
        name: 'Coffee Brown',
      ),
    ),
    SymbolDefinition(
      id: 'large-gray',
      sourceSymbol: 'J',
      normalizedKey: 'j',
      displayGlyph: 'J',
      thread: ThreadDefinition(
        id: 'dmc-645',
        color: '#777777',
        brand: 'DMC',
        catalogNumber: '645',
        name: 'Beaver Gray',
      ),
    ),
    SymbolDefinition(
      id: 'large-black',
      sourceSymbol: 'K',
      normalizedKey: 'k',
      displayGlyph: 'K',
      thread: ThreadDefinition(
        id: 'dmc-310',
        color: '#222222',
        brand: 'DMC',
        catalogNumber: '310',
        name: 'Black',
      ),
    ),
    SymbolDefinition(
      id: 'large-white',
      sourceSymbol: 'L',
      normalizedKey: 'l',
      displayGlyph: 'L',
      thread: ThreadDefinition(
        id: 'dmc-blanc',
        color: '#F4F1EA',
        brand: 'DMC',
        catalogNumber: 'BLANC',
        name: 'White',
      ),
    ),
  ];
}

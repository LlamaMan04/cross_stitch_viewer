import 'domain_error.dart';
import 'value_objects.dart';

/// Half-open row and column bounds used for spatial grid queries.
class GridBounds {
  /// Creates bounds containing rows and columns from each start through, but
  /// not including, its corresponding end.
  const GridBounds({
    required this.startRow,
    required this.endRow,
    required this.startColumn,
    required this.endColumn,
  }) : assert(endRow >= startRow),
       assert(endColumn >= startColumn);

  /// First row included in the bounds.
  final int startRow;

  /// First row excluded from the bounds.
  final int endRow;

  /// First column included in the bounds.
  final int startColumn;

  /// First column excluded from the bounds.
  final int endColumn;

  /// Whether the bounds contain no grid coordinates.
  bool get isEmpty => startRow == endRow || startColumn == endColumn;

  /// Returns whether [coordinate] lies inside these half-open bounds.
  bool contains(GridCoordinate coordinate) =>
      coordinate.row >= startRow &&
      coordinate.row < endRow &&
      coordinate.column >= startColumn &&
      coordinate.column < endColumn;

  /// Restricts these bounds to the valid coordinates in [dimensions].
  GridBounds clampTo(PatternDimensions dimensions) {
    // Clamp starts first so each end can retain a valid half-open ordering.
    final clampedStartRow = startRow.clamp(0, dimensions.rows);
    final clampedEndRow = endRow.clamp(clampedStartRow, dimensions.rows);
    final clampedStartColumn = startColumn.clamp(0, dimensions.columns);
    final clampedEndColumn = endColumn.clamp(
      clampedStartColumn,
      dimensions.columns,
    );
    return GridBounds(
      startRow: clampedStartRow,
      endRow: clampedEndRow,
      startColumn: clampedStartColumn,
      endColumn: clampedEndColumn,
    );
  }

  /// Compares bounds by all four half-open range endpoints.
  @override
  bool operator ==(Object other) =>
      other is GridBounds &&
      startRow == other.startRow &&
      endRow == other.endRow &&
      startColumn == other.startColumn &&
      endColumn == other.endColumn;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode => Object.hash(startRow, endRow, startColumn, endColumn);

  /// Human-readable range notation for diagnostics and failed tests.
  @override
  String toString() =>
      'GridBounds(rows: [$startRow, $endRow), '
      'columns: [$startColumn, $endColumn))';
}

/// Stitch technique represented by a populated grid cell.
enum StitchType {
  /// Standard full cross stitch.
  full,

  /// Stitch covering half of a grid cell.
  half,

  /// Stitch covering one quarter of a grid cell.
  quarter,

  /// Three-quarter stitch combining a half and a quarter stitch.
  threeQuarter,

  /// Linear stitch used for outlines or details.
  backstitch,

  /// Small knotted stitch used for decorative details.
  frenchKnot,

  /// Technique was not identified by the source or parser.
  unknown,
}

/// One populated coordinate in the sparse pattern grid.
class StitchCell {
  /// Creates a stitch cell with a symbol reference and optional metadata.
  const StitchCell({
    required this.coordinate,
    required this.symbolId,
    this.stitchType = StitchType.full,
    this.confidence,
    this.needsReview = false,
    this.provenanceId,
  });

  /// Global zero-based grid position of this stitch.
  final GridCoordinate coordinate;

  /// ID of the symbol definition used to render this stitch.
  final String symbolId;

  /// Technique used for this stitch.
  final StitchType stitchType;

  /// Parser confidence when the cell was imported.
  final Confidence? confidence;

  /// Whether the user or parser flagged this cell for confirmation.
  final bool needsReview;

  /// ID of the source region that supplied this cell.
  final String? provenanceId;
}

/// Stable row and column identity for one fixed-size spatial tile.
class PatternTileCoordinate {
  /// Creates a tile coordinate from zero-based tile indices.
  const PatternTileCoordinate(this.row, this.column);

  /// Zero-based tile row.
  final int row;

  /// Zero-based tile column.
  final int column;

  /// Compares tile coordinates by row and column.
  @override
  bool operator ==(Object other) =>
      other is PatternTileCoordinate &&
      row == other.row &&
      column == other.column;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode => Object.hash(row, column);
}

/// Immutable aggregate used to render a tile without enumerating its cells.
class PatternTileSummary {
  /// Creates one summary from its coordinate and symbol population counts.
  PatternTileSummary({
    required this.coordinate,
    required this.blockSize,
    required Map<String, int> symbolCounts,
  }) : symbolCounts = Map<String, int>.unmodifiable(symbolCounts),
       populatedCellCount = symbolCounts.values.fold(
         0,
         (sum, count) => sum + count,
       ),
       dominantSymbolId = _dominantSymbol(symbolCounts);

  /// Spatial tile represented by this summary.
  final PatternTileCoordinate coordinate;

  /// Number of grid cells covered along each side of this summary block.
  final int blockSize;

  /// Number of populated cells associated with each symbol ID.
  final Map<String, int> symbolCounts;

  /// Total populated cells in this tile.
  final int populatedCellCount;

  /// Most frequent symbol ID, with source order breaking ties.
  final String dominantSymbolId;

  /// Selects the first symbol having the greatest population.
  static String _dominantSymbol(Map<String, int> symbolCounts) {
    assert(symbolCounts.isNotEmpty);
    var dominantId = symbolCounts.keys.first;
    var dominantCount = symbolCounts[dominantId]!;
    for (final entry in symbolCounts.entries.skip(1)) {
      if (entry.value > dominantCount) {
        dominantId = entry.key;
        dominantCount = entry.value;
      }
    }
    return dominantId;
  }
}

/// Sparse populated cells together with the full rectangular grid dimensions.
class PatternGrid {
  /// Number of rows and columns grouped into one immutable spatial tile.
  static const int tileSize = 32;

  /// Available immutable aggregation sizes for overview rendering.
  static const List<int> overviewBlockSizes = <int>[2, 4, 8, 16, 32];

  /// Creates a grid and copies [cells] into an unmodifiable list.
  PatternGrid({required this.dimensions, required Iterable<StitchCell> cells}) {
    // Preserve stable source order while preventing mutation after indexing.
    final immutableCells = List<StitchCell>.unmodifiable(cells);
    this.cells = immutableCells;
    _cellsByCoordinate = Map.unmodifiable({
      for (final cell in immutableCells) cell.coordinate: cell,
    });
    // Accumulate mutable buckets only during construction.
    final mutableTiles = <(int, int), List<StitchCell>>{};
    for (final cell in immutableCells) {
      // Integer division maps each coordinate to its fixed spatial tile.
      final tile = (
        cell.coordinate.row ~/ tileSize,
        cell.coordinate.column ~/ tileSize,
      );
      mutableTiles.putIfAbsent(tile, () => <StitchCell>[]).add(cell);
    }
    _cellsByTile = Map.unmodifiable({
      for (final entry in mutableTiles.entries)
        entry.key: List<StitchCell>.unmodifiable(entry.value),
    });
    _overviewSummariesByBlockSize =
        Map<int, Map<PatternTileCoordinate, PatternTileSummary>>.unmodifiable({
          for (final blockSize in overviewBlockSizes)
            blockSize: _buildSummaries(immutableCells, blockSize),
        });
  }

  /// Full grid extent, including coordinates without stitches.
  final PatternDimensions dimensions;

  /// Cells containing stitches; unlisted coordinates are empty.
  late final List<StitchCell> cells;

  /// Direct coordinate lookup for populated cells.
  late final Map<GridCoordinate, StitchCell> _cellsByCoordinate;

  /// Immutable populated cells grouped into fixed-size spatial tiles.
  late final Map<(int, int), List<StitchCell>> _cellsByTile;

  /// Immutable overview summaries grouped by aggregation block size.
  late final Map<int, Map<PatternTileCoordinate, PatternTileSummary>>
  _overviewSummariesByBlockSize;

  /// Returns the tile coordinate containing [coordinate].
  static PatternTileCoordinate tileCoordinateFor(GridCoordinate coordinate) =>
      PatternTileCoordinate(
        coordinate.row ~/ tileSize,
        coordinate.column ~/ tileSize,
      );

  /// Finds the populated cell at [coordinate], or returns null if empty.
  StitchCell? cellAt(GridCoordinate coordinate) =>
      _cellsByCoordinate[coordinate];

  /// Yields populated tile summaries intersecting [bounds].
  Iterable<PatternTileSummary> tileSummariesIntersecting(GridBounds bounds) =>
      overviewSummariesIntersecting(bounds, tileSize);

  /// Yields populated overview summaries at one supported [blockSize].
  Iterable<PatternTileSummary> overviewSummariesIntersecting(
    GridBounds bounds,
    int blockSize,
  ) sync* {
    final summaries = _overviewSummariesByBlockSize[blockSize];
    if (summaries == null) {
      throw ArgumentError.value(
        blockSize,
        'blockSize',
        'Must be one of $overviewBlockSizes.',
      );
    }
    final query = bounds.clampTo(dimensions);
    if (query.isEmpty) return;
    final firstTileRow = query.startRow ~/ blockSize;
    final lastTileRow = (query.endRow - 1) ~/ blockSize;
    final firstTileColumn = query.startColumn ~/ blockSize;
    final lastTileColumn = (query.endColumn - 1) ~/ blockSize;
    for (var tileRow = firstTileRow; tileRow <= lastTileRow; tileRow++) {
      for (
        var tileColumn = firstTileColumn;
        tileColumn <= lastTileColumn;
        tileColumn++
      ) {
        final summary = summaries[PatternTileCoordinate(tileRow, tileColumn)];
        if (summary != null) yield summary;
      }
    }
  }

  /// Builds immutable symbol aggregates for one overview resolution.
  static Map<PatternTileCoordinate, PatternTileSummary> _buildSummaries(
    Iterable<StitchCell> cells,
    int blockSize,
  ) {
    final mutableCounts = <PatternTileCoordinate, Map<String, int>>{};
    for (final cell in cells) {
      final coordinate = PatternTileCoordinate(
        cell.coordinate.row ~/ blockSize,
        cell.coordinate.column ~/ blockSize,
      );
      final counts = mutableCounts.putIfAbsent(
        coordinate,
        () => <String, int>{},
      );
      counts.update(cell.symbolId, (count) => count + 1, ifAbsent: () => 1);
    }
    return Map<PatternTileCoordinate, PatternTileSummary>.unmodifiable({
      for (final entry in mutableCounts.entries)
        entry.key: PatternTileSummary(
          coordinate: entry.key,
          blockSize: blockSize,
          symbolCounts: entry.value,
        ),
    });
  }

  /// Yields populated cells inside [bounds] without scanning off-screen tiles.
  Iterable<StitchCell> cellsIntersecting(GridBounds bounds) sync* {
    // Restrict the query before converting its endpoints into tile indices.
    final query = bounds.clampTo(dimensions);
    if (query.isEmpty) return;

    // Inclusive tile endpoints cover every tile touched by the half-open query.
    final firstTileRow = query.startRow ~/ tileSize;
    final lastTileRow = (query.endRow - 1) ~/ tileSize;
    final firstTileColumn = query.startColumn ~/ tileSize;
    final lastTileColumn = (query.endColumn - 1) ~/ tileSize;
    for (var tileRow = firstTileRow; tileRow <= lastTileRow; tileRow++) {
      for (
        var tileColumn = firstTileColumn;
        tileColumn <= lastTileColumn;
        tileColumn++
      ) {
        final tileCells = _cellsByTile[(tileRow, tileColumn)];
        if (tileCells == null) continue;
        for (final cell in tileCells) {
          if (query.contains(cell.coordinate)) yield cell;
        }
      }
    }
  }

  /// Validates dimensions, cell bounds, uniqueness, and confidence values.
  void validate() {
    dimensions.validate();
    final seen = <GridCoordinate>{};
    for (final cell in cells) {
      cell.coordinate.validate();
      if (!dimensions.contains(cell.coordinate)) {
        throw DocumentValidationException(
          'Cell coordinate ${cell.coordinate} is outside the grid.',
        );
      }
      if (!seen.add(cell.coordinate)) {
        throw DocumentValidationException(
          'Duplicate cell coordinate ${cell.coordinate}.',
        );
      }
      cell.confidence?.validate();
    }
  }
}

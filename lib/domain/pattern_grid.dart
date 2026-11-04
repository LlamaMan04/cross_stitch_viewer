import 'domain_error.dart';
import 'value_objects.dart';

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

/// Sparse populated cells together with the full rectangular grid dimensions.
class PatternGrid {
  /// Creates a grid and copies [cells] into an unmodifiable list.
  PatternGrid({required this.dimensions, required Iterable<StitchCell> cells}) {
    final immutableCells = List<StitchCell>.unmodifiable(cells);
    this.cells = immutableCells;
    _cellsByCoordinate = Map.unmodifiable({
      for (final cell in immutableCells) cell.coordinate: cell,
    });
  }

  /// Full grid extent, including coordinates without stitches.
  final PatternDimensions dimensions;

  /// Cells containing stitches; unlisted coordinates are empty.
  late final List<StitchCell> cells;

  /// Direct coordinate lookup for populated cells.
  late final Map<GridCoordinate, StitchCell> _cellsByCoordinate;

  /// Finds the populated cell at [coordinate], or returns null if empty.
  StitchCell? cellAt(GridCoordinate coordinate) =>
      _cellsByCoordinate[coordinate];

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

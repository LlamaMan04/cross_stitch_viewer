import 'domain_error.dart';

/// Zero-based row and column identifying one global pattern cell.
class GridCoordinate {
  /// Creates a coordinate; call [validate] before using untrusted values.
  const GridCoordinate(this.row, this.column);

  /// Zero-based vertical cell index.
  final int row;

  /// Zero-based horizontal cell index.
  final int column;

  /// Rejects negative coordinates.
  void validate() {
    if (row < 0 || column < 0) {
      throw const DocumentValidationException(
        'Grid coordinates must be zero-based and non-negative.',
      );
    }
  }

  /// Compares coordinates by row and column.
  @override
  bool operator ==(Object other) =>
      other is GridCoordinate && row == other.row && column == other.column;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode => Object.hash(row, column);

  /// Human-readable coordinate notation for diagnostics.
  @override
  String toString() => '($row, $column)';
}

/// Positive row and column counts defining the full rectangular grid.
class PatternDimensions {
  /// Creates dimensions; call [validate] before accepting untrusted values.
  const PatternDimensions(this.rows, this.columns);

  /// Total number of rows in the pattern.
  final int rows;

  /// Total number of columns in the pattern.
  final int columns;

  /// Rejects empty or negative grid extents.
  void validate() {
    if (rows <= 0 || columns <= 0) {
      throw const DocumentValidationException(
        'Pattern dimensions must be positive.',
      );
    }
  }

  /// Returns whether [coordinate] lies inside these dimensions.
  bool contains(GridCoordinate coordinate) =>
      coordinate.row >= 0 &&
      coordinate.row < rows &&
      coordinate.column >= 0 &&
      coordinate.column < columns;
}

/// Confidence score normalized to the inclusive range from zero to one.
class Confidence {
  /// Creates a score; call [validate] before accepting untrusted values.
  const Confidence(this.value);

  /// Confidence score, where zero means no confidence and one means certain.
  final double value;

  /// Rejects non-finite or out-of-range scores.
  void validate() {
    if (!value.isFinite || value < 0 || value > 1) {
      throw const DocumentValidationException(
        'Confidence must be a finite value from 0 to 1.',
      );
    }
  }
}

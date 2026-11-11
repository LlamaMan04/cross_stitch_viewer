import 'domain_error.dart';
import 'pattern_definitions.dart';
import 'value_objects.dart';

/// A fractional row and column position on the pattern grid line lattice.
class BackstitchCoordinate {
  /// Creates a pattern-space coordinate; call [validate] for untrusted values.
  const BackstitchCoordinate({required this.row, required this.column});

  /// Vertical pattern-space position measured from the upper grid edge.
  final double row;

  /// Horizontal pattern-space position measured from the left grid edge.
  final double column;

  /// Rejects endpoint components that cannot be rendered reliably.
  void validate() {
    if (!row.isFinite || !column.isFinite) {
      throw const DocumentValidationException(
        'Backstitch coordinates must be finite.',
      );
    }
  }

  /// Compares coordinates by their pattern-space components.
  @override
  bool operator ==(Object other) =>
      other is BackstitchCoordinate &&
      row == other.row &&
      column == other.column;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode => Object.hash(row, column);

  /// Human-readable coordinate notation for diagnostics.
  @override
  String toString() => '($row, $column)';
}

/// One linear outline or detail stitch drawn between two pattern coordinates.
class BackstitchSegment {
  /// Creates a backstitch segment with thread and optional import data.
  const BackstitchSegment({
    required this.id,
    required this.start,
    required this.end,
    required this.thread,
    this.confidence,
    this.needsReview = false,
    this.provenanceId,
  });

  /// Stable segment ID used for selection and persistence.
  final String id;

  /// Pattern-space coordinate at which the rendered line begins.
  final BackstitchCoordinate start;

  /// Pattern-space coordinate at which the rendered line ends.
  final BackstitchCoordinate end;

  /// Exact thread information that supplies this segment's rendered color.
  final ThreadDefinition thread;

  /// Parser confidence when the segment was imported.
  final Confidence? confidence;

  /// Whether the user or parser flagged this segment for confirmation.
  final bool needsReview;

  /// ID of the source region that supplied this segment.
  final String? provenanceId;

  /// Validates segment-specific IDs, geometry, and optional confidence.
  void validate() {
    if (id.isEmpty) {
      throw const DocumentValidationException(
        'Backstitch segment ID is required.',
      );
    }
    start.validate();
    end.validate();
    if (start == end) {
      throw const DocumentValidationException(
        'Backstitch segment endpoints must be distinct.',
      );
    }
    thread.validate();
    confidence?.validate();
  }
}

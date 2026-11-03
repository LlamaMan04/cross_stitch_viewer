import 'value_objects.dart';

/// User-facing importance assigned to a parser diagnostic.
enum DiagnosticSeverity {
  /// Informational note that does not require action.
  info,

  /// Potential issue that may need review.
  warning,

  /// Blocking or invalid condition in parsed data.
  error,
}

/// Parser stage that produced a diagnostic.
enum DiagnosticStage {
  /// Input checks and source inspection.
  input,

  /// Extraction of text, vectors, or images from source pages.
  extraction,

  /// Classification of pages or regions by purpose.
  classification,

  /// Reading the symbol and thread legend.
  legend,

  /// Detecting and calibrating the stitch grid.
  grid,

  /// Interpreting symbols within grid cells.
  symbols,

  /// Combining regions or pages into global coordinates.
  splicing,

  /// Final checks on the normalized document.
  validation,
}

/// Maps a source page or panel into the document's global grid coordinates.
class PatternRegion {
  /// Creates a source mapping with a global grid origin and extent.
  const PatternRegion({
    required this.id,
    required this.sourcePage,
    required this.origin,
    required this.rows,
    required this.columns,
    this.label,
  });

  /// Stable provenance ID referenced by cells and diagnostics.
  final String id;

  /// Zero-based source document page number.
  final int sourcePage;

  /// Global top-left grid coordinate occupied by this region.
  final GridCoordinate origin;

  /// Number of global grid rows covered by this region.
  final int rows;

  /// Number of global grid columns covered by this region.
  final int columns;

  /// Optional page or panel label from the source.
  final String? label;
}

/// Structured parser issue that can be shown or linked to a pattern location.
class ParserDiagnostic {
  /// Creates a diagnostic with optional source and grid location details.
  const ParserDiagnostic({
    required this.severity,
    required this.stage,
    required this.message,
    this.coordinate,
    this.sourcePage,
    this.regionId,
    this.confidence,
    this.suggestedCorrection,
  });

  /// Severity used to determine how prominently this issue is presented.
  final DiagnosticSeverity severity;

  /// Parser stage that reported the issue.
  final DiagnosticStage stage;

  /// Short explanation of the parser finding.
  final String message;

  /// Global grid coordinate affected by the finding, if any.
  final GridCoordinate? coordinate;

  /// Source page affected by the finding, if any.
  final int? sourcePage;

  /// Provenance region affected by the finding, if any.
  final String? regionId;

  /// Confidence associated with the parser finding, if available.
  final Confidence? confidence;

  /// Suggested action for resolving or reviewing the issue.
  final String? suggestedCorrection;
}

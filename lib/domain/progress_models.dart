import 'domain_error.dart';
import 'value_objects.dart';

/// Saved zoom and pan information used to restore the pattern workspace.
class ViewportState {
  /// Creates a viewport snapshot anchored to a stable grid coordinate.
  const ViewportState({
    required this.zoom,
    required this.panX,
    required this.panY,
    required this.anchor,
    this.visibleRows,
    this.visibleColumns,
  });

  /// Scale factor used to draw each grid cell.
  final double zoom;

  /// Horizontal pan offset in the renderer's coordinate system.
  final double panX;

  /// Vertical pan offset in the renderer's coordinate system.
  final double panY;

  /// Grid coordinate used as the stable restoration anchor.
  final GridCoordinate anchor;

  /// Optional count of visible grid rows at save time.
  final int? visibleRows;

  /// Optional count of visible grid columns at save time.
  final int? visibleColumns;

  /// Rejects non-finite offsets, non-positive zoom, and invalid bounds.
  void validate() {
    if (!zoom.isFinite ||
        zoom <= 0 ||
        !panX.isFinite ||
        !panY.isFinite ||
        (visibleRows != null && visibleRows! <= 0) ||
        (visibleColumns != null && visibleColumns! <= 0)) {
      throw const DocumentValidationException('Invalid viewport values.');
    }
    anchor.validate();
  }
}

/// User-created visual reference attached to a pattern coordinate.
class LocationMarker {
  /// Creates a marker with a label, color, opacity, and optional note.
  const LocationMarker({
    required this.id,
    required this.coordinate,
    required this.label,
    required this.color,
    this.opacity = 1,
    this.visible = true,
    this.note,
  });

  /// Stable marker identity within the progress record.
  final String id;

  /// Text shown beside the marker.
  final String label;

  /// Marker color in `#RRGGBB` notation.
  final String color;

  /// Global grid cell marked by this annotation.
  final GridCoordinate coordinate;

  /// Transparency from fully transparent `0` to opaque `1`.
  final double opacity;

  /// Whether the marker is currently shown in the workspace.
  final bool visible;

  /// Optional user note associated with the marker.
  final String? note;

  /// Ensures the marker has valid identity, position, color, and opacity.
  void validate() {
    coordinate.validate();
    if (id.isEmpty ||
        label.isEmpty ||
        !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color) ||
        !opacity.isFinite ||
        opacity < 0 ||
        opacity > 1) {
      throw const DocumentValidationException('Invalid location marker.');
    }
  }
}

/// Mutable user state stored separately from imported pattern data.
class ProgressState {
  /// Creates an immutable snapshot of completion, markers, and viewport state.
  ProgressState({
    required this.documentId,
    required this.schemaVersion,
    required Iterable<GridCoordinate> completedCells,
    Iterable<LocationMarker> markers = const [],
    this.viewport,
    required this.lastInteractionAt,
  }) {
    this.completedCells = List.unmodifiable(completedCells);
    this.markers = List.unmodifiable(markers);
    _completedCellSet = Set.unmodifiable(this.completedCells);
    _markersById = Map.unmodifiable(
      {for (final marker in this.markers) marker.id: marker},
    );
  }

  /// ID of the pattern document this progress belongs to.
  final String documentId;

  /// Version of the mutable progress contract.
  final int schemaVersion;

  /// Coordinates the user has marked complete.
  late final List<GridCoordinate> completedCells;

  /// Direct membership index for completed coordinates.
  late final Set<GridCoordinate> _completedCellSet;

  /// User annotations attached to pattern locations.
  late final List<LocationMarker> markers;

  /// Direct marker lookup by stable ID.
  late final Map<String, LocationMarker> _markersById;

  /// Last saved workspace viewport, if available.
  final ViewportState? viewport;

  /// UTC timestamp of the most recent progress interaction.
  final DateTime lastInteractionAt;

  /// Returns whether [coordinate] is marked complete.
  bool isCellCompleted(GridCoordinate coordinate) =>
      _completedCellSet.contains(coordinate);

  /// Returns the marker with [id], if the progress state defines one.
  LocationMarker? markerById(String id) => _markersById[id];

  /// Checks identity, timestamp, unique coordinates/markers, and nested values.
  void validate() {
    if (documentId.isEmpty || schemaVersion <= 0 || !lastInteractionAt.isUtc) {
      throw const DocumentValidationException(
        'Invalid progress identity, schema version, or timestamp.',
      );
    }
    if (_completedCellSet.length != completedCells.length) {
      throw const DocumentValidationException(
        'Progress coordinates must be unique within each state.',
      );
    }
    for (final marker in markers) {
      marker.validate();
    }
    if (_markersById.length != markers.length) {
      throw const DocumentValidationException('Marker IDs must be unique.');
    }
    viewport?.validate();
  }
}

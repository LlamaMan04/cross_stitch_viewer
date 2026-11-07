import 'domain_error.dart';
import 'value_objects.dart';

/// Allowed solid colors for pattern grid rules.
enum GridColorPreset {
  /// Solid black grid rules.
  black('#000000'),

  /// Dark-gray grid rules for reduced contrast.
  darkGray('#444444'),

  /// Light-gray grid rules for a softer appearance.
  lightGray('#A0A0A0');

  /// Creates a preset with its canonical persisted RGB value.
  const GridColorPreset(this.colorHex);

  /// Canonical `#RRGGBB` value persisted for this preset.
  final String colorHex;

  /// Resolves a persisted RGB value to its supported preset.
  static GridColorPreset fromColorHex(String value) => values.firstWhere(
    (preset) => preset.colorHex == value,
    orElse: () => throw const DocumentValidationException(
      'Unsupported grid color preset.',
    ),
  );
}

/// Allowed fill colors for the selected-symbol cell highlight.
enum SelectionHighlightColorPreset {
  /// Warm amber highlight that contrasts with the default neutral surface.
  amber('#FFC107'),

  /// Teal highlight for a cool visual treatment.
  teal('#00A6A6'),

  /// Magenta highlight for a vivid visual treatment.
  magenta('#C2185B');

  /// Creates a preset with its canonical persisted RGB value.
  const SelectionHighlightColorPreset(this.colorHex);

  /// Canonical `#RRGGBB` value persisted for this preset.
  final String colorHex;

  /// Resolves a persisted RGB value to its supported preset.
  static SelectionHighlightColorPreset fromColorHex(String value) =>
      values.firstWhere(
        (preset) => preset.colorHex == value,
        orElse: () => throw const DocumentValidationException(
          'Unsupported selection highlight color preset.',
        ),
      );
}

/// Immutable visual settings stored with one pattern viewport.
class PatternRenderSettings {
  /// Creates settings with the documented initial renderer behavior.
  const PatternRenderSettings({
    this.showCellColor = false,
    this.showSymbols = true,
    this.showGrid = true,
    this.cellColorOpacity = 0.22,
    this.gridColor = GridColorPreset.black,
    this.selectionHighlightColor = SelectionHighlightColorPreset.amber,
    this.showRegions = false,
  });

  /// Whether populated cells use their imported thread colors.
  final bool showCellColor;

  /// Whether legible cells display their symbol glyphs.
  final bool showSymbols;

  /// Whether minor, major, and outside grid rules are visible.
  final bool showGrid;

  /// Alpha applied to enabled thread-color cell fills.
  final double cellColorOpacity;

  /// Preset color used for every visible grid rule.
  final GridColorPreset gridColor;

  /// Preset color used to fill cells sharing the selected symbol.
  final SelectionHighlightColorPreset selectionHighlightColor;

  /// Whether visible source-region outlines are displayed.
  final bool showRegions;

  /// Returns settings with only explicitly supplied fields replaced.
  PatternRenderSettings copyWith({
    bool? showCellColor,
    bool? showSymbols,
    bool? showGrid,
    double? cellColorOpacity,
    GridColorPreset? gridColor,
    SelectionHighlightColorPreset? selectionHighlightColor,
    bool? showRegions,
  }) => PatternRenderSettings(
    showCellColor: showCellColor ?? this.showCellColor,
    showSymbols: showSymbols ?? this.showSymbols,
    showGrid: showGrid ?? this.showGrid,
    cellColorOpacity: cellColorOpacity ?? this.cellColorOpacity,
    gridColor: gridColor ?? this.gridColor,
    selectionHighlightColor:
        selectionHighlightColor ?? this.selectionHighlightColor,
    showRegions: showRegions ?? this.showRegions,
  );

  /// Rejects non-finite or out-of-range opacity values.
  void validate() {
    if (!cellColorOpacity.isFinite ||
        cellColorOpacity < 0 ||
        cellColorOpacity > 1) {
      throw const DocumentValidationException(
        'Cell color opacity must be from zero through one.',
      );
    }
  }

  /// Compares settings by every persisted visual field.
  @override
  bool operator ==(Object other) =>
      other is PatternRenderSettings &&
      showCellColor == other.showCellColor &&
      showSymbols == other.showSymbols &&
      showGrid == other.showGrid &&
      cellColorOpacity == other.cellColorOpacity &&
      gridColor == other.gridColor &&
      selectionHighlightColor == other.selectionHighlightColor &&
      showRegions == other.showRegions;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode => Object.hash(
    showCellColor,
    showSymbols,
    showGrid,
    cellColorOpacity,
    gridColor,
    selectionHighlightColor,
    showRegions,
  );
}

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
    this.renderSettings = const PatternRenderSettings(),
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

  /// Persisted visual settings for this pattern viewport.
  final PatternRenderSettings renderSettings;

  /// Returns a snapshot with supplied camera or render fields replaced.
  ViewportState copyWith({
    double? zoom,
    double? panX,
    double? panY,
    GridCoordinate? anchor,
    int? visibleRows,
    int? visibleColumns,
    PatternRenderSettings? renderSettings,
  }) => ViewportState(
    zoom: zoom ?? this.zoom,
    panX: panX ?? this.panX,
    panY: panY ?? this.panY,
    anchor: anchor ?? this.anchor,
    visibleRows: visibleRows ?? this.visibleRows,
    visibleColumns: visibleColumns ?? this.visibleColumns,
    renderSettings: renderSettings ?? this.renderSettings,
  );

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
    renderSettings.validate();
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
    _markersById = Map.unmodifiable({
      for (final marker in this.markers) marker.id: marker,
    });
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

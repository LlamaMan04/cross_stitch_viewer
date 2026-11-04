import 'package:drift/drift.dart';

import '../../domain/progress_models.dart';
import '../../domain/value_objects.dart';
import 'app_database.dart';

/// Converts mutable user state to and from Drift's typed rows.
abstract final class ProgressMapper {
  /// Maps the progress root, storing its interaction time in UTC.
  static ProgressStatesCompanion progress(ProgressState value) =>
      ProgressStatesCompanion.insert(
        documentId: value.documentId,
        schemaVersion: value.schemaVersion,
        lastInteractionAt: value.lastInteractionAt.toUtc(),
      );

  /// Maps completed grid coordinates.
  static List<CompletedCellsCompanion> completedCells(ProgressState value) => [
    for (final coordinate in value.completedCells)
      CompletedCellsCompanion.insert(
        documentId: value.documentId,
        gridRow: coordinate.row,
        gridColumn: coordinate.column,
      ),
  ];

  /// Maps ordered user markers.
  static List<LocationMarkersCompanion> markers(ProgressState value) => [
    for (var index = 0; index < value.markers.length; index++)
      LocationMarkersCompanion.insert(
        documentId: value.documentId,
        id: value.markers[index].id,
        sortOrder: index,
        gridRow: value.markers[index].coordinate.row,
        gridColumn: value.markers[index].coordinate.column,
        label: value.markers[index].label,
        color: value.markers[index].color,
        opacity: value.markers[index].opacity,
        visible: Value(value.markers[index].visible),
        note: Value(value.markers[index].note),
      ),
  ];

  /// Maps an optional viewport snapshot.
  static ViewportStatesCompanion? viewport(ProgressState value) {
    final viewport = value.viewport;
    if (viewport == null) return null;
    return ViewportStatesCompanion.insert(
      documentId: value.documentId,
      zoom: viewport.zoom,
      panX: viewport.panX,
      panY: viewport.panY,
      anchorRow: viewport.anchor.row,
      anchorColumn: viewport.anchor.column,
      visibleRows: Value(viewport.visibleRows),
      visibleColumns: Value(viewport.visibleColumns),
    );
  }

  /// Reconstructs and validates user state from its related rows.
  static ProgressState fromRows({
    required ProgressStateRow progress,
    required List<CompletedCellRow> completedCells,
    required List<LocationMarkerRow> markers,
    required ViewportStateRow? viewport,
  }) {
    final value = ProgressState(
      documentId: progress.documentId,
      schemaVersion: progress.schemaVersion,
      completedCells: [
        for (final row in completedCells)
          GridCoordinate(row.gridRow, row.gridColumn),
      ],
      markers: [
        for (final row in markers)
          LocationMarker(
            id: row.id,
            coordinate: GridCoordinate(row.gridRow, row.gridColumn),
            label: row.label,
            color: row.color,
            opacity: row.opacity,
            visible: row.visible,
            note: row.note,
          ),
      ],
      viewport: viewport == null
          ? null
          : ViewportState(
              zoom: viewport.zoom,
              panX: viewport.panX,
              panY: viewport.panY,
              anchor: GridCoordinate(viewport.anchorRow, viewport.anchorColumn),
              visibleRows: viewport.visibleRows,
              visibleColumns: viewport.visibleColumns,
            ),
      lastInteractionAt: progress.lastInteractionAt.toUtc(),
    );
    value.validate();
    return value;
  }
}

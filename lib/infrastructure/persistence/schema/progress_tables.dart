import 'package:drift/drift.dart';

import 'pattern_tables.dart';

/// Stores the root record for mutable user progress on one document.
@DataClassName('ProgressStateRow')
class ProgressStates extends Table {
  /// Defines the pattern document whose progress is stored.
  TextColumn get documentId =>
      text().references(PatternDocuments, #id, onDelete: KeyAction.cascade)();

  /// Defines the independent portable progress schema version.
  IntColumn get schemaVersion => integer()();

  /// Defines the UTC instant of the most recent progress interaction.
  DateTimeColumn get lastInteractionAt => dateTime()();

  /// Allows one mutable progress graph per pattern document.
  @override
  Set<Column<Object>> get primaryKey => {documentId};

  /// Links progress to its document and validates the schema version.
  @override
  List<String> get customConstraints => const ['CHECK (schema_version > 0)'];
}

/// Stores coordinates the user has marked complete.
@DataClassName('CompletedCellRow')
class CompletedCells extends Table {
  /// Defines the parent progress record and pattern document.
  TextColumn get documentId => text()();

  /// Defines the zero-based global grid row.
  IntColumn get gridRow => integer()();

  /// Defines the zero-based global grid column.
  IntColumn get gridColumn => integer()();

  /// Allows at most one completion record at a global coordinate.
  @override
  Set<Column<Object>> get primaryKey => {documentId, gridRow, gridColumn};

  /// Links completed coordinates to progress and validates their bounds.
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY (document_id) REFERENCES progress_states(document_id) '
        'ON DELETE CASCADE',
    'CHECK (grid_row >= 0)',
    'CHECK (grid_column >= 0)',
  ];
}

/// Stores user-created location markers separately from imported pattern data.
@DataClassName('LocationMarkerRow')
class LocationMarkers extends Table {
  /// Defines the parent progress record and pattern document.
  TextColumn get documentId => text()();

  /// Defines the stable marker identifier within the progress record.
  TextColumn get id => text()();

  /// Preserves marker order in the portable progress document.
  IntColumn get sortOrder => integer()();

  /// Defines the zero-based global anchor row.
  IntColumn get gridRow => integer()();

  /// Defines the zero-based global anchor column.
  IntColumn get gridColumn => integer()();

  /// Defines the user-facing marker label.
  TextColumn get label => text()();

  /// Defines the marker color in canonical `#RRGGBB` notation.
  TextColumn get color => text()();

  /// Defines marker transparency from zero through one.
  RealColumn get opacity => real()();

  /// Defines whether the marker is visible in the workspace.
  BoolColumn get visible => boolean().withDefault(const Constant(true))();

  /// Defines an optional user note associated with the marker.
  TextColumn get note => text().nullable()();

  /// Uniquely identifies a marker within its parent progress record.
  @override
  Set<Column<Object>> get primaryKey => {documentId, id};

  /// Links markers to progress and validates their grid coordinate.
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY (document_id) REFERENCES progress_states(document_id) '
        'ON DELETE CASCADE',
    'UNIQUE (document_id, sort_order)',
    'CHECK (length(id) > 0)',
    'CHECK (sort_order >= 0)',
    'CHECK (length(label) > 0)',
    "CHECK (color GLOB '#[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]"
        "[0-9A-Fa-f][0-9A-Fa-f][0-9A-Fa-f]')",
    'CHECK (opacity >= 0 AND opacity <= 1)',
    'CHECK (grid_row >= 0)',
    'CHECK (grid_column >= 0)',
  ];
}

/// Stores the optional viewport snapshot for one progress record.
@DataClassName('ViewportStateRow')
class ViewportStates extends Table {
  /// Defines the parent progress record and pattern document.
  TextColumn get documentId => text()();

  /// Defines the positive renderer scale factor.
  RealColumn get zoom => real()();

  /// Defines the finite horizontal renderer offset.
  RealColumn get panX => real()();

  /// Defines the finite vertical renderer offset.
  RealColumn get panY => real()();

  /// Defines the stable zero-based anchor row.
  IntColumn get anchorRow => integer()();

  /// Defines the stable zero-based anchor column.
  IntColumn get anchorColumn => integer()();

  /// Defines the optional number of visible rows at save time.
  IntColumn get visibleRows => integer().nullable()();

  /// Defines the optional number of visible columns at save time.
  IntColumn get visibleColumns => integer().nullable()();

  /// Allows at most one viewport snapshot for a progress record.
  @override
  Set<Column<Object>> get primaryKey => {documentId};

  /// Links the viewport to progress and validates its numeric bounds.
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY (document_id) REFERENCES progress_states(document_id) '
        'ON DELETE CASCADE',
    'CHECK (zoom > 0)',
    'CHECK (anchor_row >= 0)',
    'CHECK (anchor_column >= 0)',
    'CHECK (visible_rows IS NULL OR visible_rows > 0)',
    'CHECK (visible_columns IS NULL OR visible_columns > 0)',
  ];
}

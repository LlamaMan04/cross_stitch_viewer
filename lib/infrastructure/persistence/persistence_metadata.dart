import 'package:drift/drift.dart';

/// Holds operational database metadata that is independent of application data.
class PersistenceMetadata extends Table {
  /// Defines the unique metadata name.
  TextColumn get key => text()();

  /// Defines the serialized value associated with [key].
  TextColumn get value => text()();

  /// Makes each metadata name unique within the local database.
  @override
  Set<Column<Object>> get primaryKey => {key};
}

import 'package:drift/drift.dart';

/// Applies ordered schema changes for databases created by earlier app versions.
Future<void> migrateAppDatabase(Migrator migrator, int from, int to) async {
  // Schema version 1 remains the initial, unreleased schema. No migration is
  // registered until a later schema version is intentionally introduced.
  if (from >= to) {
    return;
  }
}

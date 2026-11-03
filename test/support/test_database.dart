import 'package:drift/native.dart';
import 'package:stitch_scope/infrastructure/persistence/app_database.dart';

/// Opens an isolated, in-memory database for persistence tests.
AppDatabase openTestDatabase() {
  return AppDatabase(NativeDatabase.memory());
}

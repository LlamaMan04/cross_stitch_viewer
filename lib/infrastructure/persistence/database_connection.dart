import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Creates the lazily opened SQLite executor used by production application runs.
LazyDatabase openAppDatabaseConnection() {
  return LazyDatabase(() async {
    // Application support is writable without exposing the database to users.
    final directory = await getApplicationSupportDirectory();
    final databaseFile = File(path.join(directory.path, 'stitch_scope.sqlite'));

    return NativeDatabase.createInBackground(
      databaseFile,
      logStatements: kDebugMode,
    );
  });
}

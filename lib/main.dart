import 'package:flutter/material.dart';

import 'app/app_dependencies.dart';
import 'app/stitch_scope_app.dart';

/// Starts StitchScope with its root application widget.
void main() {
  final dependencies = AppDependencies.open();
  runApp(
    StitchScopeApp(
      patternDocuments: dependencies.patternDocuments,
      progress: dependencies.progress,
    ),
  );
}

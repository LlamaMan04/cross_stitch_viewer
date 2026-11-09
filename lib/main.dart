import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_dependencies.dart';
import 'app/stitch_scope_app.dart';

/// Starts StitchScope with its root application widget.
void main() {
  // On Android, hide the system UI (status bar and navigation bar)
  if (defaultTargetPlatform == TargetPlatform.android) {
    WidgetsFlutterBinding.ensureInitialized();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }
  final dependencies = AppDependencies.open();
  runApp(
    StitchScopeApp(
      patternDocuments: dependencies.patternDocuments,
      progress: dependencies.progress,
    ),
  );
}

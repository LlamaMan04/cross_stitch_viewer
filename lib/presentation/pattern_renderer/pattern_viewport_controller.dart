import 'package:flutter/foundation.dart';

import 'pattern_camera.dart';
import 'render_lod.dart';

/// Notifies the renderer when camera movement requires a new paint frame.
class PatternViewportController extends ChangeNotifier {
  /// Creates a controller from the viewport's initial fitted camera.
  PatternViewportController({required PatternCamera camera})
    : _camera = camera,
      _renderLod = resolveRenderLod(cellSize: camera.cellSize);

  /// Camera used by interaction hit testing and the current paint frame.
  PatternCamera _camera;

  /// Hysteretic detail level retained across camera updates.
  RenderLod _renderLod;

  /// Current immutable camera value.
  PatternCamera get camera => _camera;

  /// Current detail level resolved from [camera].
  RenderLod get renderLod => _renderLod;

  /// Applies an interaction camera and requests only a renderer repaint.
  void updateCamera(PatternCamera camera) {
    if (camera == _camera) return;
    _camera = camera;
    _renderLod = resolveRenderLod(
      cellSize: camera.cellSize,
      previous: _renderLod,
    );
    notifyListeners();
  }

  /// Replaces layout-derived geometry while the widget is already rebuilding.
  void replaceCameraForLayout(PatternCamera camera) {
    if (camera == _camera) return;
    _camera = camera;
    _renderLod = resolveRenderLod(
      cellSize: camera.cellSize,
      previous: _renderLod,
    );
  }
}

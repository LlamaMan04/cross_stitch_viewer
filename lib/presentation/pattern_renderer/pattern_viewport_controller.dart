import 'package:flutter/foundation.dart';

import 'pattern_camera.dart';
import 'render_lod.dart';

/// Describes the camera activity represented by the current paint frame.
enum PatternViewportInteractionState {
  /// The camera is stable and cache population may proceed normally.
  settled,

  /// The camera origin is moving while its scale remains unchanged.
  panning,

  /// The camera scale is changing continuously.
  zooming,
}

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

  /// Activity associated with camera updates driving the current paint frame.
  PatternViewportInteractionState _interactionState =
      PatternViewportInteractionState.settled;

  /// Current immutable camera value.
  PatternCamera get camera => _camera;

  /// Current detail level resolved from [camera].
  RenderLod get renderLod => _renderLod;

  /// Activity associated with the current renderer frame.
  PatternViewportInteractionState get interactionState => _interactionState;

  /// Marks upcoming camera updates as same-scale panning work.
  void beginPanning() =>
      _setInteractionState(PatternViewportInteractionState.panning);

  /// Marks upcoming camera updates as continuous zoom work.
  void beginZooming() =>
      _setInteractionState(PatternViewportInteractionState.zooming);

  /// Marks the camera as stable after an interaction ends.
  void settleInteraction() =>
      _setInteractionState(PatternViewportInteractionState.settled);

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

  /// Requests a paint without changing camera geometry or rebuilding widgets.
  void requestRepaint() {
    notifyListeners();
  }

  /// Updates interaction state and repaints when the state changes alone.
  void _setInteractionState(PatternViewportInteractionState value) {
    if (_interactionState == value) return;
    _interactionState = value;
    notifyListeners();
  }
}

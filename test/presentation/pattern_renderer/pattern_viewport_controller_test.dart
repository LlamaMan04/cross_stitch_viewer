import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_camera.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_viewport_controller.dart';

/// Verifies camera notification behavior used by notifier-driven painting.
void main() {
  test('notifies only when the camera or repaint request changes', () {
    final controller = PatternViewportController(
      camera: const PatternCamera(cellSize: 10, origin: Offset.zero),
    );
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    controller.updateCamera(controller.camera);
    expect(notifications, 0);

    controller.updateCamera(
      const PatternCamera(cellSize: 12, origin: Offset.zero),
    );
    expect(notifications, 1);

    controller.requestRepaint();
    expect(notifications, 2);
  });

  test('reports explicit settled, pan, and zoom interaction states', () {
    final controller = PatternViewportController(
      camera: const PatternCamera(cellSize: 10, origin: Offset.zero),
    );
    addTearDown(controller.dispose);

    expect(
      controller.interactionState,
      PatternViewportInteractionState.settled,
    );

    controller.beginPanning();
    expect(
      controller.interactionState,
      PatternViewportInteractionState.panning,
    );

    controller.beginZooming();
    expect(
      controller.interactionState,
      PatternViewportInteractionState.zooming,
    );

    controller.settleInteraction();
    expect(
      controller.interactionState,
      PatternViewportInteractionState.settled,
    );
  });
}

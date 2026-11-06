import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../domain/pattern_document.dart';
import 'pattern_camera.dart';
import 'viewport_pattern_painter.dart';

/// Interactive viewport that owns camera gestures and visible-only painting.
class PatternViewport extends StatefulWidget {
  /// Creates a viewport for an immutable normalized pattern document.
  const PatternViewport({required this.document, super.key});

  /// Pattern document displayed by the viewport.
  final PatternDocument document;

  /// Creates the mutable camera state for this viewport.
  @override
  State<PatternViewport> createState() => _PatternViewportState();
}

/// Owns camera initialization, resizing, panning, and focal-point zoom.
class _PatternViewportState extends State<PatternViewport> {
  /// Current camera, initialized after the viewport receives a layout size.
  PatternCamera? _camera;

  /// Camera snapshot captured at the start of a scale gesture.
  PatternCamera? _gestureStartCamera;

  /// Focal point captured at the start of a scale gesture.
  Offset _gestureStartFocalPoint = Offset.zero;

  /// Most recent non-empty viewport layout size.
  Size? _viewportSize;

  /// Resets the camera when a different document is placed in this viewport.
  @override
  void didUpdateWidget(covariant PatternViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) {
      _camera = null;
      _gestureStartCamera = null;
    }
  }

  /// Builds a fixed-size custom painter behind pan and zoom gesture handling.
  @override
  Widget build(BuildContext context) {
    // Resolve painter colors from the active application theme.
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Layout can briefly report zero; retain finite camera geometry.
        final viewportSize = Size(
          math.max(1, constraints.maxWidth),
          math.max(1, constraints.maxHeight),
        );
        _updateCameraForLayout(viewportSize);
        // Camera and bounds are immutable inputs for this paint pass.
        final camera = _camera!;
        final visibleBounds = camera.visibleBounds(
          viewportSize: viewportSize,
          dimensions: widget.document.grid.dimensions,
        );
        return Listener(
          key: const ValueKey('pattern-viewport'),
          onPointerSignal: _handlePointerSignal,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            child: CustomPaint(
              key: const ValueKey('pattern-grid-canvas'),
              painter: ViewportPatternPainter(
                document: widget.document,
                camera: camera,
                visibleBounds: visibleBounds,
                surfaceColor: colors.surfaceContainerLowest,
                gridColor: Colors.black,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  /// Initializes a fitted camera or clamps the existing camera after resize.
  void _updateCameraForLayout(Size viewportSize) {
    if (_camera == null) {
      _camera = PatternCamera.fit(
        dimensions: widget.document.grid.dimensions,
        viewportSize: viewportSize,
      );
    } else if (_viewportSize != viewportSize) {
      // A larger layout can raise the fitted minimum scale.
      final minimumCellSize = PatternCamera.minimumCellSizeFor(
        dimensions: widget.document.grid.dimensions,
        viewportSize: viewportSize,
      );
      final maximumCellSize = PatternCamera.maximumCellSizeFor(
        dimensions: widget.document.grid.dimensions,
        viewportSize: viewportSize,
      );
      if (_camera!.cellSize < minimumCellSize) {
        _camera = PatternCamera.fit(
          dimensions: widget.document.grid.dimensions,
          viewportSize: viewportSize,
        );
      } else {
        _camera =
            PatternCamera(
              cellSize: _camera!.cellSize.clamp(
                minimumCellSize,
                maximumCellSize,
              ),
              origin: _camera!.origin,
            ).clampTo(
              dimensions: widget.document.grid.dimensions,
              viewportSize: viewportSize,
            );
      }
    }
    _viewportSize = viewportSize;
  }

  /// Captures stable camera inputs for the duration of one scale gesture.
  void _handleScaleStart(ScaleStartDetails details) {
    _gestureStartCamera = _camera;
    _gestureStartFocalPoint = details.localFocalPoint;
  }

  /// Applies combined drag and pinch input from the gesture's initial camera.
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    // Gesture updates always derive from the same start snapshot.
    final startCamera = _gestureStartCamera;
    final viewportSize = _viewportSize;
    if (startCamera == null || viewportSize == null) return;

    // Preserve the initial grid point beneath the moving focal position.
    final gridPoint = startCamera.screenToGrid(_gestureStartFocalPoint);
    // The fit scale is the interaction floor for this exact viewport size.
    final minimumCellSize = PatternCamera.minimumCellSizeFor(
      dimensions: widget.document.grid.dimensions,
      viewportSize: viewportSize,
    );
    final maximumCellSize = PatternCamera.maximumCellSizeFor(
      dimensions: widget.document.grid.dimensions,
      viewportSize: viewportSize,
    );
    final nextCellSize = (startCamera.cellSize * details.scale).clamp(
      minimumCellSize,
      maximumCellSize,
    );
    // Combined focal movement and scale support both drag and pinch.
    final nextOrigin = Offset(
      details.localFocalPoint.dx - gridPoint.dx * nextCellSize,
      details.localFocalPoint.dy - gridPoint.dy * nextCellSize,
    );
    setState(() {
      _camera = PatternCamera(cellSize: nextCellSize, origin: nextOrigin)
          .clampTo(
            dimensions: widget.document.grid.dimensions,
            viewportSize: viewportSize,
          );
    });
  }

  /// Converts mouse-wheel movement into focal zoom at the pointer location.
  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || _camera == null) return;
    final viewportSize = _viewportSize;
    if (viewportSize == null) return;
    // Exponential scaling makes equal wheel deltas feel symmetric.
    final scale = math.exp(-event.scrollDelta.dy * 0.0015);
    setState(() {
      _camera = _camera!.zoomAround(
        focalPoint: event.localPosition,
        scale: scale,
        dimensions: widget.document.grid.dimensions,
        viewportSize: viewportSize,
      );
    });
  }
}

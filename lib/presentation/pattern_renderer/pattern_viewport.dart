import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/pattern_document.dart';
import '../../domain/progress_models.dart';
import '../../domain/value_objects.dart';
import 'pattern_camera.dart';
import 'pattern_interaction.dart';
import 'pattern_render_selection.dart';
import 'viewport_pattern_painter.dart';

/// Interactive viewport that owns camera gestures and visible-only painting.
class PatternViewport extends StatefulWidget {
  /// Creates a viewport for an immutable normalized pattern document.
  const PatternViewport({
    required this.document,
    required this.settings,
    required this.selection,
    required this.completedCells,
    required this.interactionMode,
    required this.completionSelection,
    this.onSymbolSelected,
    this.onCompletionCellSelected,
    this.onCompletionCellAdded,
    this.onCompletionEditUnavailable,
    this.onInteraction,
    super.key,
  });

  /// Pattern document displayed by the viewport.
  final PatternDocument document;

  /// Persisted visual settings applied without replacing camera state.
  final PatternRenderSettings settings;

  /// Ephemeral symbol selection highlighted without modifying pattern data.
  final PatternRenderSelection selection;

  /// Completed coordinates used by dynamic renderer overlays.
  final Set<GridCoordinate> completedCells;

  /// Active interpretation of taps inside the viewport.
  final PatternInteractionMode interactionMode;

  /// Exact cells selected for a pending completion action.
  final CompletionCellSelection completionSelection;

  /// Reports a tapped populated cell's symbol ID, or null for an empty cell.
  final ValueChanged<String?>? onSymbolSelected;

  /// Reports a populated coordinate tapped in completion-edit mode.
  final ValueChanged<GridCoordinate>? onCompletionCellSelected;

  /// Reports a populated coordinate crossed by an additive selection drag.
  final ValueChanged<GridCoordinate>? onCompletionCellAdded;

  /// Reports that completion editing requires a more legible zoom level.
  final VoidCallback? onCompletionEditUnavailable;

  /// Reports navigation or tap interaction so transient feedback can clear.
  final VoidCallback? onInteraction;

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

  /// Pointer currently driving an additive completion-selection drag.
  int? _selectionDragPointer;

  /// Coordinates already reported during the current additive drag.
  final Set<GridCoordinate> _selectionDragCoordinates = <GridCoordinate>{};

  /// Last local pointer position sampled by the additive drag.
  Offset? _selectionDragLastPosition;

  /// Whether zoom guidance was already reported for the active drag.
  bool _selectionDragUnavailableReported = false;

  /// Prevents a modifier click from being handled again as a normal tap.
  bool _suppressNextTap = false;

  /// Release time of the most recent unmodified tap or click.
  Duration? _lastTapTime;

  /// Release position of the most recent unmodified tap or click.
  Offset? _lastTapPosition;

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
          onPointerDown: _handlePointerDown,
          onPointerMove: _handlePointerMove,
          onPointerUp: _handlePointerUp,
          onPointerCancel: _handlePointerCancel,
          onPointerSignal: _handlePointerSignal,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            onTapUp:
                widget.onSymbolSelected == null &&
                    widget.onCompletionCellSelected == null
                ? null
                : _handleTapUp,
            child: CustomPaint(
              key: const ValueKey('pattern-grid-canvas'),
              painter: ViewportPatternPainter(
                document: widget.document,
                camera: camera,
                visibleBounds: visibleBounds,
                settings: widget.settings,
                selection: widget.selection,
                completedCells: widget.completedCells,
                completionSelection: widget.completionSelection.coordinates,
                surfaceColor: colors.surfaceContainerLowest,
                regionColor: colors.primary,
                completionSelectionColor: colors.primary,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );
      },
    );
  }

  /// Converts a tap into a populated cell's symbol selection.
  void _handleTapUp(TapUpDetails details) {
    if (_suppressNextTap) {
      _suppressNextTap = false;
      return;
    }
    widget.onInteraction?.call();
    final camera = _camera;
    if (camera == null) return;
    if (widget.interactionMode == PatternInteractionMode.editCompletion &&
        camera.cellSize < 12) {
      widget.onCompletionEditUnavailable?.call();
      return;
    }
    final gridPoint = camera.screenToGrid(details.localPosition);
    final coordinate = GridCoordinate(
      gridPoint.dy.floor(),
      gridPoint.dx.floor(),
    );
    if (!widget.document.grid.dimensions.contains(coordinate)) {
      if (widget.interactionMode == PatternInteractionMode.browse) {
        widget.onSymbolSelected?.call(null);
      }
      return;
    }
    final cell = widget.document.grid.cellAt(coordinate);
    if (widget.interactionMode == PatternInteractionMode.editCompletion) {
      if (cell != null) widget.onCompletionCellSelected?.call(coordinate);
      return;
    }
    widget.onSymbolSelected?.call(cell?.symbolId);
  }

  /// Begins an additive drag for a modifier or nearby second tap/click.
  void _handlePointerDown(PointerDownEvent event) {
    if (widget.interactionMode != PatternInteractionMode.editCompletion) {
      return;
    }
    if (_isSelectionModifierPressed) {
      _suppressNextTap = true;
      _beginSelectionDrag(event.pointer, event.localPosition);
      return;
    }
    {
      final lastTapTime = _lastTapTime;
      final lastTapPosition = _lastTapPosition;
      final isTimelySecondTap =
          lastTapTime != null &&
          event.timeStamp - lastTapTime <= const Duration(milliseconds: 300);
      final isNearbySecondTap =
          lastTapPosition != null &&
          (event.localPosition - lastTapPosition).distance <= 48;
      if (isTimelySecondTap && isNearbySecondTap) {
        _lastTapTime = null;
        _lastTapPosition = null;
        _beginSelectionDrag(event.pointer, event.localPosition);
      }
    }
  }

  /// Whether Control or Command is held for additive selection.
  bool get _isSelectionModifierPressed {
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    return pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight) ||
        pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.metaRight);
  }

  /// Starts one additive drag and reports its initial populated cell.
  void _beginSelectionDrag(int pointer, Offset localPosition) {
    widget.onInteraction?.call();
    _selectionDragPointer = pointer;
    _selectionDragCoordinates.clear();
    _selectionDragLastPosition = localPosition;
    _selectionDragUnavailableReported = false;
    _addCompletionCellAt(localPosition);
  }

  /// Adds newly crossed populated cells while the selection pointer moves.
  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _selectionDragPointer) return;
    final previousPosition = _selectionDragLastPosition;
    final camera = _camera;
    if (previousPosition == null || camera == null) return;
    final distance = (event.localPosition - previousPosition).distance;
    final sampleCount = math.max(1, (distance / (camera.cellSize / 2)).ceil());
    for (var sample = 1; sample <= sampleCount; sample++) {
      _addCompletionCellAt(
        Offset.lerp(
          previousPosition,
          event.localPosition,
          sample / sampleCount,
        )!,
      );
    }
    _selectionDragLastPosition = event.localPosition;
  }

  /// Ends the active additive drag after its pointer is released.
  void _handlePointerUp(PointerUpEvent event) {
    final endedSelectionDrag = event.pointer == _selectionDragPointer;
    if (endedSelectionDrag) _endSelectionDrag();
    if (!endedSelectionDrag &&
        widget.interactionMode == PatternInteractionMode.editCompletion) {
      _lastTapTime = event.timeStamp;
      _lastTapPosition = event.localPosition;
    }
  }

  /// Ends the active additive drag after its pointer is cancelled.
  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer == _selectionDragPointer) _endSelectionDrag();
    _lastTapTime = null;
    _lastTapPosition = null;
  }

  /// Clears transient state belonging to an additive drag.
  void _endSelectionDrag() {
    _selectionDragPointer = null;
    _selectionDragCoordinates.clear();
    _selectionDragLastPosition = null;
    _selectionDragUnavailableReported = false;
  }

  /// Reports the populated cell beneath [localPosition] at most once per drag.
  void _addCompletionCellAt(Offset localPosition) {
    final camera = _camera;
    if (camera == null) return;
    if (camera.cellSize < 12) {
      if (!_selectionDragUnavailableReported) {
        _selectionDragUnavailableReported = true;
        widget.onCompletionEditUnavailable?.call();
      }
      return;
    }
    final gridPoint = camera.screenToGrid(localPosition);
    final coordinate = GridCoordinate(
      gridPoint.dy.floor(),
      gridPoint.dx.floor(),
    );
    if (!widget.document.grid.dimensions.contains(coordinate) ||
        widget.document.grid.cellAt(coordinate) == null ||
        !_selectionDragCoordinates.add(coordinate)) {
      return;
    }
    widget.onCompletionCellAdded?.call(coordinate);
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
    widget.onInteraction?.call();
    if (_selectionDragPointer != null) {
      _suppressNextTap = false;
      _gestureStartCamera = null;
      return;
    }
    _gestureStartCamera = _camera;
    _gestureStartFocalPoint = details.localFocalPoint;
  }

  /// Applies combined drag and pinch input from the gesture's initial camera.
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_selectionDragPointer != null) return;
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
    widget.onInteraction?.call();
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

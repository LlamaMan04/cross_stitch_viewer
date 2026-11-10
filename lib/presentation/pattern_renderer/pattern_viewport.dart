import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/pattern_document.dart';
import '../../domain/pattern_grid.dart';
import '../../domain/progress_models.dart';
import '../../domain/value_objects.dart';
import 'pattern_camera.dart';
import 'pattern_glyph_layout_cache.dart';
import 'pattern_interaction.dart';
import 'pattern_render_instrumentation.dart';
import 'pattern_render_selection.dart';
import 'pattern_symbol_render_cache.dart';
import 'pattern_tile_picture_cache.dart';
import 'pattern_viewport_controller.dart';
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
  /// Glyph layouts shared by every painter created for this viewport.
  final PatternGlyphLayoutCache _glyphLayoutCache = PatternGlyphLayoutCache();

  /// Static tile display lists shared by every painter for this viewport.
  final PatternTilePictureCache _tilePictureCache = PatternTilePictureCache();

  /// Parsed symbol colors and fill paints shared across viewport painters.
  late PatternSymbolRenderCache _symbolRenderCache;

  /// Optional debug-only sink for renderer counters and frame timings.
  PatternRenderInstrumentation? _instrumentation;

  /// Debounces wheel zoom before allowing a settling cache-population frame.
  Timer? _wheelInteractionTimer;

  /// Whether dependency-driven cache invalidation passed its initial call.
  bool _dependenciesInitialized = false;

  /// Summary blocks containing completion at every overview resolution.
  late Map<int, Set<PatternTileCoordinate>> _completedOverviewCoordinates;

  /// Camera notifier created after the viewport receives a layout size.
  PatternViewportController? _cameraController;

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

  /// Creates document-specific renderer metadata before the first paint.
  @override
  void initState() {
    super.initState();
    _symbolRenderCache = PatternSymbolRenderCache(widget.document);
    _instrumentation = PatternRenderInstrumentation.createIfEnabled();
    _instrumentation?.attach();
    _completedOverviewCoordinates = _indexCompletedOverviewCoordinates(
      widget.completedCells,
    );
  }

  /// Releases cached native text layouts with the owning viewport.
  @override
  void dispose() {
    _wheelInteractionTimer?.cancel();
    _instrumentation?.dispose();
    _cameraController?.dispose();
    _tilePictureCache.dispose();
    _glyphLayoutCache.dispose();
    super.dispose();
  }

  /// Invalidates native pictures when inherited theme or font inputs change.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dependenciesInitialized) {
      _tilePictureCache.clear();
      _glyphLayoutCache.clear();
    }
    _dependenciesInitialized = true;
  }

  /// Resets the camera when a different document is placed in this viewport.
  @override
  void didUpdateWidget(covariant PatternViewport oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.document != widget.document) {
      _cameraController?.dispose();
      _cameraController = null;
      _gestureStartCamera = null;
      _symbolRenderCache = PatternSymbolRenderCache(widget.document);
      _tilePictureCache.clear();
    } else if (oldWidget.settings != widget.settings) {
      _tilePictureCache.clear();
    }
    if (oldWidget.document != widget.document ||
        !identical(oldWidget.completedCells, widget.completedCells)) {
      _completedOverviewCoordinates = _indexCompletedOverviewCoordinates(
        widget.completedCells,
      );
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
        final cameraController = _cameraController!;
        final camera = cameraController.camera;
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
            onScaleEnd: _handleScaleEnd,
            onTapUp:
                widget.onSymbolSelected == null &&
                    widget.onCompletionCellSelected == null
                ? null
                : _handleTapUp,
            child: RepaintBoundary(
              key: const ValueKey('pattern-render-boundary'),
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
                  glyphLayoutCache: _glyphLayoutCache,
                  symbolRenderCache: _symbolRenderCache,
                  tilePictureCache: _tilePictureCache,
                  renderLod: cameraController.renderLod,
                  completedOverviewCoordinates: _completedOverviewCoordinates,
                  cameraController: cameraController,
                  viewportSize: viewportSize,
                  onBatchMetrics: _instrumentation?.recordPaint,
                ),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Indexes completed coordinates at every supported overview resolution.
  Map<int, Set<PatternTileCoordinate>> _indexCompletedOverviewCoordinates(
    Set<GridCoordinate> completedCells,
  ) => Map<int, Set<PatternTileCoordinate>>.unmodifiable({
    for (final blockSize in PatternGrid.overviewBlockSizes)
      blockSize: Set<PatternTileCoordinate>.unmodifiable(
        completedCells.map(
          (coordinate) => PatternTileCoordinate(
            coordinate.row ~/ blockSize,
            coordinate.column ~/ blockSize,
          ),
        ),
      ),
  });

  /// Converts a tap into a populated cell's symbol selection.
  void _handleTapUp(TapUpDetails details) {
    if (_suppressNextTap) {
      _suppressNextTap = false;
      return;
    }
    widget.onInteraction?.call();
    final camera = _cameraController?.camera;
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
    final camera = _cameraController?.camera;
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
    final camera = _cameraController?.camera;
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
    final cameraController = _cameraController;
    if (cameraController == null) {
      _cameraController = PatternViewportController(
        camera: PatternCamera.fit(
          dimensions: widget.document.grid.dimensions,
          viewportSize: viewportSize,
        ),
      );
    } else if (_viewportSize != viewportSize) {
      final currentCamera = cameraController.camera;
      // A larger layout can raise the fitted minimum scale.
      final minimumCellSize = PatternCamera.minimumCellSizeFor(
        dimensions: widget.document.grid.dimensions,
        viewportSize: viewportSize,
      );
      final maximumCellSize = PatternCamera.maximumCellSizeFor(
        dimensions: widget.document.grid.dimensions,
        viewportSize: viewportSize,
      );
      final layoutCamera = currentCamera.cellSize < minimumCellSize
          ? PatternCamera.fit(
              dimensions: widget.document.grid.dimensions,
              viewportSize: viewportSize,
            )
          : PatternCamera(
              cellSize: currentCamera.cellSize.clamp(
                minimumCellSize,
                maximumCellSize,
              ),
              origin: currentCamera.origin,
            ).clampTo(
              dimensions: widget.document.grid.dimensions,
              viewportSize: viewportSize,
            );
      cameraController.replaceCameraForLayout(layoutCamera);
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
    _beginCameraInteraction();
    _gestureStartCamera = _cameraController?.camera;
    _gestureStartFocalPoint = details.localFocalPoint;
  }

  /// Finishes one touch or pointer gesture and populates missed cache tiles.
  void _handleScaleEnd(ScaleEndDetails details) {
    _gestureStartCamera = null;
    _finishCameraInteraction();
  }

  /// Applies combined drag and pinch input from the gesture's initial camera.
  void _handleScaleUpdate(ScaleUpdateDetails details) {
    if (_selectionDragPointer != null) return;
    if ((details.scale - 1).abs() > 0.0001) {
      _bypassTilePicturesForZoom();
    }
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
    _cameraController?.updateCamera(
      PatternCamera(cellSize: nextCellSize, origin: nextOrigin).clampTo(
        dimensions: widget.document.grid.dimensions,
        viewportSize: viewportSize,
      ),
    );
  }

  /// Converts mouse-wheel movement into focal zoom at the pointer location.
  void _handlePointerSignal(PointerSignalEvent event) {
    final cameraController = _cameraController;
    if (event is! PointerScrollEvent || cameraController == null) return;
    widget.onInteraction?.call();
    final viewportSize = _viewportSize;
    if (viewportSize == null) return;
    _beginCameraInteraction(bypassTilePictures: true);
    // Exponential scaling makes equal wheel deltas feel symmetric.
    final scale = math.exp(-event.scrollDelta.dy * 0.0015);
    cameraController.updateCamera(
      cameraController.camera.zoomAround(
        focalPoint: event.localPosition,
        scale: scale,
        dimensions: widget.document.grid.dimensions,
        viewportSize: viewportSize,
      ),
    );
    _wheelInteractionTimer = Timer(
      const Duration(milliseconds: 120),
      _finishCameraInteraction,
    );
  }

  /// Suspends cache recording and optionally picture replay for camera updates.
  void _beginCameraInteraction({bool bypassTilePictures = false}) {
    _wheelInteractionTimer?.cancel();
    _tilePictureCache.suspendWrites();
    if (bypassTilePictures) _bypassTilePicturesForZoom();
  }

  /// Discards stale static pictures once when an interaction becomes a zoom.
  void _bypassTilePicturesForZoom() {
    if (!_tilePictureCache.reuseEnabled) return;
    _tilePictureCache
      ..suspendReuse()
      ..clear();
  }

  /// Restores cache reuse and recording, then requests one settling repaint.
  void _finishCameraInteraction() {
    _wheelInteractionTimer?.cancel();
    _wheelInteractionTimer = null;
    _tilePictureCache.resumeWrites();
    _tilePictureCache.resumeReuse();
    _cameraController?.requestRepaint();
  }
}

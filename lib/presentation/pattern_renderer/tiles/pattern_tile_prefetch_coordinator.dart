import 'dart:collection';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import '../../../domain/pattern_grid.dart';
import '../cache/pattern_tile_picture_cache.dart';
import '../viewport/pattern_camera.dart';
import '../viewport/pattern_viewport_bounds.dart';
import '../viewport/render_lod.dart';
import 'pattern_static_tile_recorder.dart';

/// Schedules a bounded amount of static tile cache warming after each frame.
class PatternTilePrefetchCoordinator {
  /// Creates a cooperative cache warmer with a per-frame recording limit.
  PatternTilePrefetchCoordinator({
    this.maximumTilesPerFrame = 2,
    FrameCallbackScheduler? scheduleFrame,
  }) : assert(maximumTilesPerFrame > 0),
       _scheduleFrame =
           scheduleFrame ??
           ((callback) =>
               WidgetsBinding.instance.addPostFrameCallback(callback));

  /// Maximum number of display lists this coordinator can record per frame.
  final int maximumTilesPerFrame;

  /// Scheduler used to defer work until Flutter has completed the paint frame.
  final FrameCallbackScheduler _scheduleFrame;

  /// Requests awaiting a cooperative post-frame recording slot.
  final ListQueue<_PrefetchRequest> _requests = ListQueue<_PrefetchRequest>();

  /// Keys represented in [_requests], used to suppress duplicates.
  final Set<PatternTilePictureKey> _queuedKeys = <PatternTilePictureKey>{};

  /// Most recent camera used to derive a panning direction.
  PatternCamera? _previousCamera;

  /// Current revision; all older queued work is stale.
  int _revision = -1;

  /// Whether a post-frame drain was already scheduled.
  bool _drainScheduled = false;

  /// Number of requests accepted over this coordinator's lifetime.
  int requestCount = 0;

  /// Number of tiles successfully made available over this lifetime.
  int prefetchedTileCount = 0;

  /// Number of requests removed when a newer revision superseded them.
  int cancelledRequestCount = 0;

  /// Number of requests observed stale when their drain began.
  int staleRequestCount = 0;

  /// Number of requests waiting for a future post-frame recording slot.
  int get queuedRequestCount => _requests.length;

  /// Offers the current paint context and queues uncached tiles for warming.
  void submit({
    required PatternCamera camera,
    required RenderLod renderLod,
    required PatternViewportBounds bounds,
    required int revision,
    required PatternStaticTileRecorder recorder,
    required VoidCallback requestRepaint,
  }) {
    if (!recorder.cache.writesEnabled || !recorder.cache.reuseEnabled) return;
    if (revision != _revision) {
      if (_requests.isNotEmpty) {
        cancelledRequestCount += _requests.length;
        _requests.clear();
        _queuedKeys.clear();
      }
      _revision = revision;
    }
    final pan = _panDirection(camera);
    final candidates =
        _coordinatesFor(bounds.prefetchBounds).where((coordinate) {
          final key = recorder.keyFor(coordinate);
          return !recorder.cache.contains(key) && !_queuedKeys.contains(key);
        }).toList()..sort((left, right) {
          final distance = _distanceToPaint(
            left,
            bounds.paintBounds,
          ).compareTo(_distanceToPaint(right, bounds.paintBounds));
          if (distance != 0) return distance;
          final rightDirection = _directionScore(
            right,
            bounds.paintBounds,
            pan,
          );
          final leftDirection = _directionScore(left, bounds.paintBounds, pan);
          return rightDirection.compareTo(leftDirection);
        });
    for (final coordinate in candidates) {
      final key = recorder.keyFor(coordinate);
      _queuedKeys.add(key);
      _requests.add(
        _PrefetchRequest(
          key: key,
          coordinate: coordinate,
          revision: revision,
          recorder: recorder,
          requestRepaint: requestRepaint,
        ),
      );
    }
    requestCount += candidates.length;
    _scheduleDrain();
  }

  /// Discards queued work, such as when the viewport is disposed.
  void dispose() {
    invalidate();
  }

  /// Cancels queued work when its document or visual inputs become invalid.
  void invalidate() {
    cancelledRequestCount += _requests.length;
    _requests.clear();
    _queuedKeys.clear();
    _revision++;
  }

  /// Schedules one bounded queue drain after the current frame.
  void _scheduleDrain() {
    if (_drainScheduled || _requests.isEmpty) return;
    _drainScheduled = true;
    _scheduleFrame((_) {
      _drainScheduled = false;
      var recorded = 0;
      var usefulWorkCompleted = false;
      while (_requests.isNotEmpty && recorded < maximumTilesPerFrame) {
        final request = _requests.removeFirst();
        _queuedKeys.remove(request.key);
        if (request.revision != _revision) {
          staleRequestCount++;
          continue;
        }
        if (request.recorder.cache.contains(request.key)) continue;
        if (request.recorder.warm(request.coordinate)) {
          recorded++;
          prefetchedTileCount++;
          usefulWorkCompleted = true;
          _lastCompletedRepaint = request.requestRepaint;
        }
      }
      if (usefulWorkCompleted) requestRepaintForCompletedWork();
      if (_requests.isNotEmpty) _scheduleDrain();
    });
  }

  /// Requests a repaint from the newest completed prefetch request.
  void requestRepaintForCompletedWork() {
    _lastCompletedRepaint?.call();
    _lastCompletedRepaint = null;
  }

  /// Callback captured from the most recent useful prefetch request.
  VoidCallback? _lastCompletedRepaint;

  /// Returns tile coordinates covered by a document-clamped tile range.
  Iterable<PatternTileCoordinate> _coordinatesFor(GridBounds bounds) sync* {
    if (bounds.isEmpty) return;
    final firstRow = bounds.startRow ~/ PatternGrid.tileSize;
    final lastRow = (bounds.endRow - 1) ~/ PatternGrid.tileSize;
    final firstColumn = bounds.startColumn ~/ PatternGrid.tileSize;
    final lastColumn = (bounds.endColumn - 1) ~/ PatternGrid.tileSize;
    for (var row = firstRow; row <= lastRow; row++) {
      for (var column = firstColumn; column <= lastColumn; column++) {
        yield PatternTileCoordinate(row, column);
      }
    }
  }

  /// Calculates current pan direction in source-tile coordinates.
  Offset _panDirection(PatternCamera camera) {
    final previous = _previousCamera;
    _previousCamera = camera;
    if (previous == null || previous.cellSize != camera.cellSize) {
      return Offset.zero;
    }
    return Offset(
      previous.origin.dx - camera.origin.dx,
      previous.origin.dy - camera.origin.dy,
    );
  }

  /// Measures taxicab tile distance from [coordinate] to visible paint tiles.
  int _distanceToPaint(PatternTileCoordinate coordinate, GridBounds paint) {
    final firstRow = paint.startRow ~/ PatternGrid.tileSize;
    final lastRow = (paint.endRow - 1) ~/ PatternGrid.tileSize;
    final firstColumn = paint.startColumn ~/ PatternGrid.tileSize;
    final lastColumn = (paint.endColumn - 1) ~/ PatternGrid.tileSize;
    final rowDistance = coordinate.row < firstRow
        ? firstRow - coordinate.row
        : coordinate.row > lastRow
        ? coordinate.row - lastRow
        : 0;
    final columnDistance = coordinate.column < firstColumn
        ? firstColumn - coordinate.column
        : coordinate.column > lastColumn
        ? coordinate.column - lastColumn
        : 0;
    return rowDistance + columnDistance;
  }

  /// Breaks equal-distance ties toward the direction in which content moves.
  double _directionScore(
    PatternTileCoordinate coordinate,
    GridBounds paint,
    Offset pan,
  ) {
    final centerColumn =
        (paint.startColumn + paint.endColumn) / (2 * PatternGrid.tileSize);
    final centerRow =
        (paint.startRow + paint.endRow) / (2 * PatternGrid.tileSize);
    return (coordinate.column - centerColumn) * pan.dx +
        (coordinate.row - centerRow) * pan.dy;
  }
}

/// Schedules a callback after the current Flutter frame.
typedef FrameCallbackScheduler = void Function(FrameCallback callback);

/// One cache-warming operation waiting for a post-frame slot.
class _PrefetchRequest {
  /// Creates a queued cache-warming operation.
  const _PrefetchRequest({
    required this.key,
    required this.coordinate,
    required this.revision,
    required this.recorder,
    required this.requestRepaint,
  });

  /// Cache key used for duplicate suppression.
  final PatternTilePictureKey key;

  /// Tile to record when this request receives a slot.
  final PatternTileCoordinate coordinate;

  /// Camera revision that made this request relevant.
  final int revision;

  /// Shared recorder that preserves normal-paint cache semantics.
  final PatternStaticTileRecorder recorder;

  /// Repaints the viewport after a picture becomes available.
  final VoidCallback requestRepaint;
}

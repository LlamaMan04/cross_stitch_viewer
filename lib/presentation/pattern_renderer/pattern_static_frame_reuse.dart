import 'dart:ui' as ui;

import '../../domain/pattern_grid.dart';
import '../../domain/value_objects.dart';
import 'pattern_camera.dart';
import 'pattern_static_tile_recorder.dart';
import 'pattern_tile_picture_cache.dart';

/// Retains cache leases for a settled static layer during same-scale panning.
class PatternStaticFrameReuse {
  /// Camera that positioned the retained tile pictures.
  PatternCamera? _camera;

  /// Static cache signature shared by every retained tile.
  PatternTilePictureKey? _signature;

  /// Leased static tile pictures keyed by their source coordinate.
  final Map<PatternTileCoordinate, _RetainedStaticTile> _tiles =
      <PatternTileCoordinate, _RetainedStaticTile>{};

  /// Whether one or more tile pictures are retained for replay.
  bool get hasRetainedFrame => _tiles.isNotEmpty;

  /// Number of leases retained by this frame.
  int get retainedTileCount => _tiles.length;

  /// Replaces the retained frame using cache-backed tiles from a settled paint.
  void capture({
    required Iterable<PatternTileCoordinate> coordinates,
    required PatternStaticTileRecorder recorder,
    required PatternCamera camera,
  }) {
    clear();
    for (final coordinate in coordinates) {
      final key = recorder.keyFor(coordinate);
      final lease = recorder.cache.acquire(key);
      if (lease == null) continue;
      _tiles[coordinate] = _RetainedStaticTile(
        key: key,
        recordedCellSize: recorder.recordedCellSize,
        lease: lease,
      );
    }
    if (_tiles.isEmpty) return;
    _camera = camera;
    _signature = _tiles.values.first.key;
  }

  /// Whether retained pictures match [recorder] and can replay at [camera].
  bool canReplay({
    required PatternStaticTileRecorder recorder,
    required PatternCamera camera,
  }) {
    final retainedCamera = _camera;
    final signature = _signature;
    if (retainedCamera == null || signature == null || _tiles.isEmpty) {
      return false;
    }
    return retainedCamera.cellSize == camera.cellSize &&
        identical(signature.documentIdentity, recorder.document) &&
        signature.renderLod == recorder.renderLod &&
        signature.cellSizeBucket == recorder.cellSizeBucket &&
        signature.style == recorder.style;
  }

  /// Returns retained source tiles that intersect [bounds].
  Set<PatternTileCoordinate> coordinatesIntersecting(GridBounds bounds) =>
      _tiles.keys.where((tile) => _intersects(tile, bounds)).toSet();

  /// Replays retained fill or glyph pictures, clipped to the document extent.
  int paintLayer({
    required ui.Canvas canvas,
    required PatternCamera camera,
    required GridBounds bounds,
    required PatternDimensions dimensions,
    required ui.Picture? Function(PatternTilePictures pictures) pictureFor,
    required int Function(PatternTilePictures pictures) countFor,
  }) {
    final retainedCamera = _camera;
    if (retainedCamera == null || bounds.isEmpty) return 0;
    var count = 0;
    canvas.save();
    canvas.clipRect(
      ui.Rect.fromLTWH(
        camera.origin.dx,
        camera.origin.dy,
        dimensions.columns * camera.cellSize,
        dimensions.rows * camera.cellSize,
      ),
    );
    for (final entry in _tiles.entries) {
      if (!_intersects(entry.key, bounds)) continue;
      final pictures = entry.value.lease.pictures;
      final picture = pictureFor(pictures);
      if (picture == null) continue;
      // Place the settled picture using the active camera's pan delta.
      final origin =
          retainedCamera.origin + (camera.origin - retainedCamera.origin);
      canvas.save();
      canvas.translate(
        origin.dx + entry.key.column * PatternGrid.tileSize * camera.cellSize,
        origin.dy + entry.key.row * PatternGrid.tileSize * camera.cellSize,
      );
      canvas.scale(camera.cellSize / entry.value.recordedCellSize);
      canvas.drawPicture(picture);
      canvas.restore();
      count += countFor(pictures);
    }
    canvas.restore();
    return count;
  }

  /// Releases every retained cache lease exactly once.
  void clear() {
    for (final tile in _tiles.values) {
      tile.lease.release();
    }
    _tiles.clear();
    _camera = null;
    _signature = null;
  }

  /// Whether [tile]'s half-open source extent intersects [bounds].
  bool _intersects(PatternTileCoordinate tile, GridBounds bounds) {
    final startRow = tile.row * PatternGrid.tileSize;
    final startColumn = tile.column * PatternGrid.tileSize;
    return startRow < bounds.endRow &&
        startRow + PatternGrid.tileSize > bounds.startRow &&
        startColumn < bounds.endColumn &&
        startColumn + PatternGrid.tileSize > bounds.startColumn;
  }
}

/// Associates a cache lease with the scale used to record its tile pictures.
class _RetainedStaticTile {
  /// Creates one retained tile ownership record.
  const _RetainedStaticTile({
    required this.key,
    required this.recordedCellSize,
    required this.lease,
  });

  /// Complete static identity used to validate safe retained-frame replay.
  final PatternTilePictureKey key;

  /// Logical cell size used to record tile-local display lists.
  final double recordedCellSize;

  /// Lease that defers disposal while the frame is retained.
  final PatternTilePictureLease lease;
}

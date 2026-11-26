import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/app/test_patterns/sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport/pattern_camera.dart';
import 'package:stitch_scope/presentation/pattern_renderer/cache/pattern_glyph_layout_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/cache/pattern_glyph_picture_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport/pattern_render_selection.dart';
import 'package:stitch_scope/presentation/pattern_renderer/cache/pattern_symbol_render_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/cache/pattern_tile_picture_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport/render_lod.dart';
import 'package:stitch_scope/presentation/pattern_renderer/painting/viewport_pattern_painter.dart';

/// Validates rendered glyph output around scale buckets and LOD boundaries.
void main() {
  test('renders cached detail glyphs on both sides of a tile edge across a scale bucket', () async {
    const initialCellSize = 19.88;
    const replayCellSize = 20.12;
    final document = _tileEdgeDocument();
    final tilePictureCache = PatternTilePictureCache();
    final glyphPictureCache = PatternGlyphPictureCache();
    final glyphLayoutCache = PatternGlyphLayoutCache();
    final directGlyphLayoutCache = PatternGlyphLayoutCache();
    addTearDown(tilePictureCache.dispose);
    addTearDown(glyphPictureCache.dispose);
    addTearDown(glyphLayoutCache.dispose);
    addTearDown(directGlyphLayoutCache.dispose);

    // Populate the shared tile cache at the representative size first.
    await _render(
      document: document,
      cellSize: initialCellSize,
      renderLod: RenderLod.detail,
      tilePictureCache: tilePictureCache,
      glyphPictureCache: glyphPictureCache,
      glyphLayoutCache: glyphLayoutCache,
    );
    final cachedBytes = await _render(
      document: document,
      cellSize: replayCellSize,
      renderLod: RenderLod.detail,
      tilePictureCache: tilePictureCache,
      glyphPictureCache: glyphPictureCache,
      glyphLayoutCache: glyphLayoutCache,
    );
    final directBytes = await _render(
      document: document,
      cellSize: replayCellSize,
      renderLod: RenderLod.detail,
      glyphLayoutCache: directGlyphLayoutCache,
    );

    final cachedLeftInk = _nonWhitePixelCount(
      cachedBytes,
      cellSize: replayCellSize,
      column: 15,
    );
    final cachedRightInk = _nonWhitePixelCount(
      cachedBytes,
      cellSize: replayCellSize,
      column: 16,
    );
    final directLeftInk = _nonWhitePixelCount(
      directBytes,
      cellSize: replayCellSize,
      column: 15,
    );
    final directRightInk = _nonWhitePixelCount(
      directBytes,
      cellSize: replayCellSize,
      column: 16,
    );

    expect(cachedLeftInk, greaterThan(0));
    expect(cachedRightInk, greaterThan(0));
    expect(cachedLeftInk, greaterThanOrEqualTo(directLeftInk ~/ 2));
    expect(cachedRightInk, greaterThanOrEqualTo(directRightInk ~/ 2));
  });

  test('renders symbols only while the resolved LOD remains detail', () async {
    final document = _tileEdgeDocument();
    final detailGlyphLayoutCache = PatternGlyphLayoutCache();
    final gridGlyphLayoutCache = PatternGlyphLayoutCache();
    addTearDown(detailGlyphLayoutCache.dispose);
    addTearDown(gridGlyphLayoutCache.dispose);
    final detailImage = await _render(
      document: document,
      cellSize: 12.25,
      renderLod: resolveRenderLod(cellSize: 12.25),
      glyphLayoutCache: detailGlyphLayoutCache,
    );
    final gridImage = await _render(
      document: document,
      cellSize: 11.74,
      renderLod: resolveRenderLod(cellSize: 11.74, previous: RenderLod.detail),
      glyphLayoutCache: gridGlyphLayoutCache,
    );

    expect(
      _nonWhitePixelCount(detailImage, cellSize: 12.25, column: 15),
      greaterThan(0),
    );
    expect(_nonWhitePixelCount(gridImage, cellSize: 11.74, column: 15), 0);
  });
}

/// Creates populated cells immediately before and after a 16-cell tile edge.
PatternDocument _tileEdgeDocument() {
  final source = SamplePatternFixture.create();
  return PatternDocument(
    id: 'scale-bucket-visual-test',
    title: 'Scale Bucket Visual Test',
    schemaVersion: source.schemaVersion,
    grid: PatternGrid(
      dimensions: PatternDimensions(1, 17),
      cells: <StitchCell>[
        StitchCell(
          coordinate: GridCoordinate(0, 15),
          symbolId: 'flower',
          provenanceId: 'scale-bucket-test',
        ),
        StitchCell(
          coordinate: GridCoordinate(0, 16),
          symbolId: 'flower',
          provenanceId: 'scale-bucket-test',
        ),
      ],
    ),
    threads: source.threads,
    symbols: source.symbols,
    sourceMetadata: const <String, Object?>{},
  );
}

/// Renders one isolated symbol layer and returns its unpremultiplied pixels.
Future<ByteData> _render({
  required PatternDocument document,
  required double cellSize,
  required RenderLod renderLod,
  required PatternGlyphLayoutCache glyphLayoutCache,
  PatternTilePictureCache? tilePictureCache,
  PatternGlyphPictureCache? glyphPictureCache,
}) async {
  final width = (document.grid.dimensions.columns * cellSize).ceil();
  final height = (document.grid.dimensions.rows * cellSize).ceil();
  final painter = ViewportPatternPainter(
    document: document,
    camera: PatternCamera(cellSize: cellSize, origin: Offset.zero),
    visibleBounds: GridBounds(
      startRow: 0,
      endRow: document.grid.dimensions.rows,
      startColumn: 0,
      endColumn: document.grid.dimensions.columns,
    ),
    settings: const PatternRenderSettings(
      showCellColor: false,
      showGrid: false,
      showRegions: false,
    ),
    selection: const PatternRenderSelection(),
    completedCells: const <GridCoordinate>{},
    completionSelection: const <GridCoordinate>{},
    surfaceColor: Colors.white,
    regionColor: Colors.blue,
    completionSelectionColor: Colors.teal,
    glyphLayoutCache: glyphLayoutCache,
    glyphPictureCache: glyphPictureCache,
    symbolRenderCache: PatternSymbolRenderCache(document),
    tilePictureCache: tilePictureCache,
    renderLod: renderLod,
    completedOverviewCoordinates: const <int, Set<PatternTileCoordinate>>{},
  );
  final recorder = PictureRecorder();
  painter.paint(Canvas(recorder), Size(width.toDouble(), height.toDouble()));
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ImageByteFormat.rawRgba);

  image.dispose();
  picture.dispose();
  return bytes!;
}

/// Counts ink pixels in the middle of one cell, excluding adjacent cells.
int _nonWhitePixelCount(
  ByteData bytes, {
  required double cellSize,
  required int column,
}) {
  final width = (17 * cellSize).ceil();
  final left = (column * cellSize + cellSize * 0.2).floor();
  final right = ((column + 1) * cellSize - cellSize * 0.2).ceil();
  final top = (cellSize * 0.2).floor();
  final bottom = (cellSize - cellSize * 0.2).ceil();
  var count = 0;
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      final offset = (y * width + x) * 4;
      final isWhite =
          bytes.getUint8(offset) == 255 &&
          bytes.getUint8(offset + 1) == 255 &&
          bytes.getUint8(offset + 2) == 255;
      if (!isWhite) count++;
    }
  }
  return count;
}

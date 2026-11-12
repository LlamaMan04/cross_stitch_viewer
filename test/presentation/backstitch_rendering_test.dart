import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_scope/domain/pattern_backstitch.dart';
import 'package:stitch_scope/domain/pattern_definitions.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/pattern_grid.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_camera.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_glyph_layout_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_render_selection.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_symbol_render_cache.dart';
import 'package:stitch_scope/presentation/pattern_renderer/render_lod.dart';
import 'package:stitch_scope/presentation/pattern_renderer/viewport_pattern_painter.dart';

/// Exercises backstitch viewport queries and actual rasterized output.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const thread = ThreadDefinition(id: 'red', color: '#FF0000');
  const crossing = BackstitchSegment(
    id: 'crossing',
    start: BackstitchCoordinate(row: 2, column: 0),
    end: BackstitchCoordinate(row: 2, column: 10),
    definitionId: 'red-line',
  );
  const outside = BackstitchSegment(
    id: 'outside',
    start: BackstitchCoordinate(row: 8, column: 0),
    end: BackstitchCoordinate(row: 8, column: 10),
    definitionId: 'red-line',
  );
  final document = PatternDocument(
    id: 'test',
    title: 'test',
    schemaVersion: 1,
    grid: PatternGrid(
      dimensions: const PatternDimensions(10, 10),
      cells: const [],
    ),
    threads: const [thread],
    symbols: const [],
    backstitchDefinitions: const [
      BackstitchDefinition(id: 'red-line', threadId: 'red'),
    ],
    backstitches: const [crossing, outside],
  );
  final cache = PatternSymbolRenderCache(document);
  const bounds = GridBounds(
    startRow: 1,
    endRow: 4,
    startColumn: 4,
    endColumn: 6,
  );

  test('finds crossing and edge-touching segments with immutable metadata', () {
    final lines = cache.backstitchesIntersecting(bounds);
    expect(lines.map((line) => line.segment.id), ['crossing']);
    expect(lines.single.bounds, const Rect.fromLTRB(0, 2, 10, 2));
    expect(lines.single.threadColor, const Color(0xFFFF0000));
    expect(() => lines.clear(), throwsUnsupportedError);
    expect(
      cache.backstitchesIntersecting(
        const GridBounds(startRow: 2, endRow: 3, startColumn: 4, endColumn: 6),
      ),
      hasLength(1),
    );
  });

  for (final colored in [true, false]) {
    test(
      'paints transformed line above grid in ${colored ? 'color' : 'black'}',
      () async {
        final glyphs = PatternGlyphLayoutCache();
        addTearDown(glyphs.dispose);
        final painter = ViewportPatternPainter(
          document: document,
          camera: const PatternCamera(cellSize: 20, origin: Offset(-80, -20)),
          visibleBounds: bounds,
          settings: PatternRenderSettings(
            showCellColor: colored,
            showGrid: true,
            showSymbols: false,
          ),
          selection: const PatternRenderSelection(),
          completedCells: const <GridCoordinate>{},
          completionSelection: const <GridCoordinate>{},
          surfaceColor: Colors.white,
          regionColor: Colors.blue,
          completionSelectionColor: Colors.teal,
          glyphLayoutCache: glyphs,
          symbolRenderCache: cache,
          renderLod: RenderLod.detail,
          completedOverviewCoordinates: const {},
        );
        expect(painter.backstitchStrokeWidth, greaterThan(2));
        expect(
          identical(painter.visibleBackstitches, painter.visibleBackstitches),
          isTrue,
        );
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), const Size(40, 50));
        final picture = recorder.endRecording();
        final image = await picture.toImage(40, 50);
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final offset = (20 * 40 + 20) * 4;
        expect([
          pixels.getUint8(offset),
          pixels.getUint8(offset + 1),
          pixels.getUint8(offset + 2),
        ], colored ? [255, 0, 0] : [0, 0, 0]);
        image.dispose();
        picture.dispose();
      },
    );
  }
}

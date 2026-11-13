import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:stitch_scope/app/test_patterns/extra_large_sample_pattern_fixture.dart';
import 'package:stitch_scope/app/test_patterns/large_sample_pattern_fixture.dart';
import 'package:stitch_scope/app/test_patterns/sparse_sample_pattern_fixture.dart';
import 'package:stitch_scope/domain/pattern_document.dart';
import 'package:stitch_scope/domain/progress_models.dart';
import 'package:stitch_scope/domain/value_objects.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_render_instrumentation.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_render_selection.dart';
import 'package:stitch_scope/presentation/pattern_renderer/pattern_render_view.dart';

/// Repository document that defines these target-device baseline scenarios.
const String phase0BaselineDocument = 'docs/PHASE_0_RENDERER_BASELINE.md';

/// Exercises the renderer on a real Flutter target and reports engine timings.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('records deterministic renderer performance scenarios', (
    tester,
  ) async {
    expect(
      patternRenderInstrumentationEnabled,
      isTrue,
      reason: 'Run with --dart-define=PATTERN_RENDER_INSTRUMENTATION=true.',
    );
    final samplesByScenario = <String, List<PatternRenderFrameMetrics>>{};
    String? activeScenario;
    PatternRenderInstrumentation.debugMetricsListener = (metrics) {
      if (activeScenario == null || metrics.rasterDuration == null) return;
      samplesByScenario
          .putIfAbsent(activeScenario, () => <PatternRenderFrameMetrics>[])
          .add(metrics);
    };
    addTearDown(() => PatternRenderInstrumentation.debugMetricsListener = null);

    for (final scenario in _scenarios) {
      activeScenario = scenario.name;
      await _pumpScenario(tester, scenario);
      await _exerciseScenario(tester);
      await tester.pump(const Duration(milliseconds: 250));
    }
    activeScenario = null;

    final results = <String, Map<String, Object>>{
      for (final scenario in _scenarios)
        scenario.name: _summarize(samplesByScenario[scenario.name] ?? const []),
    };
    expect(
      results.values.every((result) => (result['frameCount']! as int) > 0),
      isTrue,
      reason: 'The target did not report raster FrameTiming samples.',
    );
    final report = <String, Object>{
      'baselineDocument': phase0BaselineDocument,
      'rendererPerformance': results,
    };
    binding.reportData = report;
    debugPrint('RENDER_PERFORMANCE_RESULT ${jsonEncode(report)}');
  });
}

/// Immutable definition of one target-device performance scenario.
class _RendererPerformanceScenario {
  /// Creates a named scenario with its fixed renderer inputs.
  const _RendererPerformanceScenario({
    required this.name,
    required this.createDocument,
    this.completedCells = const <GridCoordinate>{},
    this.selection = const PatternRenderSelection(),
  });

  /// Stable name used in exported performance data.
  final String name;

  /// Creates a fresh deterministic source document for the scenario.
  final PatternDocument Function() createDocument;

  /// Completed cells used to exercise progress-overlay work.
  final Set<GridCoordinate> completedCells;

  /// Symbol selection used to exercise dynamic selection-overlay work.
  final PatternRenderSelection selection;
}

/// Target-device scenarios that match the Phase 0 baseline document.
final List<_RendererPerformanceScenario> _scenarios =
    <_RendererPerformanceScenario>[
      const _RendererPerformanceScenario(
        name: 'large_sparse',
        createDocument: SparseSamplePatternFixture.create,
      ),
      const _RendererPerformanceScenario(
        name: 'dense_repeated_symbols',
        createDocument: LargeSamplePatternFixture.create,
      ),
      const _RendererPerformanceScenario(
        name: 'many_colors_and_symbols',
        createDocument: ExtraLargeSamplePatternFixture.create,
      ),
      _RendererPerformanceScenario(
        name: 'completed_and_selected_overlays',
        createDocument: ExtraLargeSamplePatternFixture.create,
        completedCells: <GridCoordinate>{
          GridCoordinate(250, 200),
          GridCoordinate(250, 201),
          GridCoordinate(251, 200),
        },
        selection: PatternRenderSelection(
          threadId: 'dmc-321',
          selectedSymbolId: 'large-red',
        ),
      ),
    ];

/// Mounts one scenario at detail scale around the center of its document.
Future<void> _pumpScenario(
  WidgetTester tester,
  _RendererPerformanceScenario scenario,
) async {
  final document = scenario.createDocument();
  final center = GridCoordinate(
    document.grid.dimensions.rows ~/ 2,
    document.grid.dimensions.columns ~/ 2,
  );
  await tester.pumpWidget(
    MaterialApp(
      home: SizedBox(
        width: 800,
        height: 600,
        child: PatternRenderView(
          document: document,
          completedCells: scenario.completedCells,
          selection: scenario.selection,
          initialViewport: ViewportState(
            zoom: 16,
            panX: 0,
            panY: 0,
            anchor: center,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Executes deterministic pan, repeat-pan, wheel, and pinch input sequences.
Future<void> _exerciseScenario(WidgetTester tester) async {
  final viewport = find.byKey(const ValueKey('pattern-viewport'));
  for (final delta in <Offset>[
    const Offset(-256, 0),
    const Offset(0, -256),
    const Offset(-192, -192),
    const Offset(256, 0),
    const Offset(-256, 0),
  ]) {
    await tester.drag(viewport, delta, touchSlopX: 0, touchSlopY: 0);
    await tester.pumpAndSettle();
  }
  final focalPoint = tester.getCenter(viewport);
  await tester.sendEventToBinding(
    PointerScrollEvent(
      position: focalPoint,
      scrollDelta: const Offset(0, -120),
    ),
  );
  await tester.pump(const Duration(milliseconds: 150));
  final firstPointer = await tester.startGesture(
    focalPoint - const Offset(40, 0),
    pointer: 101,
  );
  final secondPointer = await tester.startGesture(
    focalPoint + const Offset(40, 0),
    pointer: 102,
  );
  await firstPointer.moveBy(const Offset(-24, 0));
  await secondPointer.moveBy(const Offset(24, 0));
  await tester.pump();
  await firstPointer.up();
  await secondPointer.up();
  await tester.pumpAndSettle();
}

/// Reduces target frame samples into stable, machine-readable summary data.
Map<String, Object> _summarize(List<PatternRenderFrameMetrics> samples) {
  int maximum(Duration? Function(PatternRenderFrameMetrics sample) duration) =>
      samples.fold<int>(0, (maximum, sample) {
        final microseconds = duration(sample)?.inMicroseconds ?? 0;
        return microseconds > maximum ? microseconds : maximum;
      });
  int total(int Function(PatternRenderFrameMetrics sample) value) =>
      samples.fold(0, (sum, sample) => sum + value(sample));
  return <String, Object>{
    'frameCount': samples.length,
    'maximumBuildMicros': maximum((sample) => sample.buildDuration),
    'maximumRasterMicros': maximum((sample) => sample.rasterDuration),
    'tileHits': total((sample) => sample.paint.tilePictureHits),
    'tileMisses': total((sample) => sample.paint.tilePictureMisses),
    'tileRecordings': total((sample) => sample.paint.tileRecordingsCompleted),
    'maximumDirectGlyphPaints': samples.fold<int>(
      0,
      (maximum, sample) => maximum > sample.paint.directGlyphPaintCount
          ? maximum
          : sample.paint.directGlyphPaintCount,
    ),
    'maximumOverlayCandidates': samples.fold<int>(
      0,
      (maximum, sample) =>
          maximum > sample.paint.dynamicOverlayCandidatesVisited
          ? maximum
          : sample.paint.dynamicOverlayCandidatesVisited,
    ),
    'maximumGridRules': samples.fold<int>(
      0,
      (maximum, sample) => maximum > sample.paint.gridRuleCount
          ? maximum
          : sample.paint.gridRuleCount,
    ),
  };
}

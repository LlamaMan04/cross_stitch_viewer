import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

import 'viewport_pattern_painter.dart';

/// Enables renderer profiling only when explicitly requested in a debug build.
const bool patternRenderInstrumentationEnabled =
    kDebugMode &&
    bool.fromEnvironment('PATTERN_RENDER_INSTRUMENTATION', defaultValue: false);

/// Controls how often debug renderer frame metrics are printed.
const int patternRenderInstrumentationLogInterval = int.fromEnvironment(
  'PATTERN_RENDER_INSTRUMENTATION_LOG_INTERVAL',
  defaultValue: 60,
);

/// Collects renderer counters and Flutter frame timings in debug builds.
class PatternRenderInstrumentation {
  /// Creates an instrumentation sink with an optional debug log callback.
  PatternRenderInstrumentation({
    this.logInterval = patternRenderInstrumentationLogInterval,
    this.onMetrics,
  }) : assert(logInterval > 0);

  /// Creates the configured sink, or null when instrumentation is disabled.
  static PatternRenderInstrumentation? createIfEnabled() {
    if (!patternRenderInstrumentationEnabled) return null;
    return PatternRenderInstrumentation();
  }

  /// Number of painted renderer frames between debug log messages.
  final int logInterval;

  /// Optional consumer for tests or an in-app debug diagnostics surface.
  final ValueChanged<PatternRenderFrameMetrics>? onMetrics;

  /// Number of renderer paint frames observed by this sink.
  int _paintFrameCount = 0;

  /// Number of Flutter frame timing samples observed by this sink.
  int _timingFrameCount = 0;

  /// Most recent painter counters awaiting a Flutter timing sample.
  PatternRenderBatchMetrics? _latestPaintMetrics;

  /// Whether the sink is currently registered with Flutter's frame scheduler.
  bool _isAttached = false;

  /// Registers this sink for debug-only build and raster timing samples.
  void attach() {
    if (_isAttached) return;
    WidgetsBinding.instance.addTimingsCallback(_handleTimings);
    _isAttached = true;
  }

  /// Removes this sink from Flutter's frame timing callback list.
  void dispose() {
    if (!_isAttached) return;
    WidgetsBinding.instance.removeTimingsCallback(_handleTimings);
    _isAttached = false;
  }

  /// Records visible renderer work completed by one painter invocation.
  void recordPaint(PatternRenderBatchMetrics metrics) {
    _paintFrameCount++;
    _latestPaintMetrics = metrics;
    if (_paintFrameCount % logInterval == 0) {
      _emitMetrics(
        PatternRenderFrameMetrics(
          paintFrame: _paintFrameCount,
          timingFrame: _timingFrameCount,
          paint: metrics,
        ),
      );
    }
  }

  /// Records Flutter's build and raster durations for completed frames.
  void _handleTimings(List<FrameTiming> timings) {
    for (final timing in timings) {
      _timingFrameCount++;
      final paint = _latestPaintMetrics;
      if (paint == null || _timingFrameCount % logInterval != 0) continue;
      _emitMetrics(
        PatternRenderFrameMetrics(
          paintFrame: _paintFrameCount,
          timingFrame: _timingFrameCount,
          paint: paint,
          buildDuration: timing.buildDuration,
          rasterDuration: timing.rasterDuration,
        ),
      );
    }
  }

  /// Sends metrics to the configured consumer and the debug console.
  void _emitMetrics(PatternRenderFrameMetrics metrics) {
    onMetrics?.call(metrics);
    debugPrint(metrics.toString());
  }
}

/// Combines renderer counters with optional Flutter frame timings.
class PatternRenderFrameMetrics {
  /// Creates one immutable renderer diagnostics sample.
  const PatternRenderFrameMetrics({
    required this.paintFrame,
    required this.timingFrame,
    required this.paint,
    this.buildDuration,
    this.rasterDuration,
  });

  /// Renderer paint-frame sequence number.
  final int paintFrame;

  /// Flutter timing-frame sequence number.
  final int timingFrame;

  /// Counters reported by the renderer painter.
  final PatternRenderBatchMetrics paint;

  /// Flutter build duration when a timing sample is available.
  final Duration? buildDuration;

  /// Flutter raster duration when a timing sample is available.
  final Duration? rasterDuration;

  /// Formats the sample for debug-console inspection.
  @override
  String toString() =>
      'PatternRenderFrameMetrics('
      'paintFrame: $paintFrame, '
      'timingFrame: $timingFrame, '
      'visibleCells: ${paint.visibleCellCount}, '
      'glyphs: ${paint.glyphCount}, '
      'gridRules: ${paint.gridRuleCount}, '
      'drawCalls: ${paint.drawCallCount}, '
      'tileHits: ${paint.tilePictureHits}, '
      'tileMisses: ${paint.tilePictureMisses}, '
      'tileEntries: ${paint.tilePictureCacheEntries}, '
      'tileBytes: ${paint.tilePictureCacheBytes}, '
      'tileEvictions: ${paint.tilePictureEvictions}, '
      'tileBypasses: ${paint.tilePictureBypasses}, '
      'build: ${buildDuration?.inMicroseconds ?? '-'}us, '
      'raster: ${rasterDuration?.inMicroseconds ?? '-'}us)';
}

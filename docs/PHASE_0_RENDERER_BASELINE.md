# Phase 0 renderer baseline

## Purpose

This is the repeatable trace procedure to use before changing tile dimensions or cache budgets. It is diagnostic rather than a timing assertion: build and raster duration vary by GPU, display scale, and build mode.

## Enable the trace

Load the built-in samples from **Settings > Sample patterns**, open the named pattern, then run in profile mode:

```powershell
flutter run -d windows --profile --dart-define=PATTERN_RENDER_INSTRUMENTATION=true --dart-define=PATTERN_RENDER_INSTRUMENTATION_LOG_INTERVAL=1
```

Use `flutter devices` to substitute an attached Android or iOS target. Each `PatternRenderFrameMetrics` line records camera/LOD/interaction state, build and raster time, tile counters, direct work, tile recordings, prefetch counters, overlay work, grid work, and draw calls.

## Automated target-device recording

The executable suite at [`integration_test/renderer_performance_test.dart`](../integration_test/renderer_performance_test.dart) is the automated form of every scenario below. It embeds this document's repository path (`docs/PHASE_0_RENDERER_BASELINE.md`) in its `IntegrationTestWidgetsFlutterBinding.reportData` and emits a `RENDER_PERFORMANCE_RESULT` JSON line. That JSON includes actual Flutter-engine build and raster timing samples plus renderer instrumentation counters from the selected target.

Run it in profile mode with a device identifier from `flutter devices`:

```powershell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/renderer_performance_test.dart -d windows --profile --dart-define=PATTERN_RENDER_INSTRUMENTATION=true
```

Save the emitted JSON as a dated artifact alongside the hardware and OS details for the baseline row below. The integration suite deliberately reports measurements without pass/fail timing thresholds so device-specific regressions can be compared without flaking on unrelated target differences.

## Deterministic scenarios

| Scenario | Fixture and setup | Gesture sequence |
| --- | --- | --- |
| Sparse source tiles | `Sparse Test Pattern`, detail zoom, all renderer layers enabled. Its fixed 10% population gives reproducible sparse boundaries. | Slowly pan horizontally, vertically, and diagonally across a 16-cell tile boundary; repeat each direction back and forth five times. |
| Dense repeated symbols | `Large Test Pattern`, detail zoom, cell color, symbols, and grid enabled. It has 95% coverage and twelve repeating symbols. | Repeat the three boundary pans, then wheel and pinch zoom immediately below and above each LOD threshold. |
| Many colors and symbols | `Extra Large Random Test Pattern`, detail zoom, cell color, symbols, and grid enabled. Its seeded 500-by-400 distribution uses all twelve fixed colors and symbols. | Repeat the three boundary pans and threshold zooms after cache warm-up. |
| Dynamic overlays | `Extra Large Random Test Pattern`, a representative completed group, selected symbol, and completed cells excluded from selection. | Repeat the horizontal boundary pan, then change a renderer style after the cache warms and repeat it. |

After each scenario, toggle grid visibility or cell-color opacity, allow one settled frame, and repeat one pan to capture warmed-cache invalidation behavior.

## Results record

| Target | Build | Date | Result |
| --- | --- | --- | --- |
| Windows desktop | Profile | Pending manual capture | The trace is ready; automated renderer tests validate deterministic counters but do not stand in for GPU raster timings. |
| Mobile-class target | Profile | Pending attached-device capture | Requires a physical or configured mobile target. Retain target model, OS, refresh rate, raw trace, medians, and worst boundary-crossing frame. |

The timing rows remain intentionally pending: target-specific measurements must not be fabricated from unit-test picture recording. Update them before Phase 5 tuning.

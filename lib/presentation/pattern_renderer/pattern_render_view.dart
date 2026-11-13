import 'package:flutter/material.dart';

import '../../domain/pattern_document.dart';
import '../../domain/progress_models.dart';
import '../../domain/value_objects.dart';
import 'pattern_interaction.dart';
import 'pattern_render_selection.dart';
import 'pattern_viewport.dart';

/// Places a normalized pattern document in the viewport rendering engine.
class PatternRenderView extends StatelessWidget {
  /// Creates a read-only viewport for [document].
  const PatternRenderView({
    required this.document,
    this.settings = const PatternRenderSettings(),
    this.selection = const PatternRenderSelection(),
    this.completedCells = const <GridCoordinate>{},
    this.interactionMode = PatternInteractionMode.browse,
    CompletionCellSelection? completionSelection,
    this.onSymbolSelected,
    this.onBackstitchSelected,
    this.onCompletionCellSelected,
    this.onCompletionCellAdded,
    this.onCompletionEditUnavailable,
    this.onInteraction,
    this.initialViewport,
    this.onViewportSettled,
    super.key,
  }) : completionSelection =
           completionSelection ?? const CompletionCellSelection.empty();

  /// Pattern data rendered by the viewport.
  final PatternDocument document;

  /// Visual settings applied without changing viewport camera state.
  final PatternRenderSettings settings;

  /// Ephemeral symbol selection highlighted across matching visible cells.
  final PatternRenderSelection selection;

  /// Completed coordinates used by progress-aware renderer overlays.
  final Set<GridCoordinate> completedCells;

  /// Active interpretation of taps inside the viewport.
  final PatternInteractionMode interactionMode;

  /// Exact coordinates selected for pending completion changes.
  final CompletionCellSelection completionSelection;

  /// Reports direct pattern-cell selection changes.
  final ValueChanged<String?>? onSymbolSelected;

  /// Reports a backstitch selection made directly on the viewport.
  final ValueChanged<PatternRenderSelection>? onBackstitchSelected;

  /// Reports exact-cell selection changes in completion-edit mode.
  final ValueChanged<GridCoordinate>? onCompletionCellSelected;

  /// Reports cells crossed by an additive completion-selection drag.
  final ValueChanged<GridCoordinate>? onCompletionCellAdded;

  /// Reports completion taps attempted below the legible zoom threshold.
  final VoidCallback? onCompletionEditUnavailable;

  /// Reports viewport interaction so transient completion feedback can clear.
  final VoidCallback? onInteraction;

  /// Persisted camera snapshot restored by the viewport after it is laid out.
  final ViewportState? initialViewport;

  /// Reports a stable camera snapshot for debounced progress persistence.
  final ValueChanged<ViewportState>? onViewportSettled;

  /// Builds a bounded surface whose camera maps grid coordinates to pixels.
  @override
  Widget build(BuildContext context) {
    // The viewport surface follows the active application theme.
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
      ),
      child: PatternViewport(
        document: document,
        settings: settings,
        selection: selection,
        completedCells: completedCells,
        interactionMode: interactionMode,
        completionSelection: completionSelection,
        onSymbolSelected: onSymbolSelected,
        onBackstitchSelected: onBackstitchSelected,
        onCompletionCellSelected: onCompletionCellSelected,
        onCompletionCellAdded: onCompletionCellAdded,
        onCompletionEditUnavailable: onCompletionEditUnavailable,
        onInteraction: onInteraction,
        initialViewport: initialViewport,
        onViewportSettled: onViewportSettled,
      ),
    );
  }
}

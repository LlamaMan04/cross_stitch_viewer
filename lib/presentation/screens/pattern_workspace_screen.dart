import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_document.dart';
import '../../domain/progress_models.dart';
import '../../domain/repositories.dart';
import '../../domain/value_objects.dart';
import '../pattern_renderer/pattern_interaction.dart';
import '../pattern_renderer/pattern_viewport.dart';
import '../pattern_renderer/pattern_render_selection.dart';

/// Mutually exclusive workspace surface activated from the floating menu.
enum _WorkspaceMenuOption {
  /// Opens renderer-specific visual settings.
  rendererSettings,

  /// Opens the symbol palette and thread inspector.
  symbolPalette,

  /// Enables exact-cell completion selection and its action surface.
  completionSelection,
}

/// Loads a persisted pattern and its independent viewport render settings.
class PatternWorkspaceScreen extends StatefulWidget {
  /// Creates a workspace for the selected document.
  const PatternWorkspaceScreen({
    required this.documentId,
    required this.patternDocuments,
    required this.progress,
    super.key,
  });

  /// Stable identity of the document opened from the library.
  final String documentId;

  /// Repository used to load the selected normalized document.
  final PatternDocumentRepository patternDocuments;

  /// Repository used to load and save per-pattern render settings.
  final ProgressRepository progress;

  /// Creates state that retains settings and panel visibility.
  @override
  State<PatternWorkspaceScreen> createState() => _PatternWorkspaceScreenState();
}

/// Coordinates workspace loading, render-setting controls, and persistence.
class _PatternWorkspaceScreenState extends State<PatternWorkspaceScreen> {
  /// Pending document and progress read retained across rebuilds.
  late final Future<PatternDocument?> _document;

  /// Current persisted or default render settings.
  PatternRenderSettings _settings = const PatternRenderSettings();

  /// Latest complete progress graph used to preserve unrelated user state.
  ProgressState? _progress;

  /// Completed coordinates loaded with the mutable progress graph.
  Set<GridCoordinate> _completedCells = const <GridCoordinate>{};

  /// Whether the bottom-right floating menu currently exposes its choices.
  bool _isFloatingMenuExpanded = false;

  /// The only active workspace surface, or null when none is selected.
  _WorkspaceMenuOption? _activeMenuOption;

  /// Current ephemeral symbol selection, intentionally not persisted.
  PatternRenderSelection _selection = const PatternRenderSelection();

  /// Whether the renderer settings surface is the active menu choice.
  bool get _showSettings =>
      _activeMenuOption == _WorkspaceMenuOption.rendererSettings;

  /// Whether the symbol palette surface is the active menu choice.
  bool get _showSymbolPalette =>
      _activeMenuOption == _WorkspaceMenuOption.symbolPalette;

  /// Derives tap behavior from the currently active mutually exclusive choice.
  PatternInteractionMode get _interactionMode =>
      _activeMenuOption == _WorkspaceMenuOption.completionSelection
      ? PatternInteractionMode.editCompletion
      : PatternInteractionMode.browse;

  /// Exact cells selected for the next completion action.
  CompletionCellSelection _completionSelection =
      CompletionCellSelection.empty();

  /// Inline Undo notice shown without covering workspace controls.
  _CompletionUndoNotice? _completionUndoNotice;

  /// Timer that dismisses the completion Undo notice after five seconds.
  Timer? _completionUndoTimer;

  /// Serializes settings writes so rapid interactions cannot save out of order.
  Future<void> _saveChain = Future<void>.value();

  /// Starts the document and progress reads once for this workspace route.
  @override
  void initState() {
    super.initState();
    _document = _loadWorkspace();
  }

  /// Releases the transient completion-notice timer.
  @override
  void dispose() {
    _completionUndoTimer?.cancel();
    super.dispose();
  }

  /// Loads immutable source data and mutable progress concurrently.
  Future<PatternDocument?> _loadWorkspace() async {
    final documentFuture = widget.patternDocuments.getById(widget.documentId);
    final progressFuture = widget.progress.getForDocument(widget.documentId);
    final document = await documentFuture;
    final progress = await progressFuture;
    _progress = progress;
    _completedCells = Set<GridCoordinate>.unmodifiable(
      progress?.completedCells ?? const <GridCoordinate>[],
    );
    _settings =
        progress?.viewport?.renderSettings ?? const PatternRenderSettings();
    return document;
  }

  /// Builds the compact toolbar, loading state, settings panel, and viewport.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PatternDocument?>(
      future: _document,
      builder: (context, snapshot) {
        // The loaded document drives both the app-bar title and viewport body.
        final document = snapshot.data;
        return Scaffold(
          appBar: AppBar(
            toolbarHeight: 48,
            automaticallyImplyLeading: false,
            leadingWidth: 56,
            leading: IconButton(
              key: const ValueKey('workspace-back'),
              tooltip: 'Back',
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(
              document?.title ?? 'Pattern Workspace',
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              if (document != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${document.grid.dimensions.rows} × '
                      '${document.grid.dimensions.columns}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
            ],
          ),
          body: _buildBody(snapshot.connectionState, document),
        );
      },
    );
  }

  /// Builds loading, missing-document, and loaded workspace body states.
  Widget _buildBody(
    ConnectionState connectionState,
    PatternDocument? document,
  ) {
    if (connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator());
    }
    if (document == null) {
      return const Center(child: Text('This pattern is no longer available.'));
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        // Cap the overlay without changing the pattern viewport's layout.
        final panelWidth = math.min(
          280.0,
          math.max(0.0, constraints.maxWidth - 24),
        );
        final paletteWidth = math.min(
          320.0,
          math.max(0.0, constraints.maxWidth - 24),
        );
        return Listener(
          behavior: HitTestBehavior.translucent,
          onPointerUp: _dismissCompletionUndoAfterPointer,
          child: Stack(
            children: [
              Positioned.fill(
                child: PatternRenderView(
                  document: document,
                  settings: _settings,
                  selection: _selection,
                  completedCells: _completedCells,
                  interactionMode: _interactionMode,
                  completionSelection: _completionSelection,
                  onSymbolSelected: _selectSymbol,
                  onCompletionCellSelected: _toggleCompletionCell,
                  onCompletionEditUnavailable: _showCompletionZoomGuidance,
                  onInteraction: _dismissCompletionUndo,
                ),
              ),
              if (_showSettings)
                Positioned(
                  left: 12,
                  top: 12,
                  bottom: 72,
                  key: const ValueKey('renderer-settings-panel'),
                  width: panelWidth,
                  child: _PatternRenderSettingsPanel(
                    settings: _settings,
                    onChanged: _applySettings,
                    onOpacityChanged: _previewOpacity,
                    onOpacityChangeEnd: _saveOpacity,
                    onCompletedOpacityChanged: _previewCompletedOpacity,
                    onCompletedOpacityChangeEnd: _saveCompletedOpacity,
                  ),
                ),
              if (_showSymbolPalette)
                Positioned(
                  right: 12,
                  top: 12,
                  bottom: 72,
                  key: const ValueKey('symbol-palette-panel'),
                  width: paletteWidth,
                  child: _PatternSymbolPalettePanel(
                    document: document,
                    selection: _selection,
                    onSelected: _selectSymbol,
                  ),
                ),
              if (_interactionMode == PatternInteractionMode.editCompletion)
                Positioned(
                  left: 72,
                  right: 72,
                  bottom: 12,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: _CompletionActionBar(
                      selectionCount: _completionSelection.length,
                      undoMessage: _completionUndoNotice?.message,
                      onUndo: _completionUndoNotice == null
                          ? null
                          : _undoCompletionAction,
                      onMarkCompleted: () =>
                          _applyCompletionSelection(completed: true),
                      onMarkIncomplete: () =>
                          _applyCompletionSelection(completed: false),
                      onClearSelection: _clearCompletionSelection,
                    ),
                  ),
                ),
              Positioned(
                right: 12,
                bottom: 12,
                child: _WorkspaceFloatingMenu(
                  isExpanded: _isFloatingMenuExpanded,
                  activeOption: _activeMenuOption,
                  onToggle: _toggleFloatingMenu,
                  onSelected: _selectMenuOption,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Selects a symbol and opens its inspector when selection is non-null.
  void _selectSymbol(String? symbolId) {
    _dismissCompletionUndo();
    setState(() {
      _selection = _selection.select(symbolId);
      if (symbolId != null) {
        _activeMenuOption = _WorkspaceMenuOption.symbolPalette;
        _isFloatingMenuExpanded = false;
      }
    });
  }

  /// Opens or collapses the floating menu without changing the active choice.
  void _toggleFloatingMenu() {
    _dismissCompletionUndo();
    setState(() => _isFloatingMenuExpanded = !_isFloatingMenuExpanded);
  }

  /// Activates one menu choice while closing every other workspace surface.
  void _selectMenuOption(_WorkspaceMenuOption option) {
    _dismissCompletionUndo();
    setState(() {
      if (_activeMenuOption == option) {
        _activeMenuOption = null;
      } else {
        _activeMenuOption = option;
      }
      if (_activeMenuOption != _WorkspaceMenuOption.completionSelection) {
        _completionSelection = _completionSelection.clear();
      }
      if (_activeMenuOption == _WorkspaceMenuOption.completionSelection) {
        _selection = _selection.select(null);
      }
      _isFloatingMenuExpanded = false;
    });
  }

  /// Toggles one populated coordinate in the transient completion selection.
  void _toggleCompletionCell(GridCoordinate coordinate) {
    _dismissCompletionUndo();
    setState(() {
      _completionSelection = _completionSelection.toggle(coordinate);
    });
  }

  /// Clears exact-cell selection without changing persisted progress.
  void _clearCompletionSelection() {
    _dismissCompletionUndo();
    setState(() {
      _completionSelection = _completionSelection.clear();
    });
  }

  /// Applies one completion value to every exactly selected coordinate.
  void _applyCompletionSelection({required bool completed}) {
    _dismissCompletionUndo();
    if (_completionSelection.isEmpty) return;
    final previousCells = _completedCells;
    final updatedCells = Set<GridCoordinate>.of(_completedCells);
    if (completed) {
      updatedCells.addAll(_completionSelection.coordinates);
    } else {
      updatedCells.removeAll(_completionSelection.coordinates);
    }
    final changedCellCount = completed
        ? updatedCells.length - previousCells.length
        : previousCells.length - updatedCells.length;
    setState(() {
      _completedCells = Set<GridCoordinate>.unmodifiable(updatedCells);
      _completionSelection = _completionSelection.clear();
    });
    if (changedCellCount == 0) return;
    _persistCompletedCells(_completedCells);
    final actionLabel = completed ? 'completed' : 'incomplete';
    final message =
        '$changedCellCount ${changedCellCount == 1 ? 'cell' : 'cells'} '
        'marked $actionLabel.';
    _showCompletionUndo(previousCells: previousCells, message: message);
  }

  /// Shows an inline Undo notice for exactly five seconds.
  void _showCompletionUndo({
    required Set<GridCoordinate> previousCells,
    required String message,
  }) {
    _completionUndoTimer?.cancel();
    setState(() {
      _completionUndoNotice = _CompletionUndoNotice(
        message: message,
        previousCells: previousCells,
      );
    });
    _completionUndoTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _completionUndoNotice == null) return;
      setState(() => _completionUndoNotice = null);
      _completionUndoTimer = null;
    });
  }

  /// Restores completion state captured by the visible Undo notice.
  void _undoCompletionAction() {
    final notice = _completionUndoNotice;
    if (notice == null) return;
    _completionUndoTimer?.cancel();
    _completionUndoTimer = null;
    setState(() {
      _completionUndoNotice = null;
      _completedCells = notice.previousCells;
    });
    _persistCompletedCells(_completedCells);
  }

  /// Removes completion Undo feedback when another interaction begins.
  void _dismissCompletionUndo() {
    if (_completionUndoNotice == null) return;
    _completionUndoTimer?.cancel();
    _completionUndoTimer = null;
    setState(() => _completionUndoNotice = null);
  }

  /// Dismisses the notice after a body pointer action finishes dispatching.
  void _dismissCompletionUndoAfterPointer(PointerUpEvent event) {
    final visibleNotice = _completionUndoNotice;
    if (visibleNotice == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(_completionUndoNotice, visibleNotice)) return;
      _dismissCompletionUndo();
    });
  }

  /// Persists completed coordinates while preserving markers and viewport data.
  void _persistCompletedCells(Set<GridCoordinate> completedCells) {
    final current = _progress;
    final updated = ProgressState(
      documentId: widget.documentId,
      schemaVersion: current?.schemaVersion ?? 1,
      completedCells: completedCells,
      markers: current?.markers ?? const [],
      viewport: current?.viewport,
      lastInteractionAt: DateTime.now().toUtc(),
    );
    _queueProgressSave(updated);
  }

  /// Explains why exact completion editing is unavailable at overview zoom.
  void _showCompletionZoomGuidance() {
    _dismissCompletionUndo();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Zoom in to select individual cells.')),
      );
  }

  /// Applies and persists a discrete renderer setting change.
  void _applySettings(PatternRenderSettings settings) {
    _dismissCompletionUndo();
    setState(() => _settings = settings);
    _persistSettings(settings);
  }

  /// Updates opacity immediately while the slider is moving.
  void _previewOpacity(double opacity) {
    _dismissCompletionUndo();
    setState(() {
      _settings = _settings.copyWith(cellColorOpacity: opacity);
    });
  }

  /// Persists the final opacity after a slider interaction settles.
  void _saveOpacity(double opacity) {
    _dismissCompletionUndo();
    final settings = _settings.copyWith(cellColorOpacity: opacity);
    setState(() => _settings = settings);
    _persistSettings(settings);
  }

  /// Updates completed-cell opacity immediately while its slider is moving.
  void _previewCompletedOpacity(double opacity) {
    _dismissCompletionUndo();
    setState(() {
      _settings = _settings.copyWith(completedCellOpacity: opacity);
    });
  }

  /// Persists the final completed-cell opacity after slider interaction.
  void _saveCompletedOpacity(double opacity) {
    _dismissCompletionUndo();
    final settings = _settings.copyWith(completedCellOpacity: opacity);
    setState(() => _settings = settings);
    _persistSettings(settings);
  }

  /// Replaces only render settings while preserving progress and camera fields.
  void _persistSettings(PatternRenderSettings settings) {
    final current = _progress;
    final viewport =
        current?.viewport?.copyWith(renderSettings: settings) ??
        ViewportState(
          zoom: 1,
          panX: 0,
          panY: 0,
          anchor: const GridCoordinate(0, 0),
          renderSettings: settings,
        );
    final updated = ProgressState(
      documentId: widget.documentId,
      schemaVersion: current?.schemaVersion ?? 1,
      completedCells: current?.completedCells ?? const [],
      markers: current?.markers ?? const [],
      viewport: viewport,
      lastInteractionAt: DateTime.now().toUtc(),
    );
    _queueProgressSave(updated);
  }

  /// Queues a complete progress snapshot after all earlier writes settle.
  void _queueProgressSave(ProgressState updated) {
    _progress = updated;
    final previousSave = _saveChain;
    _saveChain = () async {
      try {
        await previousSave;
      } on Object {
        // A prior failure must not prevent newer settings from being saved.
      }
      await widget.progress.save(updated);
    }();
    unawaited(_reportSaveFailure(_saveChain));
  }

  /// Shows non-blocking feedback when a queued settings write fails.
  Future<void> _reportSaveFailure(Future<void> save) async {
    try {
      await save;
    } on Object {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Unable to save pattern progress.')),
        );
    }
  }
}

/// Snapshot and message backing the transient inline completion Undo notice.
class _CompletionUndoNotice {
  /// Creates an immutable notice for one completed-cell change.
  _CompletionUndoNotice({
    required this.message,
    required Set<GridCoordinate> previousCells,
  }) : previousCells = Set<GridCoordinate>.unmodifiable(previousCells);

  /// Human-readable description of the completion change.
  final String message;

  /// Completion snapshot restored when Undo is selected.
  final Set<GridCoordinate> previousCells;
}

/// Collapsible bottom-right menu for mutually exclusive workspace surfaces.
class _WorkspaceFloatingMenu extends StatelessWidget {
  /// Creates the menu from its expansion and active-selection state.
  const _WorkspaceFloatingMenu({
    required this.isExpanded,
    required this.activeOption,
    required this.onToggle,
    required this.onSelected,
  });

  /// Whether the three workspace choices are currently visible.
  final bool isExpanded;

  /// The only currently active workspace choice, if any.
  final _WorkspaceMenuOption? activeOption;

  /// Opens or closes the three-choice floating menu.
  final VoidCallback onToggle;

  /// Activates or clears one workspace choice.
  final ValueChanged<_WorkspaceMenuOption> onSelected;

  /// Builds vertically stacked floating choices above the menu trigger.
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isExpanded) ...[
          _WorkspaceMenuButton(
            key: const ValueKey('floating-menu-completion-selection'),
            tooltip: 'Completion selection',
            icon: Icons.check_box_outlined,
            isSelected:
                activeOption == _WorkspaceMenuOption.completionSelection,
            selectedColor: colors.secondaryContainer,
            onPressed: () =>
                onSelected(_WorkspaceMenuOption.completionSelection),
          ),
          const SizedBox(height: 8),
          _WorkspaceMenuButton(
            key: const ValueKey('floating-menu-symbol-palette'),
            tooltip: 'Symbol palette',
            icon: Icons.palette_outlined,
            isSelected: activeOption == _WorkspaceMenuOption.symbolPalette,
            selectedColor: colors.secondaryContainer,
            onPressed: () => onSelected(_WorkspaceMenuOption.symbolPalette),
          ),
          const SizedBox(height: 8),
          _WorkspaceMenuButton(
            key: const ValueKey('floating-menu-renderer-settings'),
            tooltip: 'Renderer settings',
            icon: Icons.tune,
            isSelected: activeOption == _WorkspaceMenuOption.rendererSettings,
            selectedColor: colors.secondaryContainer,
            onPressed: () => onSelected(_WorkspaceMenuOption.rendererSettings),
          ),
          const SizedBox(height: 8),
        ],
        FloatingActionButton.small(
          key: const ValueKey('floating-menu-toggle'),
          heroTag: 'workspace-floating-menu',
          tooltip: isExpanded ? 'Close workspace menu' : 'Open workspace menu',
          onPressed: onToggle,
          child: Icon(isExpanded ? Icons.close : Icons.menu),
        ),
      ],
    );
  }
}

/// One visible choice in the workspace floating menu.
class _WorkspaceMenuButton extends StatelessWidget {
  /// Creates one small floating button representing a workspace surface.
  const _WorkspaceMenuButton({
    required super.key,
    required this.tooltip,
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.onPressed,
  });

  /// Accessible label explaining the menu choice.
  final String tooltip;

  /// Icon representing the menu choice.
  final IconData icon;

  /// Whether this choice is the currently active workspace surface.
  final bool isSelected;

  /// Highlight color used for the active choice.
  final Color selectedColor;

  /// Activates or clears this menu choice.
  final VoidCallback onPressed;

  /// Builds a colored small floating-action button for the choice.
  @override
  Widget build(BuildContext context) => FloatingActionButton.small(
    heroTag: tooltip,
    tooltip: tooltip,
    backgroundColor: isSelected ? selectedColor : null,
    onPressed: onPressed,
    child: Icon(icon),
  );
}

/// Floating controls for applying completion state to exact selected cells.
class _CompletionActionBar extends StatelessWidget {
  /// Creates completion controls for the current transient cell selection.
  const _CompletionActionBar({
    required this.selectionCount,
    required this.undoMessage,
    required this.onUndo,
    required this.onMarkCompleted,
    required this.onMarkIncomplete,
    required this.onClearSelection,
  });

  /// Number of exact cells awaiting a completion action.
  final int selectionCount;

  /// Completion result announced inline without covering workspace controls.
  final String? undoMessage;

  /// Restores the completion snapshot associated with [undoMessage].
  final VoidCallback? onUndo;

  /// Marks every selected coordinate complete.
  final VoidCallback onMarkCompleted;

  /// Marks every selected coordinate incomplete.
  final VoidCallback onMarkIncomplete;

  /// Clears selection without changing completion state.
  final VoidCallback onClearSelection;

  /// Builds a compact action surface that can wrap on narrow viewports.
  @override
  Widget build(BuildContext context) {
    final hasSelection = selectionCount > 0;
    return Material(
      key: const ValueKey('completion-action-bar'),
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.center,
          children: [
            if (undoMessage == null)
              Text(
                hasSelection
                    ? '$selectionCount selected'
                    : 'Tap stitches to select',
              )
            else
              Container(
                key: const ValueKey('completion-undo-snackbar'),
                constraints: const BoxConstraints(maxWidth: 320),
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.inverseSurface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Semantics(
                  liveRegion: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          undoMessage!,
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onInverseSurface,
                          ),
                        ),
                      ),
                      TextButton(
                        key: const ValueKey('undo-completion-action'),
                        onPressed: onUndo,
                        child: const Text('Undo'),
                      ),
                    ],
                  ),
                ),
              ),
            FilledButton.icon(
              key: const ValueKey('mark-completed'),
              onPressed: hasSelection ? onMarkCompleted : null,
              icon: const Icon(Icons.check),
              label: const Text('Complete'),
            ),
            OutlinedButton.icon(
              key: const ValueKey('mark-incomplete'),
              onPressed: hasSelection ? onMarkIncomplete : null,
              icon: const Icon(Icons.remove_done),
              label: const Text('Incomplete'),
            ),
            IconButton(
              key: const ValueKey('clear-completion-selection'),
              tooltip: 'Clear cell selection',
              onPressed: hasSelection ? onClearSelection : null,
              icon: const Icon(Icons.clear),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact controls for the visual layers supported by the current renderer.
class _PatternRenderSettingsPanel extends StatelessWidget {
  /// Creates controls for [settings].
  const _PatternRenderSettingsPanel({
    required this.settings,
    required this.onChanged,
    required this.onOpacityChanged,
    required this.onOpacityChangeEnd,
    required this.onCompletedOpacityChanged,
    required this.onCompletedOpacityChangeEnd,
  });

  /// Current immutable renderer settings.
  final PatternRenderSettings settings;

  /// Callback for discrete switch and preset changes.
  final ValueChanged<PatternRenderSettings> onChanged;

  /// Callback for live opacity previews.
  final ValueChanged<double> onOpacityChanged;

  /// Callback for persisting a settled opacity value.
  final ValueChanged<double> onOpacityChangeEnd;

  /// Callback for live completed-cell opacity previews.
  final ValueChanged<double> onCompletedOpacityChanged;

  /// Callback for persisting a settled completed-cell opacity value.
  final ValueChanged<double> onCompletedOpacityChangeEnd;

  /// Builds scrollable controls that fit desktop and compact-height layouts.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              'Renderer Settings',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          SwitchListTile(
            key: const ValueKey('show-symbols-setting'),
            dense: true,
            title: const Text('Symbols'),
            value: settings.showSymbols,
            onChanged: (value) =>
                onChanged(settings.copyWith(showSymbols: value)),
          ),
          SwitchListTile(
            key: const ValueKey('show-cell-color-setting'),
            dense: true,
            title: const Text('Cell colors'),
            value: settings.showCellColor,
            onChanged: (value) =>
                onChanged(settings.copyWith(showCellColor: value)),
          ),
          if (settings.showCellColor) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(child: Text('Color opacity')),
                  Text('${(settings.cellColorOpacity * 100).round()}%'),
                ],
              ),
            ),
            Slider(
              key: const ValueKey('cell-color-opacity-setting'),
              value: settings.cellColorOpacity,
              onChanged: onOpacityChanged,
              onChangeEnd: onOpacityChangeEnd,
            ),
          ],
          SwitchListTile(
            key: const ValueKey('show-grid-setting'),
            dense: true,
            title: const Text('Grid'),
            value: settings.showGrid,
            onChanged: (value) => onChanged(settings.copyWith(showGrid: value)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DropdownButtonFormField<GridColorPreset>(
              key: const ValueKey('grid-color-setting'),
              initialValue: settings.gridColor,
              decoration: const InputDecoration(
                labelText: 'Grid color',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: GridColorPreset.black,
                  child: Text('Black'),
                ),
                DropdownMenuItem(
                  value: GridColorPreset.darkGray,
                  child: Text('Dark gray'),
                ),
                DropdownMenuItem(
                  value: GridColorPreset.lightGray,
                  child: Text('Light gray'),
                ),
              ],
              onChanged: settings.showGrid
                  ? (value) {
                      if (value != null) {
                        onChanged(settings.copyWith(gridColor: value));
                      }
                    }
                  : null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: DropdownButtonFormField<SelectionHighlightColorPreset>(
              key: const ValueKey('selection-highlight-color-setting'),
              initialValue: settings.selectionHighlightColor,
              decoration: const InputDecoration(
                labelText: 'Selection highlight',
                isDense: true,
              ),
              items: const [
                DropdownMenuItem(
                  value: SelectionHighlightColorPreset.amber,
                  child: Text('Amber'),
                ),
                DropdownMenuItem(
                  value: SelectionHighlightColorPreset.teal,
                  child: Text('Teal'),
                ),
                DropdownMenuItem(
                  value: SelectionHighlightColorPreset.magenta,
                  child: Text('Magenta'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onChanged(settings.copyWith(selectionHighlightColor: value));
                }
              },
            ),
          ),
          SwitchListTile(
            key: const ValueKey('show-regions-setting'),
            dense: true,
            title: const Text('Source regions'),
            value: settings.showRegions,
            onChanged: (value) =>
                onChanged(settings.copyWith(showRegions: value)),
          ),
          SwitchListTile(
            key: const ValueKey('show-completed-overlay-setting'),
            dense: true,
            title: const Text('Completed-cell overlay'),
            value: settings.showCompletedCellOverlay,
            onChanged: (value) =>
                onChanged(settings.copyWith(showCompletedCellOverlay: value)),
          ),
          if (settings.showCompletedCellOverlay) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: DropdownButtonFormField<CompletedCellColorPreset>(
                key: const ValueKey('completed-cell-color-setting'),
                initialValue: settings.completedCellColor,
                decoration: const InputDecoration(
                  labelText: 'Completed-cell color',
                  isDense: true,
                ),
                items: const [
                  DropdownMenuItem(
                    value: CompletedCellColorPreset.neutralGray,
                    child: Text('Neutral gray'),
                  ),
                  DropdownMenuItem(
                    value: CompletedCellColorPreset.darkGray,
                    child: Text('Dark gray'),
                  ),
                  DropdownMenuItem(
                    value: CompletedCellColorPreset.lightGray,
                    child: Text('Light gray'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    onChanged(settings.copyWith(completedCellColor: value));
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(child: Text('Completed opacity')),
                  Text('${(settings.completedCellOpacity * 100).round()}%'),
                ],
              ),
            ),
            Slider(
              key: const ValueKey('completed-cell-opacity-setting'),
              value: settings.completedCellOpacity,
              onChanged: onCompletedOpacityChanged,
              onChangeEnd: onCompletedOpacityChangeEnd,
            ),
          ],
          SwitchListTile(
            key: const ValueKey('include-completed-in-selection-setting'),
            dense: true,
            title: const Text('Select completed cells'),
            subtitle: const Text(
              'Include completed cells in symbol highlighting',
            ),
            value: settings.includeCompletedCellsInSelection,
            onChanged: (value) => onChanged(
              settings.copyWith(includeCompletedCellsInSelection: value),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating symbol palette and selected-thread inspector.
class _PatternSymbolPalettePanel extends StatelessWidget {
  /// Creates a palette over one immutable pattern document.
  const _PatternSymbolPalettePanel({
    required this.document,
    required this.selection,
    required this.onSelected,
  });

  /// Document supplying symbols and complete thread definitions.
  final PatternDocument document;

  /// Current ephemeral symbol selection.
  final PatternRenderSelection selection;

  /// Callback used to select or clear a symbol.
  final ValueChanged<String?> onSelected;

  /// Builds selected details followed by every selectable document symbol.
  @override
  Widget build(BuildContext context) {
    final selected = selection.selectedSymbolId == null
        ? null
        : document.symbolById(selection.selectedSymbolId!);
    return Material(
      elevation: 8,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Symbols',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (selection.hasSelection)
                  IconButton(
                    key: const ValueKey('clear-symbol-selection'),
                    tooltip: 'Clear selection',
                    onPressed: () => onSelected(null),
                    icon: const Icon(Icons.clear),
                  ),
              ],
            ),
          ),
          if (selected != null) _SelectedSymbolDetails(symbol: selected),
          const Divider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                for (final symbol in document.symbols)
                  ListTile(
                    key: ValueKey('symbol-palette-${symbol.id}'),
                    dense: true,
                    selected: symbol.id == selection.selectedSymbolId,
                    onTap: () => onSelected(symbol.id),
                    leading: _SymbolSwatch(symbol: symbol),
                    title: Text(symbol.thread.name ?? symbol.id),
                    subtitle: Text(_threadSummary(symbol.thread)),
                    trailing: Text(
                      symbol.displayGlyph,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Detailed metadata for the currently selected symbol and thread.
class _SelectedSymbolDetails extends StatelessWidget {
  /// Creates an inspector for [symbol].
  const _SelectedSymbolDetails({required this.symbol});

  /// Selected symbol whose thread metadata is displayed.
  final SymbolDefinition symbol;

  /// Builds glyph, catalog, and conversion information.
  @override
  Widget build(BuildContext context) {
    final thread = symbol.thread;
    return Padding(
      key: const ValueKey('selected-symbol-details'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SymbolSwatch(symbol: symbol, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      thread.name ?? symbol.id,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(_threadSummary(thread)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (thread.conversionNotes != null)
            Text('Conversion: ${thread.conversionNotes}'),
        ],
      ),
    );
  }
}

/// Colored glyph swatch shared by palette rows and selected details.
class _SymbolSwatch extends StatelessWidget {
  /// Creates a square swatch for [symbol].
  const _SymbolSwatch({required this.symbol, this.size = 36});

  /// Symbol whose glyph and thread color are represented.
  final SymbolDefinition symbol;

  /// Logical width and height of the square swatch.
  final double size;

  /// Builds a contrast-aware glyph over the imported thread color.
  @override
  Widget build(BuildContext context) {
    final color = _parseThreadColor(symbol.thread.color);
    final foreground = color.computeLuminance() > 0.45
        ? Colors.black87
        : Colors.white;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        symbol.displayGlyph,
        style: TextStyle(
          color: foreground,
          fontSize: size * 0.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Produces a compact manufacturer and catalog label for [thread].
String _threadSummary(ThreadDefinition thread) {
  final parts = <String>[
    if (thread.brand != null) thread.brand!,
    if (thread.catalogNumber != null) thread.catalogNumber!,
  ];
  return parts.isEmpty ? thread.color : parts.join(' ');
}

/// Converts a validated domain thread color to an opaque Flutter color.
Color _parseThreadColor(String value) =>
    Color(int.parse('FF${value.substring(1)}', radix: 16));

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
    this.onCompletionCellSelected,
    this.onCompletionEditUnavailable,
    this.onInteraction,
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

  /// Reports exact-cell selection changes in completion-edit mode.
  final ValueChanged<GridCoordinate>? onCompletionCellSelected;

  /// Reports completion taps attempted below the legible zoom threshold.
  final VoidCallback? onCompletionEditUnavailable;

  /// Reports viewport interaction so transient completion feedback can clear.
  final VoidCallback? onInteraction;

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
        onCompletionCellSelected: onCompletionCellSelected,
        onCompletionEditUnavailable: onCompletionEditUnavailable,
        onInteraction: onInteraction,
      ),
    );
  }
}

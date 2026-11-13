import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/pattern_document.dart';
import '../../domain/progress_models.dart';
import '../../domain/repositories.dart';
import '../../domain/value_objects.dart';
import '../pattern_renderer/pattern_interaction.dart';
import '../pattern_renderer/pattern_render_selection.dart';
import '../pattern_renderer/pattern_render_view.dart';
import 'pattern_workspace_controls.dart';
import 'pattern_workspace_palette.dart';
import 'pattern_workspace_settings_panel.dart';

export '../pattern_renderer/pattern_render_view.dart';

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

  /// Loaded immutable document used to resolve selection references.
  PatternDocument? _loadedDocument;

  /// Current persisted or default render settings.
  PatternRenderSettings _settings = const PatternRenderSettings();

  /// Latest complete progress graph used to preserve unrelated user state.
  ProgressState? _progress;

  /// Completed coordinates loaded with the mutable progress graph.
  Set<GridCoordinate> _completedCells = const <GridCoordinate>{};

  /// Whether the bottom-right floating menu currently exposes its choices.
  bool _isFloatingMenuExpanded = false;

  /// The only active workspace surface, or null when none is selected.
  WorkspaceMenuOption? _activeMenuOption;

  /// Current ephemeral symbol selection, intentionally not persisted.
  PatternRenderSelection _selection = const PatternRenderSelection();

  /// Whether the renderer settings surface is the active menu choice.
  bool get _showSettings =>
      _activeMenuOption == WorkspaceMenuOption.rendererSettings;

  /// Whether the symbol palette surface is the active menu choice.
  bool get _showSymbolPalette =>
      _activeMenuOption == WorkspaceMenuOption.symbolPalette;

  /// Derives tap behavior from the currently active mutually exclusive choice.
  PatternInteractionMode get _interactionMode =>
      _activeMenuOption == WorkspaceMenuOption.completionSelection
      ? PatternInteractionMode.editCompletion
      : PatternInteractionMode.browse;

  /// Exact cells selected for the next completion action.
  CompletionCellSelection _completionSelection =
      CompletionCellSelection.empty();

  /// Inline Undo notice shown without covering workspace controls.
  CompletionUndoNotice? _completionUndoNotice;

  /// Timer that makes the completion Undo notice eligible for dismissal.
  Timer? _completionUndoTimer;

  /// Coalesces camera writes after successive settled viewport interactions.
  Timer? _viewportSaveTimer;

  /// Latest camera snapshot awaiting its debounced progress write.
  ViewportState? _pendingViewport;

  /// Whether the visible completion Undo notice has completed its minimum time.
  bool _completionUndoCanDismiss = false;

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
    _flushPendingViewportSave();
    _viewportSaveTimer?.cancel();
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
    _loadedDocument = document;
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
                  onBackstitchSelected: _selectBackstitch,
                  onCompletionCellSelected: _toggleCompletionCell,
                  onCompletionCellAdded: _addCompletionCell,
                  onCompletionEditUnavailable: _showCompletionZoomGuidance,
                  onInteraction: _dismissCompletionUndo,
                  initialViewport: _progress?.viewport,
                  onViewportSettled: _scheduleViewportSave,
                ),
              ),
              if (_showSettings)
                Positioned(
                  left: 12,
                  top: 12,
                  bottom: 72,
                  key: const ValueKey('renderer-settings-panel'),
                  width: panelWidth,
                  child: PatternRenderSettingsPanel(
                    settings: _settings,
                    onChanged: _applySettings,
                    onOpacityChanged: _previewOpacity,
                    onOpacityChangeEnd: _saveOpacity,
                    onCompletedOpacityChanged: _previewCompletedOpacity,
                    onCompletedOpacityChangeEnd: _saveCompletedOpacity,
                    onClose: _closeActiveMenuOption,
                  ),
                ),
              if (_showSymbolPalette)
                Positioned(
                  right: 12,
                  top: 12,
                  bottom: 72,
                  key: const ValueKey('symbol-palette-panel'),
                  width: paletteWidth,
                  child: PatternSymbolPalettePanel(
                    document: document,
                    selection: _selection,
                    onSelected: _selectSelection,
                    onClose: _closeActiveMenuOption,
                  ),
                ),
              if (_interactionMode == PatternInteractionMode.editCompletion)
                Positioned(
                  left: 72,
                  right: 72,
                  bottom: 12,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: CompletionActionBar(
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
                      onClose: _closeActiveMenuOption,
                    ),
                  ),
                ),
              Positioned(
                right: 12,
                bottom: 12,
                child: WorkspaceFloatingMenu(
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

  /// Selects a symbol without changing the currently open workspace surface.
  void _selectSymbol(String? symbolId) {
    _dismissCompletionUndo();
    setState(() {
      final symbol = symbolId == null
          ? null
          : _loadedDocument?.symbolById(symbolId);
      _selection = symbol == null
          ? const PatternRenderSelection()
          : _selection.selectSymbol(symbol.id, symbol.threadId);
    });
  }

  /// Selects backstitch linework without changing the active workspace surface.
  void _selectBackstitch(PatternRenderSelection selection) {
    _dismissCompletionUndo();
    setState(() => _selection = selection);
  }

  /// Applies the symbol or backstitch selection produced by the palette.
  void _selectSelection(PatternRenderSelection selection) {
    _dismissCompletionUndo();
    setState(() => _selection = selection);
  }

  /// Opens or collapses the floating menu without changing the active choice.
  void _toggleFloatingMenu() {
    _dismissCompletionUndo();
    setState(() => _isFloatingMenuExpanded = !_isFloatingMenuExpanded);
  }

  /// Activates one menu choice while closing every other workspace surface.
  void _selectMenuOption(WorkspaceMenuOption option) {
    _dismissCompletionUndo();
    final enablesCompletedOverlay =
        option == WorkspaceMenuOption.completionSelection &&
        _activeMenuOption != WorkspaceMenuOption.completionSelection &&
        !_settings.showCompletedCellOverlay;
    final updatedSettings = enablesCompletedOverlay
        ? _settings.copyWith(showCompletedCellOverlay: true)
        : null;
    setState(() {
      if (_activeMenuOption == option) {
        _activeMenuOption = null;
      } else {
        _activeMenuOption = option;
      }
      if (_activeMenuOption != WorkspaceMenuOption.completionSelection) {
        _completionSelection = _completionSelection.clear();
      }
      if (_activeMenuOption == WorkspaceMenuOption.completionSelection) {
        _selection = _selection.clear();
      }
      if (updatedSettings != null) {
        _settings = updatedSettings;
      }
      _isFloatingMenuExpanded = false;
    });
    if (updatedSettings != null) {
      _persistSettings(updatedSettings);
    }
  }

  /// Closes the active workspace surface without expanding the floating menu.
  void _closeActiveMenuOption() {
    _dismissCompletionUndo();
    setState(() {
      if (_activeMenuOption == WorkspaceMenuOption.completionSelection) {
        _completionSelection = _completionSelection.clear();
      }
      _activeMenuOption = null;
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

  /// Adds one populated coordinate without toggling existing selection.
  void _addCompletionCell(GridCoordinate coordinate) {
    _dismissCompletionUndo();
    setState(() {
      _completionSelection = _completionSelection.add(coordinate);
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

  /// Shows an inline Undo notice that remains visible for at least five seconds.
  void _showCompletionUndo({
    required Set<GridCoordinate> previousCells,
    required String message,
  }) {
    _completionUndoTimer?.cancel();
    _completionUndoCanDismiss = false;
    setState(() {
      _completionUndoNotice = CompletionUndoNotice(
        message: message,
        previousCells: previousCells,
      );
    });
    _completionUndoTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _completionUndoNotice == null) return;
      _completionUndoCanDismiss = true;
      _completionUndoTimer = null;
    });
  }

  /// Restores completion state captured by the visible Undo notice.
  void _undoCompletionAction() {
    final notice = _completionUndoNotice;
    if (notice == null) return;
    _completionUndoTimer?.cancel();
    _completionUndoTimer = null;
    _completionUndoCanDismiss = false;
    setState(() {
      _completionUndoNotice = null;
      _completedCells = notice.previousCells;
    });
    _persistCompletedCells(_completedCells);
  }

  /// Removes eligible completion Undo feedback when another interaction begins.
  void _dismissCompletionUndo() {
    if (_completionUndoNotice == null || !_completionUndoCanDismiss) return;
    _completionUndoTimer?.cancel();
    _completionUndoTimer = null;
    _completionUndoCanDismiss = false;
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
    _flushPendingViewportSave();
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
    _flushPendingViewportSave();
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

  /// Schedules one progress write for the latest stable camera snapshot.
  void _scheduleViewportSave(ViewportState viewport) {
    _pendingViewport = viewport;
    _viewportSaveTimer?.cancel();
    _viewportSaveTimer = Timer(
      const Duration(milliseconds: 250),
      _flushPendingViewportSave,
    );
  }

  /// Saves the pending camera while retaining every current renderer setting.
  void _flushPendingViewportSave() {
    _viewportSaveTimer?.cancel();
    _viewportSaveTimer = null;
    final viewport = _pendingViewport;
    _pendingViewport = null;
    if (viewport == null) return;
    final current = _progress;
    final updated = ProgressState(
      documentId: widget.documentId,
      schemaVersion: current?.schemaVersion ?? 1,
      completedCells: current?.completedCells ?? const [],
      markers: current?.markers ?? const [],
      viewport: viewport.copyWith(renderSettings: _settings),
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

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/pattern_document.dart';
import '../../domain/progress_models.dart';
import '../../domain/repositories.dart';
import '../../domain/value_objects.dart';
import '../pattern_renderer/pattern_viewport.dart';

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

  /// Whether the left renderer-settings panel is visible.
  bool _showSettings = false;

  /// Serializes settings writes so rapid interactions cannot save out of order.
  Future<void> _saveChain = Future<void>.value();

  /// Starts the document and progress reads once for this workspace route.
  @override
  void initState() {
    super.initState();
    _document = _loadWorkspace();
  }

  /// Loads immutable source data and mutable progress concurrently.
  Future<PatternDocument?> _loadWorkspace() async {
    final documentFuture = widget.patternDocuments.getById(widget.documentId);
    final progressFuture = widget.progress.getForDocument(widget.documentId);
    final document = await documentFuture;
    final progress = await progressFuture;
    _progress = progress;
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
        // Cap the panel while preserving useful viewport width on small screens.
        final panelWidth = math.min(280.0, constraints.maxWidth * 0.8);
        return Row(
          children: [
            SizedBox(
              width: 56,
              child: Material(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: IconButton(
                  key: const ValueKey('renderer-settings-toggle'),
                  tooltip: 'Renderer settings',
                  isSelected: _showSettings,
                  onPressed: () =>
                      setState(() => _showSettings = !_showSettings),
                  icon: const Icon(Icons.tune),
                ),
              ),
            ),
            const VerticalDivider(width: 1),
            if (_showSettings)
              SizedBox(
                key: const ValueKey('renderer-settings-panel'),
                width: panelWidth,
                child: _PatternRenderSettingsPanel(
                  settings: _settings,
                  onChanged: _applySettings,
                  onOpacityChanged: _previewOpacity,
                  onOpacityChangeEnd: _saveOpacity,
                ),
              ),
            if (_showSettings) const VerticalDivider(width: 1),
            Expanded(
              child: PatternRenderView(document: document, settings: _settings),
            ),
          ],
        );
      },
    );
  }

  /// Applies and persists a discrete renderer setting change.
  void _applySettings(PatternRenderSettings settings) {
    setState(() => _settings = settings);
    _persistSettings(settings);
  }

  /// Updates opacity immediately while the slider is moving.
  void _previewOpacity(double opacity) {
    setState(() {
      _settings = _settings.copyWith(cellColorOpacity: opacity);
    });
  }

  /// Persists the final opacity after a slider interaction settles.
  void _saveOpacity(double opacity) {
    final settings = _settings.copyWith(cellColorOpacity: opacity);
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
          const SnackBar(content: Text('Unable to save renderer settings.')),
        );
    }
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
  });

  /// Current immutable renderer settings.
  final PatternRenderSettings settings;

  /// Callback for discrete switch and preset changes.
  final ValueChanged<PatternRenderSettings> onChanged;

  /// Callback for live opacity previews.
  final ValueChanged<double> onOpacityChanged;

  /// Callback for persisting a settled opacity value.
  final ValueChanged<double> onOpacityChangeEnd;

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
              'Renderer',
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
          SwitchListTile(
            key: const ValueKey('show-regions-setting'),
            dense: true,
            title: const Text('Source regions'),
            value: settings.showRegions,
            onChanged: (value) =>
                onChanged(settings.copyWith(showRegions: value)),
          ),
        ],
      ),
    );
  }
}

/// Places a normalized pattern document in the viewport rendering engine.
class PatternRenderView extends StatelessWidget {
  /// Creates a read-only viewport for [document].
  const PatternRenderView({
    required this.document,
    this.settings = const PatternRenderSettings(),
    super.key,
  });

  /// Pattern data rendered by the viewport.
  final PatternDocument document;

  /// Visual settings applied without changing viewport camera state.
  final PatternRenderSettings settings;

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
      child: PatternViewport(document: document, settings: settings),
    );
  }
}

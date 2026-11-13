import 'package:flutter/material.dart';

import '../../domain/progress_models.dart';

/// Compact controls for the visual layers supported by the current renderer.
class PatternRenderSettingsPanel extends StatelessWidget {
  /// Creates controls for [settings].
  const PatternRenderSettingsPanel({
    required this.settings,
    required this.onChanged,
    required this.onOpacityChanged,
    required this.onOpacityChangeEnd,
    required this.onCompletedOpacityChanged,
    required this.onCompletedOpacityChangeEnd,
    required this.onClose,
    super.key,
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

  /// Closes renderer settings without reopening the floating menu.
  final VoidCallback onClose;

  /// Builds scrollable controls that fit desktop and compact-height layouts.
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Renderer Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  key: const ValueKey('close-renderer-settings'),
                  tooltip: 'Close renderer settings',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          _buildSectionHeader(context, 'Cell display'),
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
          const Divider(height: 24),
          _buildSectionHeader(context, 'Guides and selection'),
          SwitchListTile(
            key: const ValueKey('show-grid-setting'),
            dense: true,
            title: const Text('Grid'),
            value: settings.showGrid,
            onChanged: (value) => onChanged(settings.copyWith(showGrid: value)),
          ),
          if (settings.showGrid)
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
                onChanged: (value) {
                  if (value != null) {
                    onChanged(settings.copyWith(gridColor: value));
                  }
                },
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
            key: const ValueKey('show-top-ruler-setting'),
            dense: true,
            title: const Text('Top ruler'),
            value: settings.showTopRuler,
            onChanged: (value) =>
                onChanged(settings.copyWith(showTopRuler: value)),
          ),
          SwitchListTile(
            key: const ValueKey('show-left-ruler-setting'),
            dense: true,
            title: const Text('Left ruler'),
            value: settings.showLeftRuler,
            onChanged: (value) =>
                onChanged(settings.copyWith(showLeftRuler: value)),
          ),
          SwitchListTile(
            key: const ValueKey('show-regions-setting'),
            dense: true,
            title: const Text('Source regions'),
            value: settings.showRegions,
            onChanged: (value) =>
                onChanged(settings.copyWith(showRegions: value)),
          ),
          const Divider(height: 24),
          _buildSectionHeader(context, 'Completion tracking'),
          SwitchListTile(
            key: const ValueKey('show-completed-overlay-setting'),
            dense: true,
            title: const Text('Completed-cell overlay'),
            value: settings.showCompletedCellOverlay,
            onChanged: (value) => onChanged(
              settings.copyWith(
                showCompletedCellOverlay: value,
                includeCompletedCellsInSelection: value
                    ? settings.includeCompletedCellsInSelection
                    : true,
              ),
            ),
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
        ],
      ),
    );
  }

  /// Builds a label that introduces one related renderer-settings region.
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(title, style: Theme.of(context).textTheme.labelLarge),
    );
  }
}

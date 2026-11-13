import 'package:flutter/material.dart';

import '../../domain/value_objects.dart';

/// Mutually exclusive workspace surface activated from the floating menu.
enum WorkspaceMenuOption {
  /// Opens renderer-specific visual settings.
  rendererSettings,

  /// Opens the symbol palette and thread inspector.
  symbolPalette,

  /// Enables exact-cell completion selection and its action surface.
  completionSelection,
}

/// Snapshot and message backing the transient inline completion Undo notice.
class CompletionUndoNotice {
  /// Creates an immutable notice for one completed-cell change.
  CompletionUndoNotice({
    required this.message,
    required Set<GridCoordinate> previousCells,
  }) : previousCells = Set<GridCoordinate>.unmodifiable(previousCells);

  /// Human-readable description of the completion change.
  final String message;

  /// Completion snapshot restored when Undo is selected.
  final Set<GridCoordinate> previousCells;
}

/// Collapsible bottom-right menu for mutually exclusive workspace surfaces.
class WorkspaceFloatingMenu extends StatelessWidget {
  /// Creates the menu from its expansion and active-selection state.
  const WorkspaceFloatingMenu({
    required this.isExpanded,
    required this.activeOption,
    required this.onToggle,
    required this.onSelected,
    super.key,
  });

  /// Whether the three workspace choices are currently visible.
  final bool isExpanded;

  /// The only currently active workspace choice, if any.
  final WorkspaceMenuOption? activeOption;

  /// Opens or closes the three-choice floating menu.
  final VoidCallback onToggle;

  /// Activates or clears one workspace choice.
  final ValueChanged<WorkspaceMenuOption> onSelected;

  /// Builds vertically stacked floating choices above the menu trigger.
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isExpanded) ...[
          WorkspaceMenuButton(
            key: const ValueKey('floating-menu-completion-selection'),
            tooltip: 'Completion selection',
            icon: Icons.check_box_outlined,
            isSelected: activeOption == WorkspaceMenuOption.completionSelection,
            selectedColor: colors.secondaryContainer,
            onPressed: () =>
                onSelected(WorkspaceMenuOption.completionSelection),
          ),
          const SizedBox(height: 8),
          WorkspaceMenuButton(
            key: const ValueKey('floating-menu-symbol-palette'),
            tooltip: 'Symbol palette',
            icon: Icons.palette_outlined,
            isSelected: activeOption == WorkspaceMenuOption.symbolPalette,
            selectedColor: colors.secondaryContainer,
            onPressed: () => onSelected(WorkspaceMenuOption.symbolPalette),
          ),
          const SizedBox(height: 8),
          WorkspaceMenuButton(
            key: const ValueKey('floating-menu-renderer-settings'),
            tooltip: 'Renderer settings',
            icon: Icons.tune,
            isSelected: activeOption == WorkspaceMenuOption.rendererSettings,
            selectedColor: colors.secondaryContainer,
            onPressed: () => onSelected(WorkspaceMenuOption.rendererSettings),
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
class WorkspaceMenuButton extends StatelessWidget {
  /// Creates one small floating button representing a workspace surface.
  const WorkspaceMenuButton({
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
class CompletionActionBar extends StatelessWidget {
  /// Creates completion controls for the current transient cell selection.
  const CompletionActionBar({
    required this.selectionCount,
    required this.undoMessage,
    required this.onUndo,
    required this.onMarkCompleted,
    required this.onMarkIncomplete,
    required this.onClearSelection,
    required this.onClose,
    super.key,
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

  /// Closes completion selection without reopening the floating menu.
  final VoidCallback onClose;

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
            TextButton(
              key: const ValueKey('clear-completion-selection'),
              onPressed: hasSelection ? onClearSelection : null,
              child: const Text('Clear selection'),
            ),
            IconButton(
              key: const ValueKey('close-completion-selection'),
              tooltip: 'Close completion selection',
              onPressed: onClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}

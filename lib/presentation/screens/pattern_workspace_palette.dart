import 'package:flutter/material.dart';

import '../../domain/pattern_backstitch.dart';
import '../../domain/pattern_definitions.dart';
import '../../domain/pattern_document.dart';
import '../pattern_renderer/pattern_render_selection.dart';

/// Floating symbol palette and selected-thread inspector.
class PatternSymbolPalettePanel extends StatelessWidget {
  /// Creates a palette over one immutable pattern document.
  const PatternSymbolPalettePanel({
    required this.document,
    required this.selection,
    required this.onSelected,
    required this.onClose,
    super.key,
  });

  /// Document supplying symbols and complete thread definitions.
  final PatternDocument document;

  /// Current ephemeral symbol selection.
  final PatternRenderSelection selection;

  /// Callback used to select or clear an item in the palette.
  final ValueChanged<PatternRenderSelection> onSelected;

  /// Closes the palette without reopening the floating menu.
  final VoidCallback onClose;

  /// Builds a fixed selected-details header above every selectable document symbol.
  @override
  Widget build(BuildContext context) {
    final selectedSymbol = selection.selectedSymbolId == null
        ? null
        : document.symbolById(selection.selectedSymbolId!);
    final selectedBackstitchDefinition =
        selection.selectedBackstitchDefinitionId == null
        ? null
        : document.backstitchDefinitionById(
            selection.selectedBackstitchDefinitionId!,
          );
    final selectedThread = selection.threadId == null
        ? null
        : document.threadById(selection.threadId!);
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
                  TextButton(
                    key: const ValueKey('clear-symbol-selection'),
                    onPressed: () => onSelected(const PatternRenderSelection()),
                    child: const Text('Clear'),
                  ),
                IconButton(
                  key: const ValueKey('close-symbol-palette'),
                  tooltip: 'Close symbol palette',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          if (selectedThread != null) ...[
            _SelectedThreadDetails(
              thread: selectedThread,
              symbol: selectedSymbol,
              backstitchDefinition: selectedBackstitchDefinition,
            ),
            const Divider(height: 1),
          ],
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 8),
              children: [
                for (final symbol in document.symbols)
                  Builder(
                    builder: (context) {
                      final thread = document.threadForSymbol(symbol)!;
                      return ListTile(
                        key: ValueKey('symbol-palette-${symbol.id}'),
                        dense: true,
                        selected:
                            selection.selectedSymbolId != null &&
                            thread.id == selection.threadId,
                        onTap: () => onSelected(
                          PatternRenderSelection().selectSymbol(
                            symbol.id,
                            thread.id,
                          ),
                        ),
                        leading: _SymbolSwatch(symbol: symbol, thread: thread),
                        title: Text(thread.name ?? symbol.id),
                        subtitle: Text(_threadSummary(thread)),
                        trailing: Text(
                          symbol.displayGlyph,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      );
                    },
                  ),
                if (document.backstitchDefinitions.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text('Backstitches'),
                  ),
                for (final definition in document.backstitchDefinitions)
                  Builder(
                    builder: (context) {
                      final thread = document.threadForBackstitch(definition)!;
                      return ListTile(
                        key: ValueKey('backstitch-palette-${definition.id}'),
                        dense: true,
                        selected:
                            selection.hasBackstitchSelection &&
                            thread.id == selection.threadId,
                        onTap: () => onSelected(
                          PatternRenderSelection().selectBackstitch(
                            definition.id,
                            thread.id,
                          ),
                        ),
                        leading: _BackstitchSwatch(thread: thread),
                        title: Text(thread.name ?? thread.id),
                        subtitle: Text(_threadSummary(thread)),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Concise metadata for the currently selected stitch and thread.
class _SelectedThreadDetails extends StatelessWidget {
  /// Creates an inspector for one selected symbol or backstitch definition.
  const _SelectedThreadDetails({
    required this.thread,
    required this.symbol,
    required this.backstitchDefinition,
  });

  /// Complete reusable thread record displayed by the inspector.
  final ThreadDefinition thread;

  /// Symbol that originated selection, when a cell or symbol was selected.
  final SymbolDefinition? symbol;

  /// Definition that originated selection, when linework was selected.
  final BackstitchDefinition? backstitchDefinition;

  /// Builds the selected stitch's type, optional strands, and thread catalog ID.
  @override
  Widget build(BuildContext context) {
    final selectedSymbol = symbol;
    final selectedBackstitch = backstitchDefinition;
    return Semantics(
      label: selectedBackstitch == null
          ? 'Selected symbol thread ${thread.id}'
          : 'Selected backstitch thread ${thread.id}',
      child: Padding(
        key: ValueKey(
          selectedBackstitch == null
              ? 'selected-symbol-details'
              : 'selected-backstitch-details',
        ),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedSymbol != null)
                  _SymbolSwatch(
                    symbol: selectedSymbol,
                    thread: thread,
                    size: 48,
                  )
                else
                  _BackstitchSwatch(thread: thread, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedSymbol != null) ...[
                        Text(
                          'Stitch type: '
                          '${_stitchTypeLabel(selectedSymbol.stitchType)}',
                        ),
                        if (selectedSymbol.threadCount != null)
                          Text(
                            'Number of strands: ${selectedSymbol.threadCount}',
                          ),
                      ],
                      if (selectedBackstitch != null) ...[
                        const Text('Stitch type: Backstitch'),
                        if (selectedBackstitch.threadCount != null)
                          Text(
                            'Number of strands: '
                            '${selectedBackstitch.threadCount}',
                          ),
                      ],
                      Text(_threadSummary(thread)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Colored glyph swatch shared by palette rows and selected details.
class _SymbolSwatch extends StatelessWidget {
  /// Creates a square swatch for [symbol].
  const _SymbolSwatch({
    required this.symbol,
    required this.thread,
    this.size = 36,
  });

  /// Symbol whose glyph and thread color are represented.
  final SymbolDefinition symbol;

  /// Separately stored thread whose color fills the swatch.
  final ThreadDefinition thread;

  /// Logical width and height of the square swatch.
  final double size;

  /// Builds a contrast-aware glyph over the imported thread color.
  @override
  Widget build(BuildContext context) {
    final color = _parseThreadColor(thread.color);
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

/// Colored line swatch used for palette backstitch entries and details.
class _BackstitchSwatch extends StatelessWidget {
  /// Creates a line swatch for one backstitch [thread].
  const _BackstitchSwatch({required this.thread, this.size = 36});

  /// Thread whose color is represented by the swatch.
  final ThreadDefinition thread;

  /// Logical width and height of the swatch.
  final double size;

  /// Builds a thread-colored line over a neutral rounded surface.
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Container(
      width: size * 0.68,
      height: 5,
      decoration: BoxDecoration(
        color: _parseThreadColor(thread.color),
        borderRadius: BorderRadius.circular(3),
      ),
    ),
  );
}

/// Produces a compact manufacturer and catalog label for [thread].
String _threadSummary(ThreadDefinition thread) {
  final parts = <String>[
    if (thread.brand != null) thread.brand!,
    if (thread.catalogNumber != null) thread.catalogNumber!,
  ];
  return parts.isEmpty ? thread.color : parts.join(' ');
}

/// Produces a user-facing label for an optional [type].
String _stitchTypeLabel(StitchType? type) {
  switch (type) {
    case StitchType.full:
      return 'Full stitch';
    case StitchType.half:
      return 'Half stitch';
    case StitchType.quarter:
      return 'Quarter stitch';
    case StitchType.threeQuarter:
      return 'Three-quarter stitch';
    case StitchType.frenchKnot:
      return 'French knot';
    case StitchType.unknown:
      return 'Unknown';
    case null:
      return 'Multiple or not specified';
  }
}

/// Converts a validated domain thread color to an opaque Flutter color.
Color _parseThreadColor(String value) =>
    Color(int.parse('FF${value.substring(1)}', radix: 16));

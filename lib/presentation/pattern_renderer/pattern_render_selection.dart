/// Ephemeral symbol selection used by the renderer and symbol palette.
class PatternRenderSelection {
  /// Creates a selection whose null symbol ID represents no active selection.
  const PatternRenderSelection({this.selectedSymbolId});

  /// Symbol highlighted across matching visible pattern cells.
  final String? selectedSymbolId;

  /// Returns whether a symbol is currently selected.
  bool get hasSelection => selectedSymbolId != null;

  /// Returns a new selection for [symbolId], or a cleared selection for null.
  PatternRenderSelection select(String? symbolId) =>
      PatternRenderSelection(selectedSymbolId: symbolId);

  /// Compares selections by their ephemeral selected symbol ID.
  @override
  bool operator ==(Object other) =>
      other is PatternRenderSelection &&
      selectedSymbolId == other.selectedSymbolId;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode => selectedSymbolId.hashCode;
}

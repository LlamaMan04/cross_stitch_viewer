/// Ephemeral renderer selection used by the viewport and symbol palette.
class PatternRenderSelection {
  /// Creates an empty, symbol, or backstitch selection.
  const PatternRenderSelection({
    this.selectedSymbolId,
    this.backstitchColorKey,
  }) : assert(selectedSymbolId == null || backstitchColorKey == null);

  /// Symbol highlighted across matching visible pattern cells.
  final String? selectedSymbolId;

  /// Normalized thread color shared by the selected backstitch lines.
  final String? backstitchColorKey;

  /// Returns whether a symbol or backstitch is currently selected.
  bool get hasSelection =>
      selectedSymbolId != null || backstitchColorKey != null;

  /// Whether the active selection represents backstitch linework.
  bool get hasBackstitchSelection => backstitchColorKey != null;

  /// Returns a new selection for [symbolId], or a cleared selection for null.
  PatternRenderSelection select(String? symbolId) =>
      PatternRenderSelection(selectedSymbolId: symbolId);

  /// Returns a selection for every backstitch line sharing [colorKey].
  PatternRenderSelection selectBackstitch(String colorKey) =>
      PatternRenderSelection(backstitchColorKey: colorKey);

  /// Compares selections by their ephemeral symbol or backstitch color identity.
  @override
  bool operator ==(Object other) =>
      other is PatternRenderSelection &&
      selectedSymbolId == other.selectedSymbolId &&
      backstitchColorKey == other.backstitchColorKey;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode =>
      Object.hash(selectedSymbolId, backstitchColorKey);
}

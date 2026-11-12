/// Ephemeral renderer selection used by the viewport and symbol palette.
class PatternRenderSelection {
  /// Creates an empty, symbol, or backstitch selection.
  const PatternRenderSelection({
    this.selectedSymbolId,
    this.selectedBackstitchId,
    this.backstitchColorKey,
  }) : assert(
         selectedSymbolId == null ||
             (selectedBackstitchId == null && backstitchColorKey == null),
       ),
       assert(
         selectedBackstitchId == null ||
             (selectedSymbolId == null && backstitchColorKey != null),
       ),
       assert(backstitchColorKey == null || selectedBackstitchId != null);

  /// Symbol highlighted across matching visible pattern cells.
  final String? selectedSymbolId;

  /// Stable identity of the selected backstitch segment.
  final String? selectedBackstitchId;

  /// Normalized thread color shared by the selected backstitch lines.
  final String? backstitchColorKey;

  /// Returns whether a symbol or backstitch is currently selected.
  bool get hasSelection =>
      selectedSymbolId != null || selectedBackstitchId != null;

  /// Whether the active selection represents backstitch linework.
  bool get hasBackstitchSelection => selectedBackstitchId != null;

  /// Returns a new selection for [symbolId], or a cleared selection for null.
  PatternRenderSelection select(String? symbolId) =>
      PatternRenderSelection(selectedSymbolId: symbolId);

  /// Returns a selection for one backstitch and every line sharing [colorKey].
  PatternRenderSelection selectBackstitch({
    required String segmentId,
    required String colorKey,
  }) => PatternRenderSelection(
    selectedBackstitchId: segmentId,
    backstitchColorKey: colorKey,
  );

  /// Compares selections by their ephemeral selected symbol ID.
  @override
  bool operator ==(Object other) =>
      other is PatternRenderSelection &&
      selectedSymbolId == other.selectedSymbolId &&
      selectedBackstitchId == other.selectedBackstitchId &&
      backstitchColorKey == other.backstitchColorKey;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode =>
      Object.hash(selectedSymbolId, selectedBackstitchId, backstitchColorKey);
}

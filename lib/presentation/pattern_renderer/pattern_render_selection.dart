/// Ephemeral renderer selection used by the viewport and symbol palette.
class PatternRenderSelection {
  /// Creates an empty, symbol, or backstitch selection.
  const PatternRenderSelection({
    this.threadId,
    this.selectedSymbolId,
    this.selectedBackstitchDefinitionId,
  }) : assert(
         (threadId == null &&
                 selectedSymbolId == null &&
                 selectedBackstitchDefinitionId == null) ||
             (threadId != null &&
                 ((selectedSymbolId != null) !=
                     (selectedBackstitchDefinitionId != null))),
       );

  /// Thread identity highlighted within the selected stitch family.
  final String? threadId;

  /// Symbol highlighted across matching visible pattern cells.
  final String? selectedSymbolId;

  /// Backstitch definition that originated the current selection.
  final String? selectedBackstitchDefinitionId;

  /// Returns whether a symbol or backstitch is currently selected.
  bool get hasSelection => threadId != null;

  /// Whether the active selection represents symbol-based cell stitches.
  bool get hasSymbolSelection => selectedSymbolId != null;

  /// Whether the active selection represents backstitch linework.
  bool get hasBackstitchSelection => selectedBackstitchDefinitionId != null;

  /// Returns a symbol-family selection grouped by [threadId].
  PatternRenderSelection selectSymbol(String symbolId, String threadId) =>
      PatternRenderSelection(threadId: threadId, selectedSymbolId: symbolId);

  /// Returns a cleared selection.
  PatternRenderSelection clear() => const PatternRenderSelection();

  /// Returns a thread selection originating from a backstitch definition.
  PatternRenderSelection selectBackstitch(
    String definitionId,
    String threadId,
  ) => PatternRenderSelection(
    threadId: threadId,
    selectedBackstitchDefinitionId: definitionId,
  );

  /// Compares selections by thread identity and exclusive stitch family.
  @override
  bool operator ==(Object other) =>
      other is PatternRenderSelection &&
      threadId == other.threadId &&
      selectedSymbolId == other.selectedSymbolId &&
      selectedBackstitchDefinitionId == other.selectedBackstitchDefinitionId;

  /// Hash code consistent with [operator ==].
  @override
  int get hashCode =>
      Object.hash(threadId, selectedSymbolId, selectedBackstitchDefinitionId);
}

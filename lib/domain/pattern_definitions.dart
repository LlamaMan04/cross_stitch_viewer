import 'domain_error.dart';

/// Indicates whether a thread color came directly from a source or was estimated.
enum ColorEvidence {
  /// The source explicitly provided this color.
  explicit,

  /// The color was inferred during parsing or conversion.
  inferred,
}

/// Stable symbol identity and display data used by cells and the pattern legend.
class SymbolDefinition {
  /// Creates a symbol definition from its source, normalized, and display forms.
  const SymbolDefinition({
    required this.id,
    required this.sourceSymbol,
    required this.normalizedKey,
    required this.displayGlyph,
    required this.thread,
    this.legendEvidence,
  });

  /// Stable ID referenced by stitches and other document data.
  final String id;

  /// Symbol text as found in the source pattern.
  final String sourceSymbol;

  /// Canonical lookup key used to match equivalent source spellings.
  final String normalizedKey;

  /// Glyph displayed in the pattern grid.
  final String displayGlyph;

  /// Exact thread definition rendered for stitches using this symbol.
  final ThreadDefinition thread;

  /// Original legend text or other evidence supporting the mapping.
  final String? legendEvidence;
}

/// Thread catalog entry and canonical color associated with a symbol.
class ThreadDefinition {
  /// Creates a thread entry; [color] must use canonical `#RRGGBB` notation.
  const ThreadDefinition({
    required this.id,
    required this.color,
    this.brand,
    this.catalogNumber,
    this.name,
    this.conversionNotes,
    this.evidence = ColorEvidence.explicit,
  });

  /// Stable ID supplied by the pattern source or thread catalog.
  final String id;

  /// Canonical RGB color in `#RRGGBB` notation.
  final String color;

  /// Optional manufacturer name.
  final String? brand;

  /// Optional manufacturer catalog number.
  final String? catalogNumber;

  /// Optional human-readable color name.
  final String? name;

  /// Optional notes about substitutions or conversions.
  final String? conversionNotes;

  /// Indicates whether the color was explicit in the source or inferred.
  final ColorEvidence evidence;

  /// Rejects colors that are not six-digit RGB hex values.
  void validate() {
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      throw const DocumentValidationException('Thread color must use #RRGGBB.');
    }
  }
}

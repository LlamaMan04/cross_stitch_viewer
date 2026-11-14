import '../domain/pattern_document.dart';
import 'pattern_document_json_export.dart';
import 'pattern_document_json_import.dart';

/// Backwards-compatible facade for portable pattern document JSON conversion.
class PatternDocumentJsonCodec {
  /// Current version of the JSON interchange format.
  static const int formatVersion = 1;

  /// Encodes [document] as a portable JSON string.
  static String encode(PatternDocument document) =>
      encodePatternDocumentJson(document);

  /// Decodes a portable JSON string into a validated [PatternDocument].
  static PatternDocument decode(String source) =>
      decodePatternDocumentJson(source);

  /// Converts [document] into JSON-compatible values.
  static Map<String, Object?> toJson(PatternDocument document) =>
      patternDocumentToJson(document);

  /// Decodes JSON-compatible [source] values into a validated document.
  static PatternDocument fromJson(Object? source) =>
      patternDocumentFromJson(source);
}

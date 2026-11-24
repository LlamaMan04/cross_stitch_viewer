import 'dart:convert';

import '../domain/pattern_backstitch.dart';
import '../domain/pattern_definitions.dart';
import '../domain/pattern_document.dart';
import '../domain/pattern_grid.dart';
import '../domain/pattern_provenance.dart';
import 'pattern_document_json_constants.dart';

/// Encodes [document] as a portable JSON string.
String encodePatternDocumentJson(PatternDocument document) =>
    jsonEncode(patternDocumentToJson(document));

/// Converts [document] into JSON-compatible values.
Map<String, Object?> patternDocumentToJson(PatternDocument document) {
  document.validate();
  return <String, Object?>{
    'formatVersion': patternDocumentJsonFormatVersion,
    'id': document.id,
    'title': document.title,
    'schemaVersion': document.schemaVersion,
    'grid': <String, Object?>{
      'rows': document.grid.dimensions.rows,
      'columns': document.grid.dimensions.columns,
      'cells': document.grid.cells.map(_cellToJson).toList(growable: false),
    },
    'threads': document.threads.map(_threadToJson).toList(growable: false),
    'symbols': document.symbols.map(_symbolToJson).toList(growable: false),
    'backstitchDefinitions': document.backstitchDefinitions
        .map(_backstitchDefinitionToJson)
        .toList(growable: false),
    'backstitches': document.backstitches
        .map(_backstitchToJson)
        .toList(growable: false),
    'regions': document.regions.map(_regionToJson).toList(growable: false),
    'sourceMetadata': _jsonValue(document.sourceMetadata, 'sourceMetadata'),
    'sourceChecksum': document.sourceChecksum,
    'diagnostics': document.diagnostics
        .map(_diagnosticToJson)
        .toList(growable: false),
  };
}

Map<String, Object?> _cellToJson(StitchCell cell) => <String, Object?>{
  'row': cell.coordinate.row,
  'column': cell.coordinate.column,
  'symbolId': cell.symbolId,
  'confidence': cell.confidence?.value,
  'needsReview': cell.needsReview,
  'provenanceId': cell.provenanceId,
};

Map<String, Object?> _threadToJson(ThreadDefinition thread) =>
    <String, Object?>{
      'id': thread.id,
      'color': thread.color,
      'brand': thread.brand,
      'catalogNumber': thread.catalogNumber,
      'name': thread.name,
      'conversionNotes': thread.conversionNotes,
      'evidence': thread.evidence.name,
    };

Map<String, Object?> _symbolToJson(SymbolDefinition symbol) =>
    <String, Object?>{
      'id': symbol.id,
      'sourceSymbol': symbol.sourceSymbol,
      'normalizedKey': symbol.normalizedKey,
      'displayGlyph': symbol.displayGlyph,
      'threadId': symbol.threadId,
      'stitchType': symbol.stitchType.name,
      'threadCount': symbol.threadCount,
      'legendEvidence': symbol.legendEvidence,
    };

Map<String, Object?> _backstitchDefinitionToJson(BackstitchDefinition value) =>
    <String, Object?>{
      'id': value.id,
      'threadId': value.threadId,
      'threadCount': value.threadCount,
    };

Map<String, Object?> _backstitchToJson(BackstitchSegment value) =>
    <String, Object?>{
      'id': value.id,
      'start': _backstitchCoordinateToJson(value.start),
      'end': _backstitchCoordinateToJson(value.end),
      'definitionId': value.definitionId,
      'confidence': value.confidence?.value,
      'needsReview': value.needsReview,
      'provenanceId': value.provenanceId,
    };

Map<String, Object?> _backstitchCoordinateToJson(BackstitchCoordinate value) =>
    <String, Object?>{'row': value.row, 'column': value.column};

Map<String, Object?> _regionToJson(PatternRegion value) => <String, Object?>{
  'id': value.id,
  'sourcePage': value.sourcePage,
  'row': value.origin.row,
  'column': value.origin.column,
  'rows': value.rows,
  'columns': value.columns,
  'label': value.label,
};

Map<String, Object?> _diagnosticToJson(ParserDiagnostic value) =>
    <String, Object?>{
      'severity': value.severity.name,
      'stage': value.stage.name,
      'message': value.message,
      'coordinate': value.coordinate == null
          ? null
          : <String, Object?>{
              'row': value.coordinate!.row,
              'column': value.coordinate!.column,
            },
      'sourcePage': value.sourcePage,
      'regionId': value.regionId,
      'confidence': value.confidence?.value,
      'suggestedCorrection': value.suggestedCorrection,
    };

Object? _jsonValue(Object? value, String path) {
  if (value == null || value is String || value is bool) return value;
  if (value is num) {
    if (!value.isFinite) {
      throw FormatException('Number must be finite.', path);
    }
    return value;
  }
  if (value is List) {
    return value
        .asMap()
        .entries
        .map((entry) => _jsonValue(entry.value, '$path[${entry.key}]'))
        .toList(growable: false);
  }
  if (value is Map) {
    final result = <String, Object?>{};
    for (final entry in value.entries) {
      if (entry.key is! String) {
        throw FormatException('JSON object keys must be strings.', path);
      }
      result[entry.key as String] = _jsonValue(
        entry.value,
        '$path.${entry.key}',
      );
    }
    return result;
  }
  throw FormatException('Value is not JSON-compatible.', path);
}

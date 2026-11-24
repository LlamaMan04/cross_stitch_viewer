import 'dart:convert';

import '../domain/domain_error.dart';
import '../domain/pattern_backstitch.dart';
import '../domain/pattern_definitions.dart';
import '../domain/pattern_document.dart';
import '../domain/pattern_grid.dart';
import '../domain/pattern_provenance.dart';
import '../domain/value_objects.dart';
import 'pattern_document_json_constants.dart';

/// Decodes a portable JSON string into a validated [PatternDocument].
PatternDocument decodePatternDocumentJson(String source) {
  try {
    return patternDocumentFromJson(jsonDecode(source));
  } on FormatException {
    rethrow;
  } on DomainException {
    rethrow;
  } catch (error) {
    throw FormatException('Invalid pattern document JSON: $error');
  }
}

/// Decodes JSON-compatible [source] values into a validated document.
PatternDocument patternDocumentFromJson(Object? source) {
  final root = _object(source, r'$');
  final version = _integer(root, 'formatVersion', r'$');
  if (version != patternDocumentJsonFormatVersion) {
    throw FormatException(
      'Unsupported format version $version.',
      r'$.formatVersion',
    );
  }
  final grid = _object(_required(root, 'grid', r'$'), r'$.grid');
  final document = PatternDocument(
    id: _string(root, 'id', r'$'),
    title: _string(root, 'title', r'$'),
    schemaVersion: _integer(root, 'schemaVersion', r'$'),
    grid: PatternGrid(
      dimensions: PatternDimensions(
        _integer(grid, 'rows', r'$.grid'),
        _integer(grid, 'columns', r'$.grid'),
      ),
      cells: _array(grid, 'cells', r'$.grid').asMap().entries.map(
        (entry) => _cellFromJson(entry.value, r'$.grid.cells[${entry.key}]'),
      ),
    ),
    threads: _decodeList(root, 'threads', r'$', _threadFromJson),
    symbols: _decodeList(root, 'symbols', r'$', _symbolFromJson),
    backstitchDefinitions: _decodeList(
      root,
      'backstitchDefinitions',
      r'$',
      _backstitchDefinitionFromJson,
    ),
    backstitches: _decodeList(root, 'backstitches', r'$', _backstitchFromJson),
    regions: _decodeList(root, 'regions', r'$', _regionFromJson),
    sourceMetadata: _metadata(root),
    sourceChecksum: _nullableString(root, 'sourceChecksum', r'$'),
    diagnostics: _decodeList(root, 'diagnostics', r'$', _diagnosticFromJson),
  );
  try {
    document.validate();
  } on DomainException catch (error) {
    throw FormatException(error.message, error.path ?? r'$');
  }
  return document;
}

StitchCell _cellFromJson(Object? value, String path) {
  final object = _object(value, path);
  return StitchCell(
    coordinate: _coordinate(object, path),
    symbolId: _string(object, 'symbolId', path),
    confidence: _confidence(object, path),
    needsReview: _booleanOrDefault(object, 'needsReview', path, false),
    provenanceId: _nullableString(object, 'provenanceId', path),
  );
}

ThreadDefinition _threadFromJson(Object? value, String path) {
  final object = _object(value, path);
  return ThreadDefinition(
    id: _string(object, 'id', path),
    color: _string(object, 'color', path),
    brand: _nullableString(object, 'brand', path),
    catalogNumber: _nullableString(object, 'catalogNumber', path),
    name: _nullableString(object, 'name', path),
    conversionNotes: _nullableString(object, 'conversionNotes', path),
    evidence: _enumValue(ColorEvidence.values, object, 'evidence', path),
  );
}

SymbolDefinition _symbolFromJson(Object? value, String path) {
  final object = _object(value, path);
  return SymbolDefinition(
    id: _string(object, 'id', path),
    sourceSymbol: _string(object, 'sourceSymbol', path),
    normalizedKey: _string(object, 'normalizedKey', path),
    displayGlyph: _string(object, 'displayGlyph', path),
    threadId: _string(object, 'threadId', path),
    stitchType: _enumValue(StitchType.values, object, 'stitchType', path),
    threadCount: _nullableInteger(object, 'threadCount', path),
    legendEvidence: _nullableString(object, 'legendEvidence', path),
  );
}

BackstitchDefinition _backstitchDefinitionFromJson(Object? value, String path) {
  final object = _object(value, path);
  return BackstitchDefinition(
    id: _string(object, 'id', path),
    threadId: _string(object, 'threadId', path),
    threadCount: _nullableInteger(object, 'threadCount', path),
  );
}

BackstitchSegment _backstitchFromJson(Object? value, String path) {
  final object = _object(value, path);
  return BackstitchSegment(
    id: _string(object, 'id', path),
    start: _backstitchCoordinateFromJson(
      _required(object, 'start', path),
      '$path.start',
    ),
    end: _backstitchCoordinateFromJson(
      _required(object, 'end', path),
      '$path.end',
    ),
    definitionId: _string(object, 'definitionId', path),
    confidence: _confidence(object, path),
    needsReview: _booleanOrDefault(object, 'needsReview', path, false),
    provenanceId: _nullableString(object, 'provenanceId', path),
  );
}

BackstitchCoordinate _backstitchCoordinateFromJson(Object? value, String path) {
  final object = _object(value, path);
  return BackstitchCoordinate(
    row: _number(object, 'row', path),
    column: _number(object, 'column', path),
  );
}

PatternRegion _regionFromJson(Object? value, String path) {
  final object = _object(value, path);
  return PatternRegion(
    id: _string(object, 'id', path),
    sourcePage: _integer(object, 'sourcePage', path),
    origin: _coordinate(object, path),
    rows: _integer(object, 'rows', path),
    columns: _integer(object, 'columns', path),
    label: _nullableString(object, 'label', path),
  );
}

ParserDiagnostic _diagnosticFromJson(Object? value, String path) {
  final object = _object(value, path);
  final coordinateValue = object['coordinate'];
  return ParserDiagnostic(
    severity: _enumValue(DiagnosticSeverity.values, object, 'severity', path),
    stage: _enumValue(DiagnosticStage.values, object, 'stage', path),
    message: _string(object, 'message', path),
    coordinate: coordinateValue == null
        ? null
        : _coordinate(
            _object(coordinateValue, '$path.coordinate'),
            '$path.coordinate',
          ),
    sourcePage: _nullableInteger(object, 'sourcePage', path),
    regionId: _nullableString(object, 'regionId', path),
    confidence: _confidence(object, path),
    suggestedCorrection: _nullableString(object, 'suggestedCorrection', path),
  );
}

Map<String, Object?> _metadata(Map<String, Object?> root) {
  if (!root.containsKey('sourceMetadata')) return const <String, Object?>{};
  final value = root['sourceMetadata'];
  if (value == null) return const <String, Object?>{};
  final metadata = _object(value, r'$.sourceMetadata');
  return <String, Object?>{
    for (final entry in metadata.entries)
      entry.key: _jsonValue(entry.value, r'$.sourceMetadata.${entry.key}'),
  };
}

/// Validates and copies a recursively nested JSON-compatible metadata value.
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
        throw FormatException('Object keys must be strings.', path);
      }
      result[entry.key as String] = _jsonValue(
        entry.value,
        '$path.${entry.key}',
      );
    }
    return result;
  }
  throw FormatException('Unsupported value.', path);
}

List<T> _decodeList<T>(
  Map<String, Object?> object,
  String key,
  String path,
  T Function(Object?, String) decode,
) {
  if (!object.containsKey(key)) {
    return <T>[];
  }
  final values = _array(object, key, path);
  return values
      .asMap()
      .entries
      .map((entry) => decode(entry.value, '$path.$key[${entry.key}]'))
      .toList(growable: false);
}

Map<String, Object?> _object(Object? value, String path) {
  if (value is! Map) {
    throw FormatException('Expected an object.', path);
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw FormatException('Object keys must be strings.', path);
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<Object?> _array(Map<String, Object?> object, String key, String path) {
  final value = _required(object, key, path);
  if (value is! List) {
    throw FormatException('Expected an array.', '$path.$key');
  }
  return List<Object?>.from(value);
}

Object? _required(Map<String, Object?> object, String key, String path) {
  if (!object.containsKey(key) || object[key] == null) {
    throw FormatException('Missing required value.', '$path.$key');
  }
  return object[key];
}

String _string(Map<String, Object?> object, String key, String path) {
  final value = _required(object, key, path);
  if (value is! String) {
    throw FormatException('Expected a string.', '$path.$key');
  }
  return value;
}

String? _nullableString(Map<String, Object?> object, String key, String path) {
  if (!object.containsKey(key) || object[key] == null) {
    return null;
  }
  if (object[key] is! String) {
    throw FormatException('Expected a string or null.', '$path.$key');
  }
  return object[key] as String;
}

int _integer(Map<String, Object?> object, String key, String path) {
  final value = _required(object, key, path);
  if (value is! int) {
    throw FormatException('Expected an integer.', '$path.$key');
  }
  return value;
}

int? _nullableInteger(Map<String, Object?> object, String key, String path) {
  if (!object.containsKey(key) || object[key] == null) {
    return null;
  }
  if (object[key] is! int) {
    throw FormatException('Expected an integer or null.', '$path.$key');
  }
  return object[key] as int;
}

double _number(Map<String, Object?> object, String key, String path) {
  final value = _required(object, key, path);
  if (value is! num || !value.isFinite) {
    throw FormatException('Expected a finite number.', '$path.$key');
  }
  return value.toDouble();
}

bool _booleanOrDefault(
  Map<String, Object?> object,
  String key,
  String path,
  bool fallback,
) {
  if (!object.containsKey(key)) {
    return fallback;
  }
  final value = object[key];
  if (value is! bool) {
    throw FormatException('Expected a boolean.', '$path.$key');
  }
  return value;
}

Confidence? _confidence(Map<String, Object?> object, String path) {
  if (!object.containsKey('confidence') || object['confidence'] == null) {
    return null;
  }
  return Confidence(_number(object, 'confidence', path));
}

GridCoordinate _coordinate(Map<String, Object?> object, String path) =>
    GridCoordinate(
      _integer(object, 'row', path),
      _integer(object, 'column', path),
    );

T _enumValue<T extends Enum>(
  List<T> values,
  Map<String, Object?> object,
  String key,
  String path,
) {
  final value = _string(object, key, path);
  for (final candidate in values) {
    if (candidate.name == value) return candidate;
  }
  throw FormatException('Unsupported value "$value".', '$path.$key');
}

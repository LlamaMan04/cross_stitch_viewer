import 'domain_error.dart';
import 'pattern_backstitch.dart';
import 'pattern_definitions.dart';
import 'pattern_grid.dart';
import 'pattern_provenance.dart';

/// Normalized pattern data shared by the parser, database, and viewer.
class PatternDocument {
  /// Creates an immutable document and copies its collections.
  PatternDocument({
    required this.id,
    required this.title,
    required this.schemaVersion,
    required this.grid,
    required Iterable<ThreadDefinition> threads,
    required Iterable<SymbolDefinition> symbols,
    Iterable<BackstitchDefinition> backstitchDefinitions = const [],
    Iterable<BackstitchSegment> backstitches = const [],
    Iterable<PatternRegion> regions = const [],
    Map<String, Object?> sourceMetadata = const {},
    this.sourceChecksum,
    Iterable<ParserDiagnostic> diagnostics = const [],
  }) {
    this.threads = List.unmodifiable(threads);
    this.symbols = List.unmodifiable(symbols);
    this.backstitchDefinitions = List.unmodifiable(backstitchDefinitions);
    this.backstitches = List.unmodifiable(backstitches);
    this.regions = List.unmodifiable(regions);
    this.sourceMetadata = Map.unmodifiable(sourceMetadata);
    this.diagnostics = List.unmodifiable(diagnostics);
    _threadsById = Map.unmodifiable({
      for (final thread in this.threads) thread.id: thread,
    });
    _symbolsById = Map.unmodifiable({
      for (final symbol in this.symbols) symbol.id: symbol,
    });
    _backstitchDefinitionsById = Map.unmodifiable({
      for (final definition in this.backstitchDefinitions)
        definition.id: definition,
    });
    _backstitchesById = Map.unmodifiable({
      for (final backstitch in this.backstitches) backstitch.id: backstitch,
    });
    _regionsById = Map.unmodifiable({
      for (final region in this.regions) region.id: region,
    });
    // Build a spatial index once so painting regions never scans the document.
    final mutableRegionTiles = <(int, int), List<PatternRegion>>{};
    for (final region in this.regions) {
      final firstTileRow = region.origin.row ~/ PatternGrid.tileSize;
      final lastTileRow =
          (region.origin.row + region.rows - 1) ~/ PatternGrid.tileSize;
      final firstTileColumn = region.origin.column ~/ PatternGrid.tileSize;
      final lastTileColumn =
          (region.origin.column + region.columns - 1) ~/ PatternGrid.tileSize;
      for (var tileRow = firstTileRow; tileRow <= lastTileRow; tileRow++) {
        for (
          var tileColumn = firstTileColumn;
          tileColumn <= lastTileColumn;
          tileColumn++
        ) {
          mutableRegionTiles
              .putIfAbsent((tileRow, tileColumn), () => <PatternRegion>[])
              .add(region);
        }
      }
    }
    _regionsByTile = Map.unmodifiable({
      for (final entry in mutableRegionTiles.entries)
        entry.key: List<PatternRegion>.unmodifiable(entry.value),
    });
  }

  /// Stable document ID used by repositories and progress records.
  final String id;

  /// User-facing pattern title.
  final String title;

  /// Version of the normalized document contract.
  final int schemaVersion;

  /// Sparse stitch grid and its complete rectangular dimensions.
  final PatternGrid grid;

  /// Thread catalog entries referenced by stitch definitions.
  late final List<ThreadDefinition> threads;

  /// Direct thread lookup by stable ID.
  late final Map<String, ThreadDefinition> _threadsById;

  /// Symbol definitions referenced by populated cells.
  late final List<SymbolDefinition> symbols;

  /// Direct symbol lookup by stable ID.
  late final Map<String, SymbolDefinition> _symbolsById;

  /// Backstitch definitions referenced by linear segments.
  late final List<BackstitchDefinition> backstitchDefinitions;

  /// Direct backstitch-definition lookup by stable ID.
  late final Map<String, BackstitchDefinition> _backstitchDefinitionsById;

  /// Linear stitches rendered independently from sparse grid cells.
  late final List<BackstitchSegment> backstitches;

  /// Direct backstitch lookup by stable segment ID.
  late final Map<String, BackstitchSegment> _backstitchesById;

  /// Source page or panel mappings into global grid coordinates.
  late final List<PatternRegion> regions;

  /// Direct provenance-region lookup by stable ID.
  late final Map<String, PatternRegion> _regionsById;

  /// Immutable source regions grouped by every spatial tile they intersect.
  late final Map<(int, int), List<PatternRegion>> _regionsByTile;

  /// Source details such as the original filename.
  late final Map<String, Object?> sourceMetadata;

  /// Optional checksum identifying the immutable original source.
  final String? sourceChecksum;

  /// Parser findings retained for review and provenance.
  late final List<ParserDiagnostic> diagnostics;

  /// Returns the symbol with [id], if the document defines one.
  SymbolDefinition? symbolById(String id) => _symbolsById[id];

  /// Returns the thread with [id], if the document defines one.
  ThreadDefinition? threadById(String id) => _threadsById[id];

  /// Returns the thread referenced by [symbol].
  ThreadDefinition? threadForSymbol(SymbolDefinition symbol) =>
      _threadsById[symbol.threadId];

  /// Returns the backstitch definition with [id], if present.
  BackstitchDefinition? backstitchDefinitionById(String id) =>
      _backstitchDefinitionsById[id];

  /// Returns the definition referenced by [segment].
  BackstitchDefinition? definitionForBackstitch(BackstitchSegment segment) =>
      _backstitchDefinitionsById[segment.definitionId];

  /// Returns the thread referenced by [definition].
  ThreadDefinition? threadForBackstitch(BackstitchDefinition definition) =>
      _threadsById[definition.threadId];

  /// Returns the backstitch segment with [id], if the document defines one.
  BackstitchSegment? backstitchById(String id) => _backstitchesById[id];

  /// Returns the provenance region with [id], if the document defines one.
  PatternRegion? regionById(String id) => _regionsById[id];

  /// Yields source regions intersecting [bounds] without scanning all regions.
  Iterable<PatternRegion> regionsIntersecting(GridBounds bounds) sync* {
    final query = bounds.clampTo(grid.dimensions);
    if (query.isEmpty) return;
    final firstTileRow = query.startRow ~/ PatternGrid.tileSize;
    final lastTileRow = (query.endRow - 1) ~/ PatternGrid.tileSize;
    final firstTileColumn = query.startColumn ~/ PatternGrid.tileSize;
    final lastTileColumn = (query.endColumn - 1) ~/ PatternGrid.tileSize;
    final yieldedIds = <String>{};
    for (var tileRow = firstTileRow; tileRow <= lastTileRow; tileRow++) {
      for (
        var tileColumn = firstTileColumn;
        tileColumn <= lastTileColumn;
        tileColumn++
      ) {
        final tileRegions = _regionsByTile[(tileRow, tileColumn)];
        if (tileRegions == null) continue;
        for (final region in tileRegions) {
          final regionEndRow = region.origin.row + region.rows;
          final regionEndColumn = region.origin.column + region.columns;
          final intersects =
              region.origin.row < query.endRow &&
              regionEndRow > query.startRow &&
              region.origin.column < query.endColumn &&
              regionEndColumn > query.startColumn;
          if (intersects && yieldedIds.add(region.id)) yield region;
        }
      }
    }
  }

  /// Validates dimensions, IDs, references, color formats, and provenance.
  void validate() {
    if (id.isEmpty || title.isEmpty) {
      throw const DocumentValidationException(
        'Document ID and title are required.',
      );
    }
    if (schemaVersion <= 0) {
      throw const DocumentValidationException(
        'Schema version must be positive.',
      );
    }
    grid.validate();
    if (_threadsById.length != threads.length ||
        _symbolsById.length != symbols.length ||
        _backstitchDefinitionsById.length != backstitchDefinitions.length ||
        _backstitchesById.length != backstitches.length ||
        _regionsById.length != regions.length) {
      throw const DocumentValidationException(
        'Thread, definition, backstitch, and region IDs must be unique.',
      );
    }
    for (final region in regions) {
      if (region.sourcePage < 0 ||
          region.origin.row < 0 ||
          region.origin.column < 0 ||
          region.rows <= 0 ||
          region.columns <= 0 ||
          region.origin.row + region.rows > grid.dimensions.rows ||
          region.origin.column + region.columns > grid.dimensions.columns) {
        throw DocumentValidationException(
          'Region ${region.id} is outside the global grid.',
        );
      }
    }
    for (final thread in threads) {
      if (thread.id.isEmpty) {
        throw const DocumentValidationException('Thread ID is required.');
      }
      thread.validate();
    }
    for (final symbol in symbols) {
      symbol.validate();
      if (!_threadsById.containsKey(symbol.threadId)) {
        throw DocumentValidationException(
          'Symbol ${symbol.id} references missing thread ${symbol.threadId}.',
        );
      }
    }
    for (final definition in backstitchDefinitions) {
      definition.validate();
      if (!_threadsById.containsKey(definition.threadId)) {
        throw DocumentValidationException(
          'Backstitch definition ${definition.id} references missing thread '
          '${definition.threadId}.',
        );
      }
    }
    for (final cell in grid.cells) {
      if (!_symbolsById.containsKey(cell.symbolId)) {
        throw DocumentValidationException(
          'Cell ${cell.coordinate} references missing symbol ${cell.symbolId}.',
        );
      }
      final provenanceId = cell.provenanceId;
      if (provenanceId != null && !_regionsById.containsKey(provenanceId)) {
        throw DocumentValidationException(
          'Cell ${cell.coordinate} references missing region $provenanceId.',
        );
      }
      if (provenanceId != null) {
        final region = _regionsById[provenanceId]!;
        if (cell.coordinate.row < region.origin.row ||
            cell.coordinate.column < region.origin.column ||
            cell.coordinate.row >= region.origin.row + region.rows ||
            cell.coordinate.column >= region.origin.column + region.columns) {
          throw DocumentValidationException(
            'Cell ${cell.coordinate} is outside provenance region ${region.id}.',
          );
        }
      }
    }
    for (final backstitch in backstitches) {
      backstitch.validate();
      if (!_backstitchDefinitionsById.containsKey(backstitch.definitionId)) {
        throw DocumentValidationException(
          'Backstitch ${backstitch.id} references missing definition '
          '${backstitch.definitionId}.',
        );
      }
      _validateBackstitchCoordinate(backstitch.start, backstitch.id);
      _validateBackstitchCoordinate(backstitch.end, backstitch.id);
      final provenanceId = backstitch.provenanceId;
      if (provenanceId != null && !_regionsById.containsKey(provenanceId)) {
        throw DocumentValidationException(
          'Backstitch ${backstitch.id} references missing region '
          '$provenanceId.',
        );
      }
    }
  }

  /// Validates an endpoint against the document's inclusive grid-corner bounds.
  void _validateBackstitchCoordinate(
    BackstitchCoordinate coordinate,
    String segmentId,
  ) {
    if (coordinate.row < 0 ||
        coordinate.row > grid.dimensions.rows ||
        coordinate.column < 0 ||
        coordinate.column > grid.dimensions.columns) {
      throw DocumentValidationException(
        'Backstitch $segmentId has an endpoint outside the grid.',
      );
    }
  }
}

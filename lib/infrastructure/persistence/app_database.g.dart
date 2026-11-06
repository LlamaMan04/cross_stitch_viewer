// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $PersistenceMetadataTable extends PersistenceMetadata
    with TableInfo<$PersistenceMetadataTable, PersistenceMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PersistenceMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'persistence_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<PersistenceMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  PersistenceMetadataData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PersistenceMetadataData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $PersistenceMetadataTable createAlias(String alias) {
    return $PersistenceMetadataTable(attachedDatabase, alias);
  }
}

class PersistenceMetadataData extends DataClass
    implements Insertable<PersistenceMetadataData> {
  /// Defines the unique metadata name.
  final String key;

  /// Defines the serialized value associated with [key].
  final String value;
  const PersistenceMetadataData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  PersistenceMetadataCompanion toCompanion(bool nullToAbsent) {
    return PersistenceMetadataCompanion(key: Value(key), value: Value(value));
  }

  factory PersistenceMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PersistenceMetadataData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  PersistenceMetadataData copyWith({String? key, String? value}) =>
      PersistenceMetadataData(key: key ?? this.key, value: value ?? this.value);
  PersistenceMetadataData copyWithCompanion(PersistenceMetadataCompanion data) {
    return PersistenceMetadataData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PersistenceMetadataData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PersistenceMetadataData &&
          other.key == this.key &&
          other.value == this.value);
}

class PersistenceMetadataCompanion
    extends UpdateCompanion<PersistenceMetadataData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const PersistenceMetadataCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PersistenceMetadataCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<PersistenceMetadataData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PersistenceMetadataCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return PersistenceMetadataCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PersistenceMetadataCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatternDocumentsTable extends PatternDocuments
    with TableInfo<$PatternDocumentsTable, PatternDocumentRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatternDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowCountMeta = const VerificationMeta(
    'rowCount',
  );
  @override
  late final GeneratedColumn<int> rowCount = GeneratedColumn<int>(
    'row_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _columnCountMeta = const VerificationMeta(
    'columnCount',
  );
  @override
  late final GeneratedColumn<int> columnCount = GeneratedColumn<int>(
    'column_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceChecksumMeta = const VerificationMeta(
    'sourceChecksum',
  );
  @override
  late final GeneratedColumn<String> sourceChecksum = GeneratedColumn<String>(
    'source_checksum',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    schemaVersion,
    rowCount,
    columnCount,
    sourceChecksum,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pattern_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<PatternDocumentRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('row_count')) {
      context.handle(
        _rowCountMeta,
        rowCount.isAcceptableOrUnknown(data['row_count']!, _rowCountMeta),
      );
    } else if (isInserting) {
      context.missing(_rowCountMeta);
    }
    if (data.containsKey('column_count')) {
      context.handle(
        _columnCountMeta,
        columnCount.isAcceptableOrUnknown(
          data['column_count']!,
          _columnCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_columnCountMeta);
    }
    if (data.containsKey('source_checksum')) {
      context.handle(
        _sourceChecksumMeta,
        sourceChecksum.isAcceptableOrUnknown(
          data['source_checksum']!,
          _sourceChecksumMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PatternDocumentRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatternDocumentRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      rowCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_count'],
      )!,
      columnCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}column_count'],
      )!,
      sourceChecksum: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_checksum'],
      ),
    );
  }

  @override
  $PatternDocumentsTable createAlias(String alias) {
    return $PatternDocumentsTable(attachedDatabase, alias);
  }
}

class PatternDocumentRow extends DataClass
    implements Insertable<PatternDocumentRow> {
  /// Defines the stable document identifier.
  final String id;

  /// Defines the user-facing document title.
  final String title;

  /// Defines the portable pattern JSON schema version.
  final int schemaVersion;

  /// Defines the total number of rows in the global pattern grid.
  final int rowCount;

  /// Defines the total number of columns in the global pattern grid.
  final int columnCount;

  /// Defines the optional checksum of the immutable imported source.
  final String? sourceChecksum;
  const PatternDocumentRow({
    required this.id,
    required this.title,
    required this.schemaVersion,
    required this.rowCount,
    required this.columnCount,
    this.sourceChecksum,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['row_count'] = Variable<int>(rowCount);
    map['column_count'] = Variable<int>(columnCount);
    if (!nullToAbsent || sourceChecksum != null) {
      map['source_checksum'] = Variable<String>(sourceChecksum);
    }
    return map;
  }

  PatternDocumentsCompanion toCompanion(bool nullToAbsent) {
    return PatternDocumentsCompanion(
      id: Value(id),
      title: Value(title),
      schemaVersion: Value(schemaVersion),
      rowCount: Value(rowCount),
      columnCount: Value(columnCount),
      sourceChecksum: sourceChecksum == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceChecksum),
    );
  }

  factory PatternDocumentRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatternDocumentRow(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      rowCount: serializer.fromJson<int>(json['rowCount']),
      columnCount: serializer.fromJson<int>(json['columnCount']),
      sourceChecksum: serializer.fromJson<String?>(json['sourceChecksum']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'rowCount': serializer.toJson<int>(rowCount),
      'columnCount': serializer.toJson<int>(columnCount),
      'sourceChecksum': serializer.toJson<String?>(sourceChecksum),
    };
  }

  PatternDocumentRow copyWith({
    String? id,
    String? title,
    int? schemaVersion,
    int? rowCount,
    int? columnCount,
    Value<String?> sourceChecksum = const Value.absent(),
  }) => PatternDocumentRow(
    id: id ?? this.id,
    title: title ?? this.title,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    rowCount: rowCount ?? this.rowCount,
    columnCount: columnCount ?? this.columnCount,
    sourceChecksum: sourceChecksum.present
        ? sourceChecksum.value
        : this.sourceChecksum,
  );
  PatternDocumentRow copyWithCompanion(PatternDocumentsCompanion data) {
    return PatternDocumentRow(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      rowCount: data.rowCount.present ? data.rowCount.value : this.rowCount,
      columnCount: data.columnCount.present
          ? data.columnCount.value
          : this.columnCount,
      sourceChecksum: data.sourceChecksum.present
          ? data.sourceChecksum.value
          : this.sourceChecksum,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatternDocumentRow(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowCount: $rowCount, ')
          ..write('columnCount: $columnCount, ')
          ..write('sourceChecksum: $sourceChecksum')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    schemaVersion,
    rowCount,
    columnCount,
    sourceChecksum,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatternDocumentRow &&
          other.id == this.id &&
          other.title == this.title &&
          other.schemaVersion == this.schemaVersion &&
          other.rowCount == this.rowCount &&
          other.columnCount == this.columnCount &&
          other.sourceChecksum == this.sourceChecksum);
}

class PatternDocumentsCompanion extends UpdateCompanion<PatternDocumentRow> {
  final Value<String> id;
  final Value<String> title;
  final Value<int> schemaVersion;
  final Value<int> rowCount;
  final Value<int> columnCount;
  final Value<String?> sourceChecksum;
  final Value<int> rowid;
  const PatternDocumentsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.rowCount = const Value.absent(),
    this.columnCount = const Value.absent(),
    this.sourceChecksum = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatternDocumentsCompanion.insert({
    required String id,
    required String title,
    required int schemaVersion,
    required int rowCount,
    required int columnCount,
    this.sourceChecksum = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       schemaVersion = Value(schemaVersion),
       rowCount = Value(rowCount),
       columnCount = Value(columnCount);
  static Insertable<PatternDocumentRow> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<int>? schemaVersion,
    Expression<int>? rowCount,
    Expression<int>? columnCount,
    Expression<String>? sourceChecksum,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (rowCount != null) 'row_count': rowCount,
      if (columnCount != null) 'column_count': columnCount,
      if (sourceChecksum != null) 'source_checksum': sourceChecksum,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatternDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<int>? schemaVersion,
    Value<int>? rowCount,
    Value<int>? columnCount,
    Value<String?>? sourceChecksum,
    Value<int>? rowid,
  }) {
    return PatternDocumentsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      rowCount: rowCount ?? this.rowCount,
      columnCount: columnCount ?? this.columnCount,
      sourceChecksum: sourceChecksum ?? this.sourceChecksum,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (rowCount.present) {
      map['row_count'] = Variable<int>(rowCount.value);
    }
    if (columnCount.present) {
      map['column_count'] = Variable<int>(columnCount.value);
    }
    if (sourceChecksum.present) {
      map['source_checksum'] = Variable<String>(sourceChecksum.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatternDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('rowCount: $rowCount, ')
          ..write('columnCount: $columnCount, ')
          ..write('sourceChecksum: $sourceChecksum, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SourceMetadataEntriesTable extends SourceMetadataEntries
    with TableInfo<$SourceMetadataEntriesTable, SourceMetadataEntryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SourceMetadataEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pattern_documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [documentId, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_metadata_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceMetadataEntryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, key};
  @override
  SourceMetadataEntryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceMetadataEntryRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SourceMetadataEntriesTable createAlias(String alias) {
    return $SourceMetadataEntriesTable(attachedDatabase, alias);
  }
}

class SourceMetadataEntryRow extends DataClass
    implements Insertable<SourceMetadataEntryRow> {
  /// Defines the parent pattern document.
  final String documentId;

  /// Defines the metadata field name.
  final String key;

  /// Defines the JSON-encoded metadata value, including strings and null.
  final String value;
  const SourceMetadataEntryRow({
    required this.documentId,
    required this.key,
    required this.value,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SourceMetadataEntriesCompanion toCompanion(bool nullToAbsent) {
    return SourceMetadataEntriesCompanion(
      documentId: Value(documentId),
      key: Value(key),
      value: Value(value),
    );
  }

  factory SourceMetadataEntryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceMetadataEntryRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SourceMetadataEntryRow copyWith({
    String? documentId,
    String? key,
    String? value,
  }) => SourceMetadataEntryRow(
    documentId: documentId ?? this.documentId,
    key: key ?? this.key,
    value: value ?? this.value,
  );
  SourceMetadataEntryRow copyWithCompanion(
    SourceMetadataEntriesCompanion data,
  ) {
    return SourceMetadataEntryRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceMetadataEntryRow(')
          ..write('documentId: $documentId, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentId, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceMetadataEntryRow &&
          other.documentId == this.documentId &&
          other.key == this.key &&
          other.value == this.value);
}

class SourceMetadataEntriesCompanion
    extends UpdateCompanion<SourceMetadataEntryRow> {
  final Value<String> documentId;
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SourceMetadataEntriesCompanion({
    this.documentId = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourceMetadataEntriesCompanion.insert({
    required String documentId,
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       key = Value(key),
       value = Value(value);
  static Insertable<SourceMetadataEntryRow> custom({
    Expression<String>? documentId,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourceMetadataEntriesCompanion copyWith({
    Value<String>? documentId,
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SourceMetadataEntriesCompanion(
      documentId: documentId ?? this.documentId,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceMetadataEntriesCompanion(')
          ..write('documentId: $documentId, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LibraryMetadataTable extends LibraryMetadata
    with TableInfo<$LibraryMetadataTable, LibraryMetadataRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pattern_documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastOpenedAtMeta = const VerificationMeta(
    'lastOpenedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastOpenedAt = GeneratedColumn<DateTime>(
    'last_opened_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastModifiedAtMeta = const VerificationMeta(
    'lastModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastModifiedAt =
      GeneratedColumn<DateTime>(
        'last_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _userTitleMeta = const VerificationMeta(
    'userTitle',
  );
  @override
  late final GeneratedColumn<String> userTitle = GeneratedColumn<String>(
    'user_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    createdAt,
    importedAt,
    lastOpenedAt,
    lastModifiedAt,
    userTitle,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryMetadataRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('last_opened_at')) {
      context.handle(
        _lastOpenedAtMeta,
        lastOpenedAt.isAcceptableOrUnknown(
          data['last_opened_at']!,
          _lastOpenedAtMeta,
        ),
      );
    }
    if (data.containsKey('last_modified_at')) {
      context.handle(
        _lastModifiedAtMeta,
        lastModifiedAt.isAcceptableOrUnknown(
          data['last_modified_at']!,
          _lastModifiedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastModifiedAtMeta);
    }
    if (data.containsKey('user_title')) {
      context.handle(
        _userTitleMeta,
        userTitle.isAcceptableOrUnknown(data['user_title']!, _userTitleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  LibraryMetadataRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryMetadataRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      lastOpenedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_opened_at'],
      ),
      lastModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_modified_at'],
      )!,
      userTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_title'],
      ),
    );
  }

  @override
  $LibraryMetadataTable createAlias(String alias) {
    return $LibraryMetadataTable(attachedDatabase, alias);
  }
}

class LibraryMetadataRow extends DataClass
    implements Insertable<LibraryMetadataRow> {
  /// Defines the pattern document represented in the user's library.
  final String documentId;

  /// Defines when the library entry was first created locally.
  final DateTime createdAt;

  /// Defines when the normalized pattern was imported into the library.
  final DateTime importedAt;

  /// Defines the most recent open time, or null before the first open.
  final DateTime? lastOpenedAt;

  /// Defines when library metadata or progress was last modified.
  final DateTime lastModifiedAt;

  /// Defines an optional user-defined title distinct from the imported title.
  final String? userTitle;
  const LibraryMetadataRow({
    required this.documentId,
    required this.createdAt,
    required this.importedAt,
    this.lastOpenedAt,
    required this.lastModifiedAt,
    this.userTitle,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['imported_at'] = Variable<DateTime>(importedAt);
    if (!nullToAbsent || lastOpenedAt != null) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt);
    }
    map['last_modified_at'] = Variable<DateTime>(lastModifiedAt);
    if (!nullToAbsent || userTitle != null) {
      map['user_title'] = Variable<String>(userTitle);
    }
    return map;
  }

  LibraryMetadataCompanion toCompanion(bool nullToAbsent) {
    return LibraryMetadataCompanion(
      documentId: Value(documentId),
      createdAt: Value(createdAt),
      importedAt: Value(importedAt),
      lastOpenedAt: lastOpenedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastOpenedAt),
      lastModifiedAt: Value(lastModifiedAt),
      userTitle: userTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(userTitle),
    );
  }

  factory LibraryMetadataRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryMetadataRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      lastOpenedAt: serializer.fromJson<DateTime?>(json['lastOpenedAt']),
      lastModifiedAt: serializer.fromJson<DateTime>(json['lastModifiedAt']),
      userTitle: serializer.fromJson<String?>(json['userTitle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'lastOpenedAt': serializer.toJson<DateTime?>(lastOpenedAt),
      'lastModifiedAt': serializer.toJson<DateTime>(lastModifiedAt),
      'userTitle': serializer.toJson<String?>(userTitle),
    };
  }

  LibraryMetadataRow copyWith({
    String? documentId,
    DateTime? createdAt,
    DateTime? importedAt,
    Value<DateTime?> lastOpenedAt = const Value.absent(),
    DateTime? lastModifiedAt,
    Value<String?> userTitle = const Value.absent(),
  }) => LibraryMetadataRow(
    documentId: documentId ?? this.documentId,
    createdAt: createdAt ?? this.createdAt,
    importedAt: importedAt ?? this.importedAt,
    lastOpenedAt: lastOpenedAt.present ? lastOpenedAt.value : this.lastOpenedAt,
    lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
    userTitle: userTitle.present ? userTitle.value : this.userTitle,
  );
  LibraryMetadataRow copyWithCompanion(LibraryMetadataCompanion data) {
    return LibraryMetadataRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      lastOpenedAt: data.lastOpenedAt.present
          ? data.lastOpenedAt.value
          : this.lastOpenedAt,
      lastModifiedAt: data.lastModifiedAt.present
          ? data.lastModifiedAt.value
          : this.lastModifiedAt,
      userTitle: data.userTitle.present ? data.userTitle.value : this.userTitle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryMetadataRow(')
          ..write('documentId: $documentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('importedAt: $importedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('userTitle: $userTitle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    createdAt,
    importedAt,
    lastOpenedAt,
    lastModifiedAt,
    userTitle,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryMetadataRow &&
          other.documentId == this.documentId &&
          other.createdAt == this.createdAt &&
          other.importedAt == this.importedAt &&
          other.lastOpenedAt == this.lastOpenedAt &&
          other.lastModifiedAt == this.lastModifiedAt &&
          other.userTitle == this.userTitle);
}

class LibraryMetadataCompanion extends UpdateCompanion<LibraryMetadataRow> {
  final Value<String> documentId;
  final Value<DateTime> createdAt;
  final Value<DateTime> importedAt;
  final Value<DateTime?> lastOpenedAt;
  final Value<DateTime> lastModifiedAt;
  final Value<String?> userTitle;
  final Value<int> rowid;
  const LibraryMetadataCompanion({
    this.documentId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.lastOpenedAt = const Value.absent(),
    this.lastModifiedAt = const Value.absent(),
    this.userTitle = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryMetadataCompanion.insert({
    required String documentId,
    required DateTime createdAt,
    required DateTime importedAt,
    this.lastOpenedAt = const Value.absent(),
    required DateTime lastModifiedAt,
    this.userTitle = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       createdAt = Value(createdAt),
       importedAt = Value(importedAt),
       lastModifiedAt = Value(lastModifiedAt);
  static Insertable<LibraryMetadataRow> custom({
    Expression<String>? documentId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? importedAt,
    Expression<DateTime>? lastOpenedAt,
    Expression<DateTime>? lastModifiedAt,
    Expression<String>? userTitle,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (createdAt != null) 'created_at': createdAt,
      if (importedAt != null) 'imported_at': importedAt,
      if (lastOpenedAt != null) 'last_opened_at': lastOpenedAt,
      if (lastModifiedAt != null) 'last_modified_at': lastModifiedAt,
      if (userTitle != null) 'user_title': userTitle,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryMetadataCompanion copyWith({
    Value<String>? documentId,
    Value<DateTime>? createdAt,
    Value<DateTime>? importedAt,
    Value<DateTime?>? lastOpenedAt,
    Value<DateTime>? lastModifiedAt,
    Value<String?>? userTitle,
    Value<int>? rowid,
  }) {
    return LibraryMetadataCompanion(
      documentId: documentId ?? this.documentId,
      createdAt: createdAt ?? this.createdAt,
      importedAt: importedAt ?? this.importedAt,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      lastModifiedAt: lastModifiedAt ?? this.lastModifiedAt,
      userTitle: userTitle ?? this.userTitle,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (lastOpenedAt.present) {
      map['last_opened_at'] = Variable<DateTime>(lastOpenedAt.value);
    }
    if (lastModifiedAt.present) {
      map['last_modified_at'] = Variable<DateTime>(lastModifiedAt.value);
    }
    if (userTitle.present) {
      map['user_title'] = Variable<String>(userTitle.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryMetadataCompanion(')
          ..write('documentId: $documentId, ')
          ..write('createdAt: $createdAt, ')
          ..write('importedAt: $importedAt, ')
          ..write('lastOpenedAt: $lastOpenedAt, ')
          ..write('lastModifiedAt: $lastModifiedAt, ')
          ..write('userTitle: $userTitle, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatternSymbolsTable extends PatternSymbols
    with TableInfo<$PatternSymbolsTable, PatternSymbolRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatternSymbolsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceSymbolMeta = const VerificationMeta(
    'sourceSymbol',
  );
  @override
  late final GeneratedColumn<String> sourceSymbol = GeneratedColumn<String>(
    'source_symbol',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _normalizedKeyMeta = const VerificationMeta(
    'normalizedKey',
  );
  @override
  late final GeneratedColumn<String> normalizedKey = GeneratedColumn<String>(
    'normalized_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayGlyphMeta = const VerificationMeta(
    'displayGlyph',
  );
  @override
  late final GeneratedColumn<String> displayGlyph = GeneratedColumn<String>(
    'display_glyph',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _threadIdMeta = const VerificationMeta(
    'threadId',
  );
  @override
  late final GeneratedColumn<String> threadId = GeneratedColumn<String>(
    'thread_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _threadBrandMeta = const VerificationMeta(
    'threadBrand',
  );
  @override
  late final GeneratedColumn<String> threadBrand = GeneratedColumn<String>(
    'thread_brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _threadCatalogNumberMeta =
      const VerificationMeta('threadCatalogNumber');
  @override
  late final GeneratedColumn<String> threadCatalogNumber =
      GeneratedColumn<String>(
        'thread_catalog_number',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _threadNameMeta = const VerificationMeta(
    'threadName',
  );
  @override
  late final GeneratedColumn<String> threadName = GeneratedColumn<String>(
    'thread_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _threadColorMeta = const VerificationMeta(
    'threadColor',
  );
  @override
  late final GeneratedColumn<String> threadColor = GeneratedColumn<String>(
    'thread_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _threadConversionNotesMeta =
      const VerificationMeta('threadConversionNotes');
  @override
  late final GeneratedColumn<String> threadConversionNotes =
      GeneratedColumn<String>(
        'thread_conversion_notes',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _threadEvidenceMeta = const VerificationMeta(
    'threadEvidence',
  );
  @override
  late final GeneratedColumn<String> threadEvidence = GeneratedColumn<String>(
    'thread_evidence',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legendEvidenceMeta = const VerificationMeta(
    'legendEvidence',
  );
  @override
  late final GeneratedColumn<String> legendEvidence = GeneratedColumn<String>(
    'legend_evidence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    id,
    sortOrder,
    sourceSymbol,
    normalizedKey,
    displayGlyph,
    threadId,
    threadBrand,
    threadCatalogNumber,
    threadName,
    threadColor,
    threadConversionNotes,
    threadEvidence,
    legendEvidence,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pattern_symbols';
  @override
  VerificationContext validateIntegrity(
    Insertable<PatternSymbolRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('source_symbol')) {
      context.handle(
        _sourceSymbolMeta,
        sourceSymbol.isAcceptableOrUnknown(
          data['source_symbol']!,
          _sourceSymbolMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceSymbolMeta);
    }
    if (data.containsKey('normalized_key')) {
      context.handle(
        _normalizedKeyMeta,
        normalizedKey.isAcceptableOrUnknown(
          data['normalized_key']!,
          _normalizedKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_normalizedKeyMeta);
    }
    if (data.containsKey('display_glyph')) {
      context.handle(
        _displayGlyphMeta,
        displayGlyph.isAcceptableOrUnknown(
          data['display_glyph']!,
          _displayGlyphMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayGlyphMeta);
    }
    if (data.containsKey('thread_id')) {
      context.handle(
        _threadIdMeta,
        threadId.isAcceptableOrUnknown(data['thread_id']!, _threadIdMeta),
      );
    } else if (isInserting) {
      context.missing(_threadIdMeta);
    }
    if (data.containsKey('thread_brand')) {
      context.handle(
        _threadBrandMeta,
        threadBrand.isAcceptableOrUnknown(
          data['thread_brand']!,
          _threadBrandMeta,
        ),
      );
    }
    if (data.containsKey('thread_catalog_number')) {
      context.handle(
        _threadCatalogNumberMeta,
        threadCatalogNumber.isAcceptableOrUnknown(
          data['thread_catalog_number']!,
          _threadCatalogNumberMeta,
        ),
      );
    }
    if (data.containsKey('thread_name')) {
      context.handle(
        _threadNameMeta,
        threadName.isAcceptableOrUnknown(data['thread_name']!, _threadNameMeta),
      );
    }
    if (data.containsKey('thread_color')) {
      context.handle(
        _threadColorMeta,
        threadColor.isAcceptableOrUnknown(
          data['thread_color']!,
          _threadColorMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_threadColorMeta);
    }
    if (data.containsKey('thread_conversion_notes')) {
      context.handle(
        _threadConversionNotesMeta,
        threadConversionNotes.isAcceptableOrUnknown(
          data['thread_conversion_notes']!,
          _threadConversionNotesMeta,
        ),
      );
    }
    if (data.containsKey('thread_evidence')) {
      context.handle(
        _threadEvidenceMeta,
        threadEvidence.isAcceptableOrUnknown(
          data['thread_evidence']!,
          _threadEvidenceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_threadEvidenceMeta);
    }
    if (data.containsKey('legend_evidence')) {
      context.handle(
        _legendEvidenceMeta,
        legendEvidence.isAcceptableOrUnknown(
          data['legend_evidence']!,
          _legendEvidenceMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, id};
  @override
  PatternSymbolRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatternSymbolRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      sourceSymbol: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_symbol'],
      )!,
      normalizedKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}normalized_key'],
      )!,
      displayGlyph: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_glyph'],
      )!,
      threadId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_id'],
      )!,
      threadBrand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_brand'],
      ),
      threadCatalogNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_catalog_number'],
      ),
      threadName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_name'],
      ),
      threadColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_color'],
      )!,
      threadConversionNotes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_conversion_notes'],
      ),
      threadEvidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}thread_evidence'],
      )!,
      legendEvidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legend_evidence'],
      ),
    );
  }

  @override
  $PatternSymbolsTable createAlias(String alias) {
    return $PatternSymbolsTable(attachedDatabase, alias);
  }
}

class PatternSymbolRow extends DataClass
    implements Insertable<PatternSymbolRow> {
  /// Defines the parent pattern document.
  final String documentId;

  /// Defines the stable symbol identifier within the document.
  final String id;

  /// Preserves the symbol's order in the portable document.
  final int sortOrder;

  /// Defines the symbol text found in the imported source.
  final String sourceSymbol;

  /// Defines the canonical symbol lookup key.
  final String normalizedKey;

  /// Defines the glyph rendered in the pattern grid.
  final String displayGlyph;

  /// Defines the exact thread identifier used by the symbol.
  final String threadId;

  /// Defines the optional thread manufacturer.
  final String? threadBrand;

  /// Defines the optional manufacturer catalog number.
  final String? threadCatalogNumber;

  /// Defines the optional human-readable thread color name.
  final String? threadName;

  /// Defines the canonical thread color in `#RRGGBB` notation.
  final String threadColor;

  /// Defines optional substitution or conversion notes.
  final String? threadConversionNotes;

  /// Defines whether the thread color was explicit or inferred.
  final String threadEvidence;

  /// Defines optional source legend evidence for the mapping.
  final String? legendEvidence;
  const PatternSymbolRow({
    required this.documentId,
    required this.id,
    required this.sortOrder,
    required this.sourceSymbol,
    required this.normalizedKey,
    required this.displayGlyph,
    required this.threadId,
    this.threadBrand,
    this.threadCatalogNumber,
    this.threadName,
    required this.threadColor,
    this.threadConversionNotes,
    required this.threadEvidence,
    this.legendEvidence,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['id'] = Variable<String>(id);
    map['sort_order'] = Variable<int>(sortOrder);
    map['source_symbol'] = Variable<String>(sourceSymbol);
    map['normalized_key'] = Variable<String>(normalizedKey);
    map['display_glyph'] = Variable<String>(displayGlyph);
    map['thread_id'] = Variable<String>(threadId);
    if (!nullToAbsent || threadBrand != null) {
      map['thread_brand'] = Variable<String>(threadBrand);
    }
    if (!nullToAbsent || threadCatalogNumber != null) {
      map['thread_catalog_number'] = Variable<String>(threadCatalogNumber);
    }
    if (!nullToAbsent || threadName != null) {
      map['thread_name'] = Variable<String>(threadName);
    }
    map['thread_color'] = Variable<String>(threadColor);
    if (!nullToAbsent || threadConversionNotes != null) {
      map['thread_conversion_notes'] = Variable<String>(threadConversionNotes);
    }
    map['thread_evidence'] = Variable<String>(threadEvidence);
    if (!nullToAbsent || legendEvidence != null) {
      map['legend_evidence'] = Variable<String>(legendEvidence);
    }
    return map;
  }

  PatternSymbolsCompanion toCompanion(bool nullToAbsent) {
    return PatternSymbolsCompanion(
      documentId: Value(documentId),
      id: Value(id),
      sortOrder: Value(sortOrder),
      sourceSymbol: Value(sourceSymbol),
      normalizedKey: Value(normalizedKey),
      displayGlyph: Value(displayGlyph),
      threadId: Value(threadId),
      threadBrand: threadBrand == null && nullToAbsent
          ? const Value.absent()
          : Value(threadBrand),
      threadCatalogNumber: threadCatalogNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(threadCatalogNumber),
      threadName: threadName == null && nullToAbsent
          ? const Value.absent()
          : Value(threadName),
      threadColor: Value(threadColor),
      threadConversionNotes: threadConversionNotes == null && nullToAbsent
          ? const Value.absent()
          : Value(threadConversionNotes),
      threadEvidence: Value(threadEvidence),
      legendEvidence: legendEvidence == null && nullToAbsent
          ? const Value.absent()
          : Value(legendEvidence),
    );
  }

  factory PatternSymbolRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatternSymbolRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      id: serializer.fromJson<String>(json['id']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      sourceSymbol: serializer.fromJson<String>(json['sourceSymbol']),
      normalizedKey: serializer.fromJson<String>(json['normalizedKey']),
      displayGlyph: serializer.fromJson<String>(json['displayGlyph']),
      threadId: serializer.fromJson<String>(json['threadId']),
      threadBrand: serializer.fromJson<String?>(json['threadBrand']),
      threadCatalogNumber: serializer.fromJson<String?>(
        json['threadCatalogNumber'],
      ),
      threadName: serializer.fromJson<String?>(json['threadName']),
      threadColor: serializer.fromJson<String>(json['threadColor']),
      threadConversionNotes: serializer.fromJson<String?>(
        json['threadConversionNotes'],
      ),
      threadEvidence: serializer.fromJson<String>(json['threadEvidence']),
      legendEvidence: serializer.fromJson<String?>(json['legendEvidence']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'id': serializer.toJson<String>(id),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'sourceSymbol': serializer.toJson<String>(sourceSymbol),
      'normalizedKey': serializer.toJson<String>(normalizedKey),
      'displayGlyph': serializer.toJson<String>(displayGlyph),
      'threadId': serializer.toJson<String>(threadId),
      'threadBrand': serializer.toJson<String?>(threadBrand),
      'threadCatalogNumber': serializer.toJson<String?>(threadCatalogNumber),
      'threadName': serializer.toJson<String?>(threadName),
      'threadColor': serializer.toJson<String>(threadColor),
      'threadConversionNotes': serializer.toJson<String?>(
        threadConversionNotes,
      ),
      'threadEvidence': serializer.toJson<String>(threadEvidence),
      'legendEvidence': serializer.toJson<String?>(legendEvidence),
    };
  }

  PatternSymbolRow copyWith({
    String? documentId,
    String? id,
    int? sortOrder,
    String? sourceSymbol,
    String? normalizedKey,
    String? displayGlyph,
    String? threadId,
    Value<String?> threadBrand = const Value.absent(),
    Value<String?> threadCatalogNumber = const Value.absent(),
    Value<String?> threadName = const Value.absent(),
    String? threadColor,
    Value<String?> threadConversionNotes = const Value.absent(),
    String? threadEvidence,
    Value<String?> legendEvidence = const Value.absent(),
  }) => PatternSymbolRow(
    documentId: documentId ?? this.documentId,
    id: id ?? this.id,
    sortOrder: sortOrder ?? this.sortOrder,
    sourceSymbol: sourceSymbol ?? this.sourceSymbol,
    normalizedKey: normalizedKey ?? this.normalizedKey,
    displayGlyph: displayGlyph ?? this.displayGlyph,
    threadId: threadId ?? this.threadId,
    threadBrand: threadBrand.present ? threadBrand.value : this.threadBrand,
    threadCatalogNumber: threadCatalogNumber.present
        ? threadCatalogNumber.value
        : this.threadCatalogNumber,
    threadName: threadName.present ? threadName.value : this.threadName,
    threadColor: threadColor ?? this.threadColor,
    threadConversionNotes: threadConversionNotes.present
        ? threadConversionNotes.value
        : this.threadConversionNotes,
    threadEvidence: threadEvidence ?? this.threadEvidence,
    legendEvidence: legendEvidence.present
        ? legendEvidence.value
        : this.legendEvidence,
  );
  PatternSymbolRow copyWithCompanion(PatternSymbolsCompanion data) {
    return PatternSymbolRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      id: data.id.present ? data.id.value : this.id,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      sourceSymbol: data.sourceSymbol.present
          ? data.sourceSymbol.value
          : this.sourceSymbol,
      normalizedKey: data.normalizedKey.present
          ? data.normalizedKey.value
          : this.normalizedKey,
      displayGlyph: data.displayGlyph.present
          ? data.displayGlyph.value
          : this.displayGlyph,
      threadId: data.threadId.present ? data.threadId.value : this.threadId,
      threadBrand: data.threadBrand.present
          ? data.threadBrand.value
          : this.threadBrand,
      threadCatalogNumber: data.threadCatalogNumber.present
          ? data.threadCatalogNumber.value
          : this.threadCatalogNumber,
      threadName: data.threadName.present
          ? data.threadName.value
          : this.threadName,
      threadColor: data.threadColor.present
          ? data.threadColor.value
          : this.threadColor,
      threadConversionNotes: data.threadConversionNotes.present
          ? data.threadConversionNotes.value
          : this.threadConversionNotes,
      threadEvidence: data.threadEvidence.present
          ? data.threadEvidence.value
          : this.threadEvidence,
      legendEvidence: data.legendEvidence.present
          ? data.legendEvidence.value
          : this.legendEvidence,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatternSymbolRow(')
          ..write('documentId: $documentId, ')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('sourceSymbol: $sourceSymbol, ')
          ..write('normalizedKey: $normalizedKey, ')
          ..write('displayGlyph: $displayGlyph, ')
          ..write('threadId: $threadId, ')
          ..write('threadBrand: $threadBrand, ')
          ..write('threadCatalogNumber: $threadCatalogNumber, ')
          ..write('threadName: $threadName, ')
          ..write('threadColor: $threadColor, ')
          ..write('threadConversionNotes: $threadConversionNotes, ')
          ..write('threadEvidence: $threadEvidence, ')
          ..write('legendEvidence: $legendEvidence')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    id,
    sortOrder,
    sourceSymbol,
    normalizedKey,
    displayGlyph,
    threadId,
    threadBrand,
    threadCatalogNumber,
    threadName,
    threadColor,
    threadConversionNotes,
    threadEvidence,
    legendEvidence,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatternSymbolRow &&
          other.documentId == this.documentId &&
          other.id == this.id &&
          other.sortOrder == this.sortOrder &&
          other.sourceSymbol == this.sourceSymbol &&
          other.normalizedKey == this.normalizedKey &&
          other.displayGlyph == this.displayGlyph &&
          other.threadId == this.threadId &&
          other.threadBrand == this.threadBrand &&
          other.threadCatalogNumber == this.threadCatalogNumber &&
          other.threadName == this.threadName &&
          other.threadColor == this.threadColor &&
          other.threadConversionNotes == this.threadConversionNotes &&
          other.threadEvidence == this.threadEvidence &&
          other.legendEvidence == this.legendEvidence);
}

class PatternSymbolsCompanion extends UpdateCompanion<PatternSymbolRow> {
  final Value<String> documentId;
  final Value<String> id;
  final Value<int> sortOrder;
  final Value<String> sourceSymbol;
  final Value<String> normalizedKey;
  final Value<String> displayGlyph;
  final Value<String> threadId;
  final Value<String?> threadBrand;
  final Value<String?> threadCatalogNumber;
  final Value<String?> threadName;
  final Value<String> threadColor;
  final Value<String?> threadConversionNotes;
  final Value<String> threadEvidence;
  final Value<String?> legendEvidence;
  final Value<int> rowid;
  const PatternSymbolsCompanion({
    this.documentId = const Value.absent(),
    this.id = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.sourceSymbol = const Value.absent(),
    this.normalizedKey = const Value.absent(),
    this.displayGlyph = const Value.absent(),
    this.threadId = const Value.absent(),
    this.threadBrand = const Value.absent(),
    this.threadCatalogNumber = const Value.absent(),
    this.threadName = const Value.absent(),
    this.threadColor = const Value.absent(),
    this.threadConversionNotes = const Value.absent(),
    this.threadEvidence = const Value.absent(),
    this.legendEvidence = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatternSymbolsCompanion.insert({
    required String documentId,
    required String id,
    required int sortOrder,
    required String sourceSymbol,
    required String normalizedKey,
    required String displayGlyph,
    required String threadId,
    this.threadBrand = const Value.absent(),
    this.threadCatalogNumber = const Value.absent(),
    this.threadName = const Value.absent(),
    required String threadColor,
    this.threadConversionNotes = const Value.absent(),
    required String threadEvidence,
    this.legendEvidence = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       id = Value(id),
       sortOrder = Value(sortOrder),
       sourceSymbol = Value(sourceSymbol),
       normalizedKey = Value(normalizedKey),
       displayGlyph = Value(displayGlyph),
       threadId = Value(threadId),
       threadColor = Value(threadColor),
       threadEvidence = Value(threadEvidence);
  static Insertable<PatternSymbolRow> custom({
    Expression<String>? documentId,
    Expression<String>? id,
    Expression<int>? sortOrder,
    Expression<String>? sourceSymbol,
    Expression<String>? normalizedKey,
    Expression<String>? displayGlyph,
    Expression<String>? threadId,
    Expression<String>? threadBrand,
    Expression<String>? threadCatalogNumber,
    Expression<String>? threadName,
    Expression<String>? threadColor,
    Expression<String>? threadConversionNotes,
    Expression<String>? threadEvidence,
    Expression<String>? legendEvidence,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (id != null) 'id': id,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (sourceSymbol != null) 'source_symbol': sourceSymbol,
      if (normalizedKey != null) 'normalized_key': normalizedKey,
      if (displayGlyph != null) 'display_glyph': displayGlyph,
      if (threadId != null) 'thread_id': threadId,
      if (threadBrand != null) 'thread_brand': threadBrand,
      if (threadCatalogNumber != null)
        'thread_catalog_number': threadCatalogNumber,
      if (threadName != null) 'thread_name': threadName,
      if (threadColor != null) 'thread_color': threadColor,
      if (threadConversionNotes != null)
        'thread_conversion_notes': threadConversionNotes,
      if (threadEvidence != null) 'thread_evidence': threadEvidence,
      if (legendEvidence != null) 'legend_evidence': legendEvidence,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatternSymbolsCompanion copyWith({
    Value<String>? documentId,
    Value<String>? id,
    Value<int>? sortOrder,
    Value<String>? sourceSymbol,
    Value<String>? normalizedKey,
    Value<String>? displayGlyph,
    Value<String>? threadId,
    Value<String?>? threadBrand,
    Value<String?>? threadCatalogNumber,
    Value<String?>? threadName,
    Value<String>? threadColor,
    Value<String?>? threadConversionNotes,
    Value<String>? threadEvidence,
    Value<String?>? legendEvidence,
    Value<int>? rowid,
  }) {
    return PatternSymbolsCompanion(
      documentId: documentId ?? this.documentId,
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
      sourceSymbol: sourceSymbol ?? this.sourceSymbol,
      normalizedKey: normalizedKey ?? this.normalizedKey,
      displayGlyph: displayGlyph ?? this.displayGlyph,
      threadId: threadId ?? this.threadId,
      threadBrand: threadBrand ?? this.threadBrand,
      threadCatalogNumber: threadCatalogNumber ?? this.threadCatalogNumber,
      threadName: threadName ?? this.threadName,
      threadColor: threadColor ?? this.threadColor,
      threadConversionNotes:
          threadConversionNotes ?? this.threadConversionNotes,
      threadEvidence: threadEvidence ?? this.threadEvidence,
      legendEvidence: legendEvidence ?? this.legendEvidence,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (sourceSymbol.present) {
      map['source_symbol'] = Variable<String>(sourceSymbol.value);
    }
    if (normalizedKey.present) {
      map['normalized_key'] = Variable<String>(normalizedKey.value);
    }
    if (displayGlyph.present) {
      map['display_glyph'] = Variable<String>(displayGlyph.value);
    }
    if (threadId.present) {
      map['thread_id'] = Variable<String>(threadId.value);
    }
    if (threadBrand.present) {
      map['thread_brand'] = Variable<String>(threadBrand.value);
    }
    if (threadCatalogNumber.present) {
      map['thread_catalog_number'] = Variable<String>(
        threadCatalogNumber.value,
      );
    }
    if (threadName.present) {
      map['thread_name'] = Variable<String>(threadName.value);
    }
    if (threadColor.present) {
      map['thread_color'] = Variable<String>(threadColor.value);
    }
    if (threadConversionNotes.present) {
      map['thread_conversion_notes'] = Variable<String>(
        threadConversionNotes.value,
      );
    }
    if (threadEvidence.present) {
      map['thread_evidence'] = Variable<String>(threadEvidence.value);
    }
    if (legendEvidence.present) {
      map['legend_evidence'] = Variable<String>(legendEvidence.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatternSymbolsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('sourceSymbol: $sourceSymbol, ')
          ..write('normalizedKey: $normalizedKey, ')
          ..write('displayGlyph: $displayGlyph, ')
          ..write('threadId: $threadId, ')
          ..write('threadBrand: $threadBrand, ')
          ..write('threadCatalogNumber: $threadCatalogNumber, ')
          ..write('threadName: $threadName, ')
          ..write('threadColor: $threadColor, ')
          ..write('threadConversionNotes: $threadConversionNotes, ')
          ..write('threadEvidence: $threadEvidence, ')
          ..write('legendEvidence: $legendEvidence, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatternRegionsTable extends PatternRegions
    with TableInfo<$PatternRegionsTable, PatternRegionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatternRegionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourcePageMeta = const VerificationMeta(
    'sourcePage',
  );
  @override
  late final GeneratedColumn<int> sourcePage = GeneratedColumn<int>(
    'source_page',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originRowMeta = const VerificationMeta(
    'originRow',
  );
  @override
  late final GeneratedColumn<int> originRow = GeneratedColumn<int>(
    'origin_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originColumnMeta = const VerificationMeta(
    'originColumn',
  );
  @override
  late final GeneratedColumn<int> originColumn = GeneratedColumn<int>(
    'origin_column',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _rowCountMeta = const VerificationMeta(
    'rowCount',
  );
  @override
  late final GeneratedColumn<int> rowCount = GeneratedColumn<int>(
    'row_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _columnCountMeta = const VerificationMeta(
    'columnCount',
  );
  @override
  late final GeneratedColumn<int> columnCount = GeneratedColumn<int>(
    'column_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    id,
    sortOrder,
    sourcePage,
    originRow,
    originColumn,
    rowCount,
    columnCount,
    label,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pattern_regions';
  @override
  VerificationContext validateIntegrity(
    Insertable<PatternRegionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('source_page')) {
      context.handle(
        _sourcePageMeta,
        sourcePage.isAcceptableOrUnknown(data['source_page']!, _sourcePageMeta),
      );
    } else if (isInserting) {
      context.missing(_sourcePageMeta);
    }
    if (data.containsKey('origin_row')) {
      context.handle(
        _originRowMeta,
        originRow.isAcceptableOrUnknown(data['origin_row']!, _originRowMeta),
      );
    } else if (isInserting) {
      context.missing(_originRowMeta);
    }
    if (data.containsKey('origin_column')) {
      context.handle(
        _originColumnMeta,
        originColumn.isAcceptableOrUnknown(
          data['origin_column']!,
          _originColumnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_originColumnMeta);
    }
    if (data.containsKey('row_count')) {
      context.handle(
        _rowCountMeta,
        rowCount.isAcceptableOrUnknown(data['row_count']!, _rowCountMeta),
      );
    } else if (isInserting) {
      context.missing(_rowCountMeta);
    }
    if (data.containsKey('column_count')) {
      context.handle(
        _columnCountMeta,
        columnCount.isAcceptableOrUnknown(
          data['column_count']!,
          _columnCountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_columnCountMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, id};
  @override
  PatternRegionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatternRegionRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      sourcePage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_page'],
      )!,
      originRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origin_row'],
      )!,
      originColumn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}origin_column'],
      )!,
      rowCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}row_count'],
      )!,
      columnCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}column_count'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      ),
    );
  }

  @override
  $PatternRegionsTable createAlias(String alias) {
    return $PatternRegionsTable(attachedDatabase, alias);
  }
}

class PatternRegionRow extends DataClass
    implements Insertable<PatternRegionRow> {
  /// Defines the parent pattern document.
  final String documentId;

  /// Defines the stable provenance region identifier.
  final String id;

  /// Preserves the region's order in the portable document.
  final int sortOrder;

  /// Defines the zero-based source page number.
  final int sourcePage;

  /// Defines the region's top-most global grid row.
  final int originRow;

  /// Defines the region's left-most global grid column.
  final int originColumn;

  /// Defines the number of global rows covered by the region.
  final int rowCount;

  /// Defines the number of global columns covered by the region.
  final int columnCount;

  /// Defines the optional source page or panel label.
  final String? label;
  const PatternRegionRow({
    required this.documentId,
    required this.id,
    required this.sortOrder,
    required this.sourcePage,
    required this.originRow,
    required this.originColumn,
    required this.rowCount,
    required this.columnCount,
    this.label,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['id'] = Variable<String>(id);
    map['sort_order'] = Variable<int>(sortOrder);
    map['source_page'] = Variable<int>(sourcePage);
    map['origin_row'] = Variable<int>(originRow);
    map['origin_column'] = Variable<int>(originColumn);
    map['row_count'] = Variable<int>(rowCount);
    map['column_count'] = Variable<int>(columnCount);
    if (!nullToAbsent || label != null) {
      map['label'] = Variable<String>(label);
    }
    return map;
  }

  PatternRegionsCompanion toCompanion(bool nullToAbsent) {
    return PatternRegionsCompanion(
      documentId: Value(documentId),
      id: Value(id),
      sortOrder: Value(sortOrder),
      sourcePage: Value(sourcePage),
      originRow: Value(originRow),
      originColumn: Value(originColumn),
      rowCount: Value(rowCount),
      columnCount: Value(columnCount),
      label: label == null && nullToAbsent
          ? const Value.absent()
          : Value(label),
    );
  }

  factory PatternRegionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatternRegionRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      id: serializer.fromJson<String>(json['id']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      sourcePage: serializer.fromJson<int>(json['sourcePage']),
      originRow: serializer.fromJson<int>(json['originRow']),
      originColumn: serializer.fromJson<int>(json['originColumn']),
      rowCount: serializer.fromJson<int>(json['rowCount']),
      columnCount: serializer.fromJson<int>(json['columnCount']),
      label: serializer.fromJson<String?>(json['label']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'id': serializer.toJson<String>(id),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'sourcePage': serializer.toJson<int>(sourcePage),
      'originRow': serializer.toJson<int>(originRow),
      'originColumn': serializer.toJson<int>(originColumn),
      'rowCount': serializer.toJson<int>(rowCount),
      'columnCount': serializer.toJson<int>(columnCount),
      'label': serializer.toJson<String?>(label),
    };
  }

  PatternRegionRow copyWith({
    String? documentId,
    String? id,
    int? sortOrder,
    int? sourcePage,
    int? originRow,
    int? originColumn,
    int? rowCount,
    int? columnCount,
    Value<String?> label = const Value.absent(),
  }) => PatternRegionRow(
    documentId: documentId ?? this.documentId,
    id: id ?? this.id,
    sortOrder: sortOrder ?? this.sortOrder,
    sourcePage: sourcePage ?? this.sourcePage,
    originRow: originRow ?? this.originRow,
    originColumn: originColumn ?? this.originColumn,
    rowCount: rowCount ?? this.rowCount,
    columnCount: columnCount ?? this.columnCount,
    label: label.present ? label.value : this.label,
  );
  PatternRegionRow copyWithCompanion(PatternRegionsCompanion data) {
    return PatternRegionRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      id: data.id.present ? data.id.value : this.id,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      sourcePage: data.sourcePage.present
          ? data.sourcePage.value
          : this.sourcePage,
      originRow: data.originRow.present ? data.originRow.value : this.originRow,
      originColumn: data.originColumn.present
          ? data.originColumn.value
          : this.originColumn,
      rowCount: data.rowCount.present ? data.rowCount.value : this.rowCount,
      columnCount: data.columnCount.present
          ? data.columnCount.value
          : this.columnCount,
      label: data.label.present ? data.label.value : this.label,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatternRegionRow(')
          ..write('documentId: $documentId, ')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('sourcePage: $sourcePage, ')
          ..write('originRow: $originRow, ')
          ..write('originColumn: $originColumn, ')
          ..write('rowCount: $rowCount, ')
          ..write('columnCount: $columnCount, ')
          ..write('label: $label')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    id,
    sortOrder,
    sourcePage,
    originRow,
    originColumn,
    rowCount,
    columnCount,
    label,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatternRegionRow &&
          other.documentId == this.documentId &&
          other.id == this.id &&
          other.sortOrder == this.sortOrder &&
          other.sourcePage == this.sourcePage &&
          other.originRow == this.originRow &&
          other.originColumn == this.originColumn &&
          other.rowCount == this.rowCount &&
          other.columnCount == this.columnCount &&
          other.label == this.label);
}

class PatternRegionsCompanion extends UpdateCompanion<PatternRegionRow> {
  final Value<String> documentId;
  final Value<String> id;
  final Value<int> sortOrder;
  final Value<int> sourcePage;
  final Value<int> originRow;
  final Value<int> originColumn;
  final Value<int> rowCount;
  final Value<int> columnCount;
  final Value<String?> label;
  final Value<int> rowid;
  const PatternRegionsCompanion({
    this.documentId = const Value.absent(),
    this.id = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.sourcePage = const Value.absent(),
    this.originRow = const Value.absent(),
    this.originColumn = const Value.absent(),
    this.rowCount = const Value.absent(),
    this.columnCount = const Value.absent(),
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatternRegionsCompanion.insert({
    required String documentId,
    required String id,
    required int sortOrder,
    required int sourcePage,
    required int originRow,
    required int originColumn,
    required int rowCount,
    required int columnCount,
    this.label = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       id = Value(id),
       sortOrder = Value(sortOrder),
       sourcePage = Value(sourcePage),
       originRow = Value(originRow),
       originColumn = Value(originColumn),
       rowCount = Value(rowCount),
       columnCount = Value(columnCount);
  static Insertable<PatternRegionRow> custom({
    Expression<String>? documentId,
    Expression<String>? id,
    Expression<int>? sortOrder,
    Expression<int>? sourcePage,
    Expression<int>? originRow,
    Expression<int>? originColumn,
    Expression<int>? rowCount,
    Expression<int>? columnCount,
    Expression<String>? label,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (id != null) 'id': id,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (sourcePage != null) 'source_page': sourcePage,
      if (originRow != null) 'origin_row': originRow,
      if (originColumn != null) 'origin_column': originColumn,
      if (rowCount != null) 'row_count': rowCount,
      if (columnCount != null) 'column_count': columnCount,
      if (label != null) 'label': label,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatternRegionsCompanion copyWith({
    Value<String>? documentId,
    Value<String>? id,
    Value<int>? sortOrder,
    Value<int>? sourcePage,
    Value<int>? originRow,
    Value<int>? originColumn,
    Value<int>? rowCount,
    Value<int>? columnCount,
    Value<String?>? label,
    Value<int>? rowid,
  }) {
    return PatternRegionsCompanion(
      documentId: documentId ?? this.documentId,
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
      sourcePage: sourcePage ?? this.sourcePage,
      originRow: originRow ?? this.originRow,
      originColumn: originColumn ?? this.originColumn,
      rowCount: rowCount ?? this.rowCount,
      columnCount: columnCount ?? this.columnCount,
      label: label ?? this.label,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (sourcePage.present) {
      map['source_page'] = Variable<int>(sourcePage.value);
    }
    if (originRow.present) {
      map['origin_row'] = Variable<int>(originRow.value);
    }
    if (originColumn.present) {
      map['origin_column'] = Variable<int>(originColumn.value);
    }
    if (rowCount.present) {
      map['row_count'] = Variable<int>(rowCount.value);
    }
    if (columnCount.present) {
      map['column_count'] = Variable<int>(columnCount.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatternRegionsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('sourcePage: $sourcePage, ')
          ..write('originRow: $originRow, ')
          ..write('originColumn: $originColumn, ')
          ..write('rowCount: $rowCount, ')
          ..write('columnCount: $columnCount, ')
          ..write('label: $label, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PatternCellsTable extends PatternCells
    with TableInfo<$PatternCellsTable, PatternCellRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PatternCellsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridRowMeta = const VerificationMeta(
    'gridRow',
  );
  @override
  late final GeneratedColumn<int> gridRow = GeneratedColumn<int>(
    'grid_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridColumnMeta = const VerificationMeta(
    'gridColumn',
  );
  @override
  late final GeneratedColumn<int> gridColumn = GeneratedColumn<int>(
    'grid_column',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symbolIdMeta = const VerificationMeta(
    'symbolId',
  );
  @override
  late final GeneratedColumn<String> symbolId = GeneratedColumn<String>(
    'symbol_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stitchTypeMeta = const VerificationMeta(
    'stitchType',
  );
  @override
  late final GeneratedColumn<String> stitchType = GeneratedColumn<String>(
    'stitch_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _needsReviewMeta = const VerificationMeta(
    'needsReview',
  );
  @override
  late final GeneratedColumn<bool> needsReview = GeneratedColumn<bool>(
    'needs_review',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("needs_review" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _provenanceIdMeta = const VerificationMeta(
    'provenanceId',
  );
  @override
  late final GeneratedColumn<String> provenanceId = GeneratedColumn<String>(
    'provenance_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    sortOrder,
    gridRow,
    gridColumn,
    symbolId,
    stitchType,
    confidence,
    needsReview,
    provenanceId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pattern_cells';
  @override
  VerificationContext validateIntegrity(
    Insertable<PatternCellRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('grid_row')) {
      context.handle(
        _gridRowMeta,
        gridRow.isAcceptableOrUnknown(data['grid_row']!, _gridRowMeta),
      );
    } else if (isInserting) {
      context.missing(_gridRowMeta);
    }
    if (data.containsKey('grid_column')) {
      context.handle(
        _gridColumnMeta,
        gridColumn.isAcceptableOrUnknown(data['grid_column']!, _gridColumnMeta),
      );
    } else if (isInserting) {
      context.missing(_gridColumnMeta);
    }
    if (data.containsKey('symbol_id')) {
      context.handle(
        _symbolIdMeta,
        symbolId.isAcceptableOrUnknown(data['symbol_id']!, _symbolIdMeta),
      );
    } else if (isInserting) {
      context.missing(_symbolIdMeta);
    }
    if (data.containsKey('stitch_type')) {
      context.handle(
        _stitchTypeMeta,
        stitchType.isAcceptableOrUnknown(data['stitch_type']!, _stitchTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_stitchTypeMeta);
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('needs_review')) {
      context.handle(
        _needsReviewMeta,
        needsReview.isAcceptableOrUnknown(
          data['needs_review']!,
          _needsReviewMeta,
        ),
      );
    }
    if (data.containsKey('provenance_id')) {
      context.handle(
        _provenanceIdMeta,
        provenanceId.isAcceptableOrUnknown(
          data['provenance_id']!,
          _provenanceIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, gridRow, gridColumn};
  @override
  PatternCellRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PatternCellRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      gridRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_row'],
      )!,
      gridColumn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_column'],
      )!,
      symbolId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symbol_id'],
      )!,
      stitchType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stitch_type'],
      )!,
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      needsReview: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}needs_review'],
      )!,
      provenanceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance_id'],
      ),
    );
  }

  @override
  $PatternCellsTable createAlias(String alias) {
    return $PatternCellsTable(attachedDatabase, alias);
  }
}

class PatternCellRow extends DataClass implements Insertable<PatternCellRow> {
  /// Defines the parent pattern document.
  final String documentId;

  /// Preserves sparse cell order in the portable document.
  final int sortOrder;

  /// Defines the cell's zero-based global grid row.
  final int gridRow;

  /// Defines the cell's zero-based global grid column.
  final int gridColumn;

  /// Defines the symbol rendered for this stitch.
  final String symbolId;

  /// Defines the stitch technique using its portable enum name.
  final String stitchType;

  /// Defines the optional normalized parser confidence.
  final double? confidence;

  /// Defines whether this imported cell requires confirmation.
  final bool needsReview;

  /// Defines the optional source region that supplied the cell.
  final String? provenanceId;
  const PatternCellRow({
    required this.documentId,
    required this.sortOrder,
    required this.gridRow,
    required this.gridColumn,
    required this.symbolId,
    required this.stitchType,
    this.confidence,
    required this.needsReview,
    this.provenanceId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['sort_order'] = Variable<int>(sortOrder);
    map['grid_row'] = Variable<int>(gridRow);
    map['grid_column'] = Variable<int>(gridColumn);
    map['symbol_id'] = Variable<String>(symbolId);
    map['stitch_type'] = Variable<String>(stitchType);
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    map['needs_review'] = Variable<bool>(needsReview);
    if (!nullToAbsent || provenanceId != null) {
      map['provenance_id'] = Variable<String>(provenanceId);
    }
    return map;
  }

  PatternCellsCompanion toCompanion(bool nullToAbsent) {
    return PatternCellsCompanion(
      documentId: Value(documentId),
      sortOrder: Value(sortOrder),
      gridRow: Value(gridRow),
      gridColumn: Value(gridColumn),
      symbolId: Value(symbolId),
      stitchType: Value(stitchType),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      needsReview: Value(needsReview),
      provenanceId: provenanceId == null && nullToAbsent
          ? const Value.absent()
          : Value(provenanceId),
    );
  }

  factory PatternCellRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PatternCellRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      gridRow: serializer.fromJson<int>(json['gridRow']),
      gridColumn: serializer.fromJson<int>(json['gridColumn']),
      symbolId: serializer.fromJson<String>(json['symbolId']),
      stitchType: serializer.fromJson<String>(json['stitchType']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      needsReview: serializer.fromJson<bool>(json['needsReview']),
      provenanceId: serializer.fromJson<String?>(json['provenanceId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'gridRow': serializer.toJson<int>(gridRow),
      'gridColumn': serializer.toJson<int>(gridColumn),
      'symbolId': serializer.toJson<String>(symbolId),
      'stitchType': serializer.toJson<String>(stitchType),
      'confidence': serializer.toJson<double?>(confidence),
      'needsReview': serializer.toJson<bool>(needsReview),
      'provenanceId': serializer.toJson<String?>(provenanceId),
    };
  }

  PatternCellRow copyWith({
    String? documentId,
    int? sortOrder,
    int? gridRow,
    int? gridColumn,
    String? symbolId,
    String? stitchType,
    Value<double?> confidence = const Value.absent(),
    bool? needsReview,
    Value<String?> provenanceId = const Value.absent(),
  }) => PatternCellRow(
    documentId: documentId ?? this.documentId,
    sortOrder: sortOrder ?? this.sortOrder,
    gridRow: gridRow ?? this.gridRow,
    gridColumn: gridColumn ?? this.gridColumn,
    symbolId: symbolId ?? this.symbolId,
    stitchType: stitchType ?? this.stitchType,
    confidence: confidence.present ? confidence.value : this.confidence,
    needsReview: needsReview ?? this.needsReview,
    provenanceId: provenanceId.present ? provenanceId.value : this.provenanceId,
  );
  PatternCellRow copyWithCompanion(PatternCellsCompanion data) {
    return PatternCellRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      gridRow: data.gridRow.present ? data.gridRow.value : this.gridRow,
      gridColumn: data.gridColumn.present
          ? data.gridColumn.value
          : this.gridColumn,
      symbolId: data.symbolId.present ? data.symbolId.value : this.symbolId,
      stitchType: data.stitchType.present
          ? data.stitchType.value
          : this.stitchType,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      needsReview: data.needsReview.present
          ? data.needsReview.value
          : this.needsReview,
      provenanceId: data.provenanceId.present
          ? data.provenanceId.value
          : this.provenanceId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PatternCellRow(')
          ..write('documentId: $documentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('gridRow: $gridRow, ')
          ..write('gridColumn: $gridColumn, ')
          ..write('symbolId: $symbolId, ')
          ..write('stitchType: $stitchType, ')
          ..write('confidence: $confidence, ')
          ..write('needsReview: $needsReview, ')
          ..write('provenanceId: $provenanceId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    sortOrder,
    gridRow,
    gridColumn,
    symbolId,
    stitchType,
    confidence,
    needsReview,
    provenanceId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PatternCellRow &&
          other.documentId == this.documentId &&
          other.sortOrder == this.sortOrder &&
          other.gridRow == this.gridRow &&
          other.gridColumn == this.gridColumn &&
          other.symbolId == this.symbolId &&
          other.stitchType == this.stitchType &&
          other.confidence == this.confidence &&
          other.needsReview == this.needsReview &&
          other.provenanceId == this.provenanceId);
}

class PatternCellsCompanion extends UpdateCompanion<PatternCellRow> {
  final Value<String> documentId;
  final Value<int> sortOrder;
  final Value<int> gridRow;
  final Value<int> gridColumn;
  final Value<String> symbolId;
  final Value<String> stitchType;
  final Value<double?> confidence;
  final Value<bool> needsReview;
  final Value<String?> provenanceId;
  final Value<int> rowid;
  const PatternCellsCompanion({
    this.documentId = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.gridRow = const Value.absent(),
    this.gridColumn = const Value.absent(),
    this.symbolId = const Value.absent(),
    this.stitchType = const Value.absent(),
    this.confidence = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.provenanceId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PatternCellsCompanion.insert({
    required String documentId,
    required int sortOrder,
    required int gridRow,
    required int gridColumn,
    required String symbolId,
    required String stitchType,
    this.confidence = const Value.absent(),
    this.needsReview = const Value.absent(),
    this.provenanceId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       sortOrder = Value(sortOrder),
       gridRow = Value(gridRow),
       gridColumn = Value(gridColumn),
       symbolId = Value(symbolId),
       stitchType = Value(stitchType);
  static Insertable<PatternCellRow> custom({
    Expression<String>? documentId,
    Expression<int>? sortOrder,
    Expression<int>? gridRow,
    Expression<int>? gridColumn,
    Expression<String>? symbolId,
    Expression<String>? stitchType,
    Expression<double>? confidence,
    Expression<bool>? needsReview,
    Expression<String>? provenanceId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (gridRow != null) 'grid_row': gridRow,
      if (gridColumn != null) 'grid_column': gridColumn,
      if (symbolId != null) 'symbol_id': symbolId,
      if (stitchType != null) 'stitch_type': stitchType,
      if (confidence != null) 'confidence': confidence,
      if (needsReview != null) 'needs_review': needsReview,
      if (provenanceId != null) 'provenance_id': provenanceId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PatternCellsCompanion copyWith({
    Value<String>? documentId,
    Value<int>? sortOrder,
    Value<int>? gridRow,
    Value<int>? gridColumn,
    Value<String>? symbolId,
    Value<String>? stitchType,
    Value<double?>? confidence,
    Value<bool>? needsReview,
    Value<String?>? provenanceId,
    Value<int>? rowid,
  }) {
    return PatternCellsCompanion(
      documentId: documentId ?? this.documentId,
      sortOrder: sortOrder ?? this.sortOrder,
      gridRow: gridRow ?? this.gridRow,
      gridColumn: gridColumn ?? this.gridColumn,
      symbolId: symbolId ?? this.symbolId,
      stitchType: stitchType ?? this.stitchType,
      confidence: confidence ?? this.confidence,
      needsReview: needsReview ?? this.needsReview,
      provenanceId: provenanceId ?? this.provenanceId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (gridRow.present) {
      map['grid_row'] = Variable<int>(gridRow.value);
    }
    if (gridColumn.present) {
      map['grid_column'] = Variable<int>(gridColumn.value);
    }
    if (symbolId.present) {
      map['symbol_id'] = Variable<String>(symbolId.value);
    }
    if (stitchType.present) {
      map['stitch_type'] = Variable<String>(stitchType.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (needsReview.present) {
      map['needs_review'] = Variable<bool>(needsReview.value);
    }
    if (provenanceId.present) {
      map['provenance_id'] = Variable<String>(provenanceId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PatternCellsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('gridRow: $gridRow, ')
          ..write('gridColumn: $gridColumn, ')
          ..write('symbolId: $symbolId, ')
          ..write('stitchType: $stitchType, ')
          ..write('confidence: $confidence, ')
          ..write('needsReview: $needsReview, ')
          ..write('provenanceId: $provenanceId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ParserDiagnosticsTable extends ParserDiagnostics
    with TableInfo<$ParserDiagnosticsTable, ParserDiagnosticRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ParserDiagnosticsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _diagnosticIndexMeta = const VerificationMeta(
    'diagnosticIndex',
  );
  @override
  late final GeneratedColumn<int> diagnosticIndex = GeneratedColumn<int>(
    'diagnostic_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _severityMeta = const VerificationMeta(
    'severity',
  );
  @override
  late final GeneratedColumn<String> severity = GeneratedColumn<String>(
    'severity',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stageMeta = const VerificationMeta('stage');
  @override
  late final GeneratedColumn<String> stage = GeneratedColumn<String>(
    'stage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _messageMeta = const VerificationMeta(
    'message',
  );
  @override
  late final GeneratedColumn<String> message = GeneratedColumn<String>(
    'message',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridRowMeta = const VerificationMeta(
    'gridRow',
  );
  @override
  late final GeneratedColumn<int> gridRow = GeneratedColumn<int>(
    'grid_row',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gridColumnMeta = const VerificationMeta(
    'gridColumn',
  );
  @override
  late final GeneratedColumn<int> gridColumn = GeneratedColumn<int>(
    'grid_column',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourcePageMeta = const VerificationMeta(
    'sourcePage',
  );
  @override
  late final GeneratedColumn<int> sourcePage = GeneratedColumn<int>(
    'source_page',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _regionIdMeta = const VerificationMeta(
    'regionId',
  );
  @override
  late final GeneratedColumn<String> regionId = GeneratedColumn<String>(
    'region_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _confidenceMeta = const VerificationMeta(
    'confidence',
  );
  @override
  late final GeneratedColumn<double> confidence = GeneratedColumn<double>(
    'confidence',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _suggestedCorrectionMeta =
      const VerificationMeta('suggestedCorrection');
  @override
  late final GeneratedColumn<String> suggestedCorrection =
      GeneratedColumn<String>(
        'suggested_correction',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    diagnosticIndex,
    severity,
    stage,
    message,
    gridRow,
    gridColumn,
    sourcePage,
    regionId,
    confidence,
    suggestedCorrection,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'parser_diagnostics';
  @override
  VerificationContext validateIntegrity(
    Insertable<ParserDiagnosticRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('diagnostic_index')) {
      context.handle(
        _diagnosticIndexMeta,
        diagnosticIndex.isAcceptableOrUnknown(
          data['diagnostic_index']!,
          _diagnosticIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_diagnosticIndexMeta);
    }
    if (data.containsKey('severity')) {
      context.handle(
        _severityMeta,
        severity.isAcceptableOrUnknown(data['severity']!, _severityMeta),
      );
    } else if (isInserting) {
      context.missing(_severityMeta);
    }
    if (data.containsKey('stage')) {
      context.handle(
        _stageMeta,
        stage.isAcceptableOrUnknown(data['stage']!, _stageMeta),
      );
    } else if (isInserting) {
      context.missing(_stageMeta);
    }
    if (data.containsKey('message')) {
      context.handle(
        _messageMeta,
        message.isAcceptableOrUnknown(data['message']!, _messageMeta),
      );
    } else if (isInserting) {
      context.missing(_messageMeta);
    }
    if (data.containsKey('grid_row')) {
      context.handle(
        _gridRowMeta,
        gridRow.isAcceptableOrUnknown(data['grid_row']!, _gridRowMeta),
      );
    }
    if (data.containsKey('grid_column')) {
      context.handle(
        _gridColumnMeta,
        gridColumn.isAcceptableOrUnknown(data['grid_column']!, _gridColumnMeta),
      );
    }
    if (data.containsKey('source_page')) {
      context.handle(
        _sourcePageMeta,
        sourcePage.isAcceptableOrUnknown(data['source_page']!, _sourcePageMeta),
      );
    }
    if (data.containsKey('region_id')) {
      context.handle(
        _regionIdMeta,
        regionId.isAcceptableOrUnknown(data['region_id']!, _regionIdMeta),
      );
    }
    if (data.containsKey('confidence')) {
      context.handle(
        _confidenceMeta,
        confidence.isAcceptableOrUnknown(data['confidence']!, _confidenceMeta),
      );
    }
    if (data.containsKey('suggested_correction')) {
      context.handle(
        _suggestedCorrectionMeta,
        suggestedCorrection.isAcceptableOrUnknown(
          data['suggested_correction']!,
          _suggestedCorrectionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, diagnosticIndex};
  @override
  ParserDiagnosticRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ParserDiagnosticRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      diagnosticIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}diagnostic_index'],
      )!,
      severity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}severity'],
      )!,
      stage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}stage'],
      )!,
      message: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message'],
      )!,
      gridRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_row'],
      ),
      gridColumn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_column'],
      ),
      sourcePage: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}source_page'],
      ),
      regionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}region_id'],
      ),
      confidence: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}confidence'],
      ),
      suggestedCorrection: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}suggested_correction'],
      ),
    );
  }

  @override
  $ParserDiagnosticsTable createAlias(String alias) {
    return $ParserDiagnosticsTable(attachedDatabase, alias);
  }
}

class ParserDiagnosticRow extends DataClass
    implements Insertable<ParserDiagnosticRow> {
  /// Defines the parent pattern document.
  final String documentId;

  /// Preserves diagnostic order in the portable document.
  final int diagnosticIndex;

  /// Defines the user-facing diagnostic severity.
  final String severity;

  /// Defines the parser stage that produced the diagnostic.
  final String stage;

  /// Defines the user-safe diagnostic explanation.
  final String message;

  /// Defines the optional affected global grid row.
  final int? gridRow;

  /// Defines the optional affected global grid column.
  final int? gridColumn;

  /// Defines the optional affected zero-based source page.
  final int? sourcePage;

  /// Defines the optional affected provenance region.
  final String? regionId;

  /// Defines the optional normalized parser confidence.
  final double? confidence;

  /// Defines the optional action suggested to resolve the finding.
  final String? suggestedCorrection;
  const ParserDiagnosticRow({
    required this.documentId,
    required this.diagnosticIndex,
    required this.severity,
    required this.stage,
    required this.message,
    this.gridRow,
    this.gridColumn,
    this.sourcePage,
    this.regionId,
    this.confidence,
    this.suggestedCorrection,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['diagnostic_index'] = Variable<int>(diagnosticIndex);
    map['severity'] = Variable<String>(severity);
    map['stage'] = Variable<String>(stage);
    map['message'] = Variable<String>(message);
    if (!nullToAbsent || gridRow != null) {
      map['grid_row'] = Variable<int>(gridRow);
    }
    if (!nullToAbsent || gridColumn != null) {
      map['grid_column'] = Variable<int>(gridColumn);
    }
    if (!nullToAbsent || sourcePage != null) {
      map['source_page'] = Variable<int>(sourcePage);
    }
    if (!nullToAbsent || regionId != null) {
      map['region_id'] = Variable<String>(regionId);
    }
    if (!nullToAbsent || confidence != null) {
      map['confidence'] = Variable<double>(confidence);
    }
    if (!nullToAbsent || suggestedCorrection != null) {
      map['suggested_correction'] = Variable<String>(suggestedCorrection);
    }
    return map;
  }

  ParserDiagnosticsCompanion toCompanion(bool nullToAbsent) {
    return ParserDiagnosticsCompanion(
      documentId: Value(documentId),
      diagnosticIndex: Value(diagnosticIndex),
      severity: Value(severity),
      stage: Value(stage),
      message: Value(message),
      gridRow: gridRow == null && nullToAbsent
          ? const Value.absent()
          : Value(gridRow),
      gridColumn: gridColumn == null && nullToAbsent
          ? const Value.absent()
          : Value(gridColumn),
      sourcePage: sourcePage == null && nullToAbsent
          ? const Value.absent()
          : Value(sourcePage),
      regionId: regionId == null && nullToAbsent
          ? const Value.absent()
          : Value(regionId),
      confidence: confidence == null && nullToAbsent
          ? const Value.absent()
          : Value(confidence),
      suggestedCorrection: suggestedCorrection == null && nullToAbsent
          ? const Value.absent()
          : Value(suggestedCorrection),
    );
  }

  factory ParserDiagnosticRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ParserDiagnosticRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      diagnosticIndex: serializer.fromJson<int>(json['diagnosticIndex']),
      severity: serializer.fromJson<String>(json['severity']),
      stage: serializer.fromJson<String>(json['stage']),
      message: serializer.fromJson<String>(json['message']),
      gridRow: serializer.fromJson<int?>(json['gridRow']),
      gridColumn: serializer.fromJson<int?>(json['gridColumn']),
      sourcePage: serializer.fromJson<int?>(json['sourcePage']),
      regionId: serializer.fromJson<String?>(json['regionId']),
      confidence: serializer.fromJson<double?>(json['confidence']),
      suggestedCorrection: serializer.fromJson<String?>(
        json['suggestedCorrection'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'diagnosticIndex': serializer.toJson<int>(diagnosticIndex),
      'severity': serializer.toJson<String>(severity),
      'stage': serializer.toJson<String>(stage),
      'message': serializer.toJson<String>(message),
      'gridRow': serializer.toJson<int?>(gridRow),
      'gridColumn': serializer.toJson<int?>(gridColumn),
      'sourcePage': serializer.toJson<int?>(sourcePage),
      'regionId': serializer.toJson<String?>(regionId),
      'confidence': serializer.toJson<double?>(confidence),
      'suggestedCorrection': serializer.toJson<String?>(suggestedCorrection),
    };
  }

  ParserDiagnosticRow copyWith({
    String? documentId,
    int? diagnosticIndex,
    String? severity,
    String? stage,
    String? message,
    Value<int?> gridRow = const Value.absent(),
    Value<int?> gridColumn = const Value.absent(),
    Value<int?> sourcePage = const Value.absent(),
    Value<String?> regionId = const Value.absent(),
    Value<double?> confidence = const Value.absent(),
    Value<String?> suggestedCorrection = const Value.absent(),
  }) => ParserDiagnosticRow(
    documentId: documentId ?? this.documentId,
    diagnosticIndex: diagnosticIndex ?? this.diagnosticIndex,
    severity: severity ?? this.severity,
    stage: stage ?? this.stage,
    message: message ?? this.message,
    gridRow: gridRow.present ? gridRow.value : this.gridRow,
    gridColumn: gridColumn.present ? gridColumn.value : this.gridColumn,
    sourcePage: sourcePage.present ? sourcePage.value : this.sourcePage,
    regionId: regionId.present ? regionId.value : this.regionId,
    confidence: confidence.present ? confidence.value : this.confidence,
    suggestedCorrection: suggestedCorrection.present
        ? suggestedCorrection.value
        : this.suggestedCorrection,
  );
  ParserDiagnosticRow copyWithCompanion(ParserDiagnosticsCompanion data) {
    return ParserDiagnosticRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      diagnosticIndex: data.diagnosticIndex.present
          ? data.diagnosticIndex.value
          : this.diagnosticIndex,
      severity: data.severity.present ? data.severity.value : this.severity,
      stage: data.stage.present ? data.stage.value : this.stage,
      message: data.message.present ? data.message.value : this.message,
      gridRow: data.gridRow.present ? data.gridRow.value : this.gridRow,
      gridColumn: data.gridColumn.present
          ? data.gridColumn.value
          : this.gridColumn,
      sourcePage: data.sourcePage.present
          ? data.sourcePage.value
          : this.sourcePage,
      regionId: data.regionId.present ? data.regionId.value : this.regionId,
      confidence: data.confidence.present
          ? data.confidence.value
          : this.confidence,
      suggestedCorrection: data.suggestedCorrection.present
          ? data.suggestedCorrection.value
          : this.suggestedCorrection,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ParserDiagnosticRow(')
          ..write('documentId: $documentId, ')
          ..write('diagnosticIndex: $diagnosticIndex, ')
          ..write('severity: $severity, ')
          ..write('stage: $stage, ')
          ..write('message: $message, ')
          ..write('gridRow: $gridRow, ')
          ..write('gridColumn: $gridColumn, ')
          ..write('sourcePage: $sourcePage, ')
          ..write('regionId: $regionId, ')
          ..write('confidence: $confidence, ')
          ..write('suggestedCorrection: $suggestedCorrection')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    diagnosticIndex,
    severity,
    stage,
    message,
    gridRow,
    gridColumn,
    sourcePage,
    regionId,
    confidence,
    suggestedCorrection,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ParserDiagnosticRow &&
          other.documentId == this.documentId &&
          other.diagnosticIndex == this.diagnosticIndex &&
          other.severity == this.severity &&
          other.stage == this.stage &&
          other.message == this.message &&
          other.gridRow == this.gridRow &&
          other.gridColumn == this.gridColumn &&
          other.sourcePage == this.sourcePage &&
          other.regionId == this.regionId &&
          other.confidence == this.confidence &&
          other.suggestedCorrection == this.suggestedCorrection);
}

class ParserDiagnosticsCompanion extends UpdateCompanion<ParserDiagnosticRow> {
  final Value<String> documentId;
  final Value<int> diagnosticIndex;
  final Value<String> severity;
  final Value<String> stage;
  final Value<String> message;
  final Value<int?> gridRow;
  final Value<int?> gridColumn;
  final Value<int?> sourcePage;
  final Value<String?> regionId;
  final Value<double?> confidence;
  final Value<String?> suggestedCorrection;
  final Value<int> rowid;
  const ParserDiagnosticsCompanion({
    this.documentId = const Value.absent(),
    this.diagnosticIndex = const Value.absent(),
    this.severity = const Value.absent(),
    this.stage = const Value.absent(),
    this.message = const Value.absent(),
    this.gridRow = const Value.absent(),
    this.gridColumn = const Value.absent(),
    this.sourcePage = const Value.absent(),
    this.regionId = const Value.absent(),
    this.confidence = const Value.absent(),
    this.suggestedCorrection = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ParserDiagnosticsCompanion.insert({
    required String documentId,
    required int diagnosticIndex,
    required String severity,
    required String stage,
    required String message,
    this.gridRow = const Value.absent(),
    this.gridColumn = const Value.absent(),
    this.sourcePage = const Value.absent(),
    this.regionId = const Value.absent(),
    this.confidence = const Value.absent(),
    this.suggestedCorrection = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       diagnosticIndex = Value(diagnosticIndex),
       severity = Value(severity),
       stage = Value(stage),
       message = Value(message);
  static Insertable<ParserDiagnosticRow> custom({
    Expression<String>? documentId,
    Expression<int>? diagnosticIndex,
    Expression<String>? severity,
    Expression<String>? stage,
    Expression<String>? message,
    Expression<int>? gridRow,
    Expression<int>? gridColumn,
    Expression<int>? sourcePage,
    Expression<String>? regionId,
    Expression<double>? confidence,
    Expression<String>? suggestedCorrection,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (diagnosticIndex != null) 'diagnostic_index': diagnosticIndex,
      if (severity != null) 'severity': severity,
      if (stage != null) 'stage': stage,
      if (message != null) 'message': message,
      if (gridRow != null) 'grid_row': gridRow,
      if (gridColumn != null) 'grid_column': gridColumn,
      if (sourcePage != null) 'source_page': sourcePage,
      if (regionId != null) 'region_id': regionId,
      if (confidence != null) 'confidence': confidence,
      if (suggestedCorrection != null)
        'suggested_correction': suggestedCorrection,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ParserDiagnosticsCompanion copyWith({
    Value<String>? documentId,
    Value<int>? diagnosticIndex,
    Value<String>? severity,
    Value<String>? stage,
    Value<String>? message,
    Value<int?>? gridRow,
    Value<int?>? gridColumn,
    Value<int?>? sourcePage,
    Value<String?>? regionId,
    Value<double?>? confidence,
    Value<String?>? suggestedCorrection,
    Value<int>? rowid,
  }) {
    return ParserDiagnosticsCompanion(
      documentId: documentId ?? this.documentId,
      diagnosticIndex: diagnosticIndex ?? this.diagnosticIndex,
      severity: severity ?? this.severity,
      stage: stage ?? this.stage,
      message: message ?? this.message,
      gridRow: gridRow ?? this.gridRow,
      gridColumn: gridColumn ?? this.gridColumn,
      sourcePage: sourcePage ?? this.sourcePage,
      regionId: regionId ?? this.regionId,
      confidence: confidence ?? this.confidence,
      suggestedCorrection: suggestedCorrection ?? this.suggestedCorrection,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (diagnosticIndex.present) {
      map['diagnostic_index'] = Variable<int>(diagnosticIndex.value);
    }
    if (severity.present) {
      map['severity'] = Variable<String>(severity.value);
    }
    if (stage.present) {
      map['stage'] = Variable<String>(stage.value);
    }
    if (message.present) {
      map['message'] = Variable<String>(message.value);
    }
    if (gridRow.present) {
      map['grid_row'] = Variable<int>(gridRow.value);
    }
    if (gridColumn.present) {
      map['grid_column'] = Variable<int>(gridColumn.value);
    }
    if (sourcePage.present) {
      map['source_page'] = Variable<int>(sourcePage.value);
    }
    if (regionId.present) {
      map['region_id'] = Variable<String>(regionId.value);
    }
    if (confidence.present) {
      map['confidence'] = Variable<double>(confidence.value);
    }
    if (suggestedCorrection.present) {
      map['suggested_correction'] = Variable<String>(suggestedCorrection.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ParserDiagnosticsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('diagnosticIndex: $diagnosticIndex, ')
          ..write('severity: $severity, ')
          ..write('stage: $stage, ')
          ..write('message: $message, ')
          ..write('gridRow: $gridRow, ')
          ..write('gridColumn: $gridColumn, ')
          ..write('sourcePage: $sourcePage, ')
          ..write('regionId: $regionId, ')
          ..write('confidence: $confidence, ')
          ..write('suggestedCorrection: $suggestedCorrection, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressStatesTable extends ProgressStates
    with TableInfo<$ProgressStatesTable, ProgressStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pattern_documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  @override
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastInteractionAtMeta = const VerificationMeta(
    'lastInteractionAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastInteractionAt =
      GeneratedColumn<DateTime>(
        'last_interaction_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    schemaVersion,
    lastInteractionAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('last_interaction_at')) {
      context.handle(
        _lastInteractionAtMeta,
        lastInteractionAt.isAcceptableOrUnknown(
          data['last_interaction_at']!,
          _lastInteractionAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_lastInteractionAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  ProgressStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressStateRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      lastInteractionAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_interaction_at'],
      )!,
    );
  }

  @override
  $ProgressStatesTable createAlias(String alias) {
    return $ProgressStatesTable(attachedDatabase, alias);
  }
}

class ProgressStateRow extends DataClass
    implements Insertable<ProgressStateRow> {
  /// Defines the pattern document whose progress is stored.
  final String documentId;

  /// Defines the independent portable progress schema version.
  final int schemaVersion;

  /// Defines the UTC instant of the most recent progress interaction.
  final DateTime lastInteractionAt;
  const ProgressStateRow({
    required this.documentId,
    required this.schemaVersion,
    required this.lastInteractionAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['last_interaction_at'] = Variable<DateTime>(lastInteractionAt);
    return map;
  }

  ProgressStatesCompanion toCompanion(bool nullToAbsent) {
    return ProgressStatesCompanion(
      documentId: Value(documentId),
      schemaVersion: Value(schemaVersion),
      lastInteractionAt: Value(lastInteractionAt),
    );
  }

  factory ProgressStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressStateRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      schemaVersion: serializer.fromJson<int>(json['schemaVersion']),
      lastInteractionAt: serializer.fromJson<DateTime>(
        json['lastInteractionAt'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'schemaVersion': serializer.toJson<int>(schemaVersion),
      'lastInteractionAt': serializer.toJson<DateTime>(lastInteractionAt),
    };
  }

  ProgressStateRow copyWith({
    String? documentId,
    int? schemaVersion,
    DateTime? lastInteractionAt,
  }) => ProgressStateRow(
    documentId: documentId ?? this.documentId,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
  );
  ProgressStateRow copyWithCompanion(ProgressStatesCompanion data) {
    return ProgressStateRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      lastInteractionAt: data.lastInteractionAt.present
          ? data.lastInteractionAt.value
          : this.lastInteractionAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressStateRow(')
          ..write('documentId: $documentId, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('lastInteractionAt: $lastInteractionAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentId, schemaVersion, lastInteractionAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressStateRow &&
          other.documentId == this.documentId &&
          other.schemaVersion == this.schemaVersion &&
          other.lastInteractionAt == this.lastInteractionAt);
}

class ProgressStatesCompanion extends UpdateCompanion<ProgressStateRow> {
  final Value<String> documentId;
  final Value<int> schemaVersion;
  final Value<DateTime> lastInteractionAt;
  final Value<int> rowid;
  const ProgressStatesCompanion({
    this.documentId = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.lastInteractionAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressStatesCompanion.insert({
    required String documentId,
    required int schemaVersion,
    required DateTime lastInteractionAt,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       schemaVersion = Value(schemaVersion),
       lastInteractionAt = Value(lastInteractionAt);
  static Insertable<ProgressStateRow> custom({
    Expression<String>? documentId,
    Expression<int>? schemaVersion,
    Expression<DateTime>? lastInteractionAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (lastInteractionAt != null) 'last_interaction_at': lastInteractionAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressStatesCompanion copyWith({
    Value<String>? documentId,
    Value<int>? schemaVersion,
    Value<DateTime>? lastInteractionAt,
    Value<int>? rowid,
  }) {
    return ProgressStatesCompanion(
      documentId: documentId ?? this.documentId,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      lastInteractionAt: lastInteractionAt ?? this.lastInteractionAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (lastInteractionAt.present) {
      map['last_interaction_at'] = Variable<DateTime>(lastInteractionAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressStatesCompanion(')
          ..write('documentId: $documentId, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('lastInteractionAt: $lastInteractionAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CompletedCellsTable extends CompletedCells
    with TableInfo<$CompletedCellsTable, CompletedCellRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CompletedCellsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridRowMeta = const VerificationMeta(
    'gridRow',
  );
  @override
  late final GeneratedColumn<int> gridRow = GeneratedColumn<int>(
    'grid_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridColumnMeta = const VerificationMeta(
    'gridColumn',
  );
  @override
  late final GeneratedColumn<int> gridColumn = GeneratedColumn<int>(
    'grid_column',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [documentId, gridRow, gridColumn];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'completed_cells';
  @override
  VerificationContext validateIntegrity(
    Insertable<CompletedCellRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('grid_row')) {
      context.handle(
        _gridRowMeta,
        gridRow.isAcceptableOrUnknown(data['grid_row']!, _gridRowMeta),
      );
    } else if (isInserting) {
      context.missing(_gridRowMeta);
    }
    if (data.containsKey('grid_column')) {
      context.handle(
        _gridColumnMeta,
        gridColumn.isAcceptableOrUnknown(data['grid_column']!, _gridColumnMeta),
      );
    } else if (isInserting) {
      context.missing(_gridColumnMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, gridRow, gridColumn};
  @override
  CompletedCellRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CompletedCellRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      gridRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_row'],
      )!,
      gridColumn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_column'],
      )!,
    );
  }

  @override
  $CompletedCellsTable createAlias(String alias) {
    return $CompletedCellsTable(attachedDatabase, alias);
  }
}

class CompletedCellRow extends DataClass
    implements Insertable<CompletedCellRow> {
  /// Defines the parent progress record and pattern document.
  final String documentId;

  /// Defines the zero-based global grid row.
  final int gridRow;

  /// Defines the zero-based global grid column.
  final int gridColumn;
  const CompletedCellRow({
    required this.documentId,
    required this.gridRow,
    required this.gridColumn,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['grid_row'] = Variable<int>(gridRow);
    map['grid_column'] = Variable<int>(gridColumn);
    return map;
  }

  CompletedCellsCompanion toCompanion(bool nullToAbsent) {
    return CompletedCellsCompanion(
      documentId: Value(documentId),
      gridRow: Value(gridRow),
      gridColumn: Value(gridColumn),
    );
  }

  factory CompletedCellRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CompletedCellRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      gridRow: serializer.fromJson<int>(json['gridRow']),
      gridColumn: serializer.fromJson<int>(json['gridColumn']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'gridRow': serializer.toJson<int>(gridRow),
      'gridColumn': serializer.toJson<int>(gridColumn),
    };
  }

  CompletedCellRow copyWith({
    String? documentId,
    int? gridRow,
    int? gridColumn,
  }) => CompletedCellRow(
    documentId: documentId ?? this.documentId,
    gridRow: gridRow ?? this.gridRow,
    gridColumn: gridColumn ?? this.gridColumn,
  );
  CompletedCellRow copyWithCompanion(CompletedCellsCompanion data) {
    return CompletedCellRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      gridRow: data.gridRow.present ? data.gridRow.value : this.gridRow,
      gridColumn: data.gridColumn.present
          ? data.gridColumn.value
          : this.gridColumn,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CompletedCellRow(')
          ..write('documentId: $documentId, ')
          ..write('gridRow: $gridRow, ')
          ..write('gridColumn: $gridColumn')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(documentId, gridRow, gridColumn);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CompletedCellRow &&
          other.documentId == this.documentId &&
          other.gridRow == this.gridRow &&
          other.gridColumn == this.gridColumn);
}

class CompletedCellsCompanion extends UpdateCompanion<CompletedCellRow> {
  final Value<String> documentId;
  final Value<int> gridRow;
  final Value<int> gridColumn;
  final Value<int> rowid;
  const CompletedCellsCompanion({
    this.documentId = const Value.absent(),
    this.gridRow = const Value.absent(),
    this.gridColumn = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CompletedCellsCompanion.insert({
    required String documentId,
    required int gridRow,
    required int gridColumn,
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       gridRow = Value(gridRow),
       gridColumn = Value(gridColumn);
  static Insertable<CompletedCellRow> custom({
    Expression<String>? documentId,
    Expression<int>? gridRow,
    Expression<int>? gridColumn,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (gridRow != null) 'grid_row': gridRow,
      if (gridColumn != null) 'grid_column': gridColumn,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CompletedCellsCompanion copyWith({
    Value<String>? documentId,
    Value<int>? gridRow,
    Value<int>? gridColumn,
    Value<int>? rowid,
  }) {
    return CompletedCellsCompanion(
      documentId: documentId ?? this.documentId,
      gridRow: gridRow ?? this.gridRow,
      gridColumn: gridColumn ?? this.gridColumn,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (gridRow.present) {
      map['grid_row'] = Variable<int>(gridRow.value);
    }
    if (gridColumn.present) {
      map['grid_column'] = Variable<int>(gridColumn.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CompletedCellsCompanion(')
          ..write('documentId: $documentId, ')
          ..write('gridRow: $gridRow, ')
          ..write('gridColumn: $gridColumn, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocationMarkersTable extends LocationMarkers
    with TableInfo<$LocationMarkersTable, LocationMarkerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocationMarkersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridRowMeta = const VerificationMeta(
    'gridRow',
  );
  @override
  late final GeneratedColumn<int> gridRow = GeneratedColumn<int>(
    'grid_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gridColumnMeta = const VerificationMeta(
    'gridColumn',
  );
  @override
  late final GeneratedColumn<int> gridColumn = GeneratedColumn<int>(
    'grid_column',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  @override
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _opacityMeta = const VerificationMeta(
    'opacity',
  );
  @override
  late final GeneratedColumn<double> opacity = GeneratedColumn<double>(
    'opacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibleMeta = const VerificationMeta(
    'visible',
  );
  @override
  late final GeneratedColumn<bool> visible = GeneratedColumn<bool>(
    'visible',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("visible" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    id,
    sortOrder,
    gridRow,
    gridColumn,
    label,
    color,
    opacity,
    visible,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'location_markers';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocationMarkerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('grid_row')) {
      context.handle(
        _gridRowMeta,
        gridRow.isAcceptableOrUnknown(data['grid_row']!, _gridRowMeta),
      );
    } else if (isInserting) {
      context.missing(_gridRowMeta);
    }
    if (data.containsKey('grid_column')) {
      context.handle(
        _gridColumnMeta,
        gridColumn.isAcceptableOrUnknown(data['grid_column']!, _gridColumnMeta),
      );
    } else if (isInserting) {
      context.missing(_gridColumnMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    } else if (isInserting) {
      context.missing(_colorMeta);
    }
    if (data.containsKey('opacity')) {
      context.handle(
        _opacityMeta,
        opacity.isAcceptableOrUnknown(data['opacity']!, _opacityMeta),
      );
    } else if (isInserting) {
      context.missing(_opacityMeta);
    }
    if (data.containsKey('visible')) {
      context.handle(
        _visibleMeta,
        visible.isAcceptableOrUnknown(data['visible']!, _visibleMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId, id};
  @override
  LocationMarkerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocationMarkerRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      gridRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_row'],
      )!,
      gridColumn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}grid_column'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      )!,
      opacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}opacity'],
      )!,
      visible: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}visible'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $LocationMarkersTable createAlias(String alias) {
    return $LocationMarkersTable(attachedDatabase, alias);
  }
}

class LocationMarkerRow extends DataClass
    implements Insertable<LocationMarkerRow> {
  /// Defines the parent progress record and pattern document.
  final String documentId;

  /// Defines the stable marker identifier within the progress record.
  final String id;

  /// Preserves marker order in the portable progress document.
  final int sortOrder;

  /// Defines the zero-based global anchor row.
  final int gridRow;

  /// Defines the zero-based global anchor column.
  final int gridColumn;

  /// Defines the user-facing marker label.
  final String label;

  /// Defines the marker color in canonical `#RRGGBB` notation.
  final String color;

  /// Defines marker transparency from zero through one.
  final double opacity;

  /// Defines whether the marker is visible in the workspace.
  final bool visible;

  /// Defines an optional user note associated with the marker.
  final String? note;
  const LocationMarkerRow({
    required this.documentId,
    required this.id,
    required this.sortOrder,
    required this.gridRow,
    required this.gridColumn,
    required this.label,
    required this.color,
    required this.opacity,
    required this.visible,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['id'] = Variable<String>(id);
    map['sort_order'] = Variable<int>(sortOrder);
    map['grid_row'] = Variable<int>(gridRow);
    map['grid_column'] = Variable<int>(gridColumn);
    map['label'] = Variable<String>(label);
    map['color'] = Variable<String>(color);
    map['opacity'] = Variable<double>(opacity);
    map['visible'] = Variable<bool>(visible);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  LocationMarkersCompanion toCompanion(bool nullToAbsent) {
    return LocationMarkersCompanion(
      documentId: Value(documentId),
      id: Value(id),
      sortOrder: Value(sortOrder),
      gridRow: Value(gridRow),
      gridColumn: Value(gridColumn),
      label: Value(label),
      color: Value(color),
      opacity: Value(opacity),
      visible: Value(visible),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory LocationMarkerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocationMarkerRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      id: serializer.fromJson<String>(json['id']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      gridRow: serializer.fromJson<int>(json['gridRow']),
      gridColumn: serializer.fromJson<int>(json['gridColumn']),
      label: serializer.fromJson<String>(json['label']),
      color: serializer.fromJson<String>(json['color']),
      opacity: serializer.fromJson<double>(json['opacity']),
      visible: serializer.fromJson<bool>(json['visible']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'id': serializer.toJson<String>(id),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'gridRow': serializer.toJson<int>(gridRow),
      'gridColumn': serializer.toJson<int>(gridColumn),
      'label': serializer.toJson<String>(label),
      'color': serializer.toJson<String>(color),
      'opacity': serializer.toJson<double>(opacity),
      'visible': serializer.toJson<bool>(visible),
      'note': serializer.toJson<String?>(note),
    };
  }

  LocationMarkerRow copyWith({
    String? documentId,
    String? id,
    int? sortOrder,
    int? gridRow,
    int? gridColumn,
    String? label,
    String? color,
    double? opacity,
    bool? visible,
    Value<String?> note = const Value.absent(),
  }) => LocationMarkerRow(
    documentId: documentId ?? this.documentId,
    id: id ?? this.id,
    sortOrder: sortOrder ?? this.sortOrder,
    gridRow: gridRow ?? this.gridRow,
    gridColumn: gridColumn ?? this.gridColumn,
    label: label ?? this.label,
    color: color ?? this.color,
    opacity: opacity ?? this.opacity,
    visible: visible ?? this.visible,
    note: note.present ? note.value : this.note,
  );
  LocationMarkerRow copyWithCompanion(LocationMarkersCompanion data) {
    return LocationMarkerRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      id: data.id.present ? data.id.value : this.id,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      gridRow: data.gridRow.present ? data.gridRow.value : this.gridRow,
      gridColumn: data.gridColumn.present
          ? data.gridColumn.value
          : this.gridColumn,
      label: data.label.present ? data.label.value : this.label,
      color: data.color.present ? data.color.value : this.color,
      opacity: data.opacity.present ? data.opacity.value : this.opacity,
      visible: data.visible.present ? data.visible.value : this.visible,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocationMarkerRow(')
          ..write('documentId: $documentId, ')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('gridRow: $gridRow, ')
          ..write('gridColumn: $gridColumn, ')
          ..write('label: $label, ')
          ..write('color: $color, ')
          ..write('opacity: $opacity, ')
          ..write('visible: $visible, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    id,
    sortOrder,
    gridRow,
    gridColumn,
    label,
    color,
    opacity,
    visible,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocationMarkerRow &&
          other.documentId == this.documentId &&
          other.id == this.id &&
          other.sortOrder == this.sortOrder &&
          other.gridRow == this.gridRow &&
          other.gridColumn == this.gridColumn &&
          other.label == this.label &&
          other.color == this.color &&
          other.opacity == this.opacity &&
          other.visible == this.visible &&
          other.note == this.note);
}

class LocationMarkersCompanion extends UpdateCompanion<LocationMarkerRow> {
  final Value<String> documentId;
  final Value<String> id;
  final Value<int> sortOrder;
  final Value<int> gridRow;
  final Value<int> gridColumn;
  final Value<String> label;
  final Value<String> color;
  final Value<double> opacity;
  final Value<bool> visible;
  final Value<String?> note;
  final Value<int> rowid;
  const LocationMarkersCompanion({
    this.documentId = const Value.absent(),
    this.id = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.gridRow = const Value.absent(),
    this.gridColumn = const Value.absent(),
    this.label = const Value.absent(),
    this.color = const Value.absent(),
    this.opacity = const Value.absent(),
    this.visible = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocationMarkersCompanion.insert({
    required String documentId,
    required String id,
    required int sortOrder,
    required int gridRow,
    required int gridColumn,
    required String label,
    required String color,
    required double opacity,
    this.visible = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       id = Value(id),
       sortOrder = Value(sortOrder),
       gridRow = Value(gridRow),
       gridColumn = Value(gridColumn),
       label = Value(label),
       color = Value(color),
       opacity = Value(opacity);
  static Insertable<LocationMarkerRow> custom({
    Expression<String>? documentId,
    Expression<String>? id,
    Expression<int>? sortOrder,
    Expression<int>? gridRow,
    Expression<int>? gridColumn,
    Expression<String>? label,
    Expression<String>? color,
    Expression<double>? opacity,
    Expression<bool>? visible,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (id != null) 'id': id,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (gridRow != null) 'grid_row': gridRow,
      if (gridColumn != null) 'grid_column': gridColumn,
      if (label != null) 'label': label,
      if (color != null) 'color': color,
      if (opacity != null) 'opacity': opacity,
      if (visible != null) 'visible': visible,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocationMarkersCompanion copyWith({
    Value<String>? documentId,
    Value<String>? id,
    Value<int>? sortOrder,
    Value<int>? gridRow,
    Value<int>? gridColumn,
    Value<String>? label,
    Value<String>? color,
    Value<double>? opacity,
    Value<bool>? visible,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return LocationMarkersCompanion(
      documentId: documentId ?? this.documentId,
      id: id ?? this.id,
      sortOrder: sortOrder ?? this.sortOrder,
      gridRow: gridRow ?? this.gridRow,
      gridColumn: gridColumn ?? this.gridColumn,
      label: label ?? this.label,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      visible: visible ?? this.visible,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (gridRow.present) {
      map['grid_row'] = Variable<int>(gridRow.value);
    }
    if (gridColumn.present) {
      map['grid_column'] = Variable<int>(gridColumn.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (opacity.present) {
      map['opacity'] = Variable<double>(opacity.value);
    }
    if (visible.present) {
      map['visible'] = Variable<bool>(visible.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocationMarkersCompanion(')
          ..write('documentId: $documentId, ')
          ..write('id: $id, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('gridRow: $gridRow, ')
          ..write('gridColumn: $gridColumn, ')
          ..write('label: $label, ')
          ..write('color: $color, ')
          ..write('opacity: $opacity, ')
          ..write('visible: $visible, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ViewportStatesTable extends ViewportStates
    with TableInfo<$ViewportStatesTable, ViewportStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ViewportStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _zoomMeta = const VerificationMeta('zoom');
  @override
  late final GeneratedColumn<double> zoom = GeneratedColumn<double>(
    'zoom',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _panXMeta = const VerificationMeta('panX');
  @override
  late final GeneratedColumn<double> panX = GeneratedColumn<double>(
    'pan_x',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _panYMeta = const VerificationMeta('panY');
  @override
  late final GeneratedColumn<double> panY = GeneratedColumn<double>(
    'pan_y',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorRowMeta = const VerificationMeta(
    'anchorRow',
  );
  @override
  late final GeneratedColumn<int> anchorRow = GeneratedColumn<int>(
    'anchor_row',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorColumnMeta = const VerificationMeta(
    'anchorColumn',
  );
  @override
  late final GeneratedColumn<int> anchorColumn = GeneratedColumn<int>(
    'anchor_column',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _visibleRowsMeta = const VerificationMeta(
    'visibleRows',
  );
  @override
  late final GeneratedColumn<int> visibleRows = GeneratedColumn<int>(
    'visible_rows',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _visibleColumnsMeta = const VerificationMeta(
    'visibleColumns',
  );
  @override
  late final GeneratedColumn<int> visibleColumns = GeneratedColumn<int>(
    'visible_columns',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _showCellColorMeta = const VerificationMeta(
    'showCellColor',
  );
  @override
  late final GeneratedColumn<bool> showCellColor = GeneratedColumn<bool>(
    'show_cell_color',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_cell_color" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _showSymbolsMeta = const VerificationMeta(
    'showSymbols',
  );
  @override
  late final GeneratedColumn<bool> showSymbols = GeneratedColumn<bool>(
    'show_symbols',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_symbols" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _showGridMeta = const VerificationMeta(
    'showGrid',
  );
  @override
  late final GeneratedColumn<bool> showGrid = GeneratedColumn<bool>(
    'show_grid',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_grid" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _cellColorOpacityMeta = const VerificationMeta(
    'cellColorOpacity',
  );
  @override
  late final GeneratedColumn<double> cellColorOpacity = GeneratedColumn<double>(
    'cell_color_opacity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.22),
  );
  static const VerificationMeta _gridColorMeta = const VerificationMeta(
    'gridColor',
  );
  @override
  late final GeneratedColumn<String> gridColor = GeneratedColumn<String>(
    'grid_color',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#000000'),
  );
  static const VerificationMeta _showRegionsMeta = const VerificationMeta(
    'showRegions',
  );
  @override
  late final GeneratedColumn<bool> showRegions = GeneratedColumn<bool>(
    'show_regions',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_regions" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    documentId,
    zoom,
    panX,
    panY,
    anchorRow,
    anchorColumn,
    visibleRows,
    visibleColumns,
    showCellColor,
    showSymbols,
    showGrid,
    cellColorOpacity,
    gridColor,
    showRegions,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'viewport_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<ViewportStateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('zoom')) {
      context.handle(
        _zoomMeta,
        zoom.isAcceptableOrUnknown(data['zoom']!, _zoomMeta),
      );
    } else if (isInserting) {
      context.missing(_zoomMeta);
    }
    if (data.containsKey('pan_x')) {
      context.handle(
        _panXMeta,
        panX.isAcceptableOrUnknown(data['pan_x']!, _panXMeta),
      );
    } else if (isInserting) {
      context.missing(_panXMeta);
    }
    if (data.containsKey('pan_y')) {
      context.handle(
        _panYMeta,
        panY.isAcceptableOrUnknown(data['pan_y']!, _panYMeta),
      );
    } else if (isInserting) {
      context.missing(_panYMeta);
    }
    if (data.containsKey('anchor_row')) {
      context.handle(
        _anchorRowMeta,
        anchorRow.isAcceptableOrUnknown(data['anchor_row']!, _anchorRowMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorRowMeta);
    }
    if (data.containsKey('anchor_column')) {
      context.handle(
        _anchorColumnMeta,
        anchorColumn.isAcceptableOrUnknown(
          data['anchor_column']!,
          _anchorColumnMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_anchorColumnMeta);
    }
    if (data.containsKey('visible_rows')) {
      context.handle(
        _visibleRowsMeta,
        visibleRows.isAcceptableOrUnknown(
          data['visible_rows']!,
          _visibleRowsMeta,
        ),
      );
    }
    if (data.containsKey('visible_columns')) {
      context.handle(
        _visibleColumnsMeta,
        visibleColumns.isAcceptableOrUnknown(
          data['visible_columns']!,
          _visibleColumnsMeta,
        ),
      );
    }
    if (data.containsKey('show_cell_color')) {
      context.handle(
        _showCellColorMeta,
        showCellColor.isAcceptableOrUnknown(
          data['show_cell_color']!,
          _showCellColorMeta,
        ),
      );
    }
    if (data.containsKey('show_symbols')) {
      context.handle(
        _showSymbolsMeta,
        showSymbols.isAcceptableOrUnknown(
          data['show_symbols']!,
          _showSymbolsMeta,
        ),
      );
    }
    if (data.containsKey('show_grid')) {
      context.handle(
        _showGridMeta,
        showGrid.isAcceptableOrUnknown(data['show_grid']!, _showGridMeta),
      );
    }
    if (data.containsKey('cell_color_opacity')) {
      context.handle(
        _cellColorOpacityMeta,
        cellColorOpacity.isAcceptableOrUnknown(
          data['cell_color_opacity']!,
          _cellColorOpacityMeta,
        ),
      );
    }
    if (data.containsKey('grid_color')) {
      context.handle(
        _gridColorMeta,
        gridColor.isAcceptableOrUnknown(data['grid_color']!, _gridColorMeta),
      );
    }
    if (data.containsKey('show_regions')) {
      context.handle(
        _showRegionsMeta,
        showRegions.isAcceptableOrUnknown(
          data['show_regions']!,
          _showRegionsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {documentId};
  @override
  ViewportStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ViewportStateRow(
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      zoom: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zoom'],
      )!,
      panX: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pan_x'],
      )!,
      panY: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pan_y'],
      )!,
      anchorRow: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anchor_row'],
      )!,
      anchorColumn: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}anchor_column'],
      )!,
      visibleRows: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}visible_rows'],
      ),
      visibleColumns: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}visible_columns'],
      ),
      showCellColor: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_cell_color'],
      )!,
      showSymbols: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_symbols'],
      )!,
      showGrid: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_grid'],
      )!,
      cellColorOpacity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cell_color_opacity'],
      )!,
      gridColor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grid_color'],
      )!,
      showRegions: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_regions'],
      )!,
    );
  }

  @override
  $ViewportStatesTable createAlias(String alias) {
    return $ViewportStatesTable(attachedDatabase, alias);
  }
}

class ViewportStateRow extends DataClass
    implements Insertable<ViewportStateRow> {
  /// Defines the parent progress record and pattern document.
  final String documentId;

  /// Defines the positive renderer scale factor.
  final double zoom;

  /// Defines the finite horizontal renderer offset.
  final double panX;

  /// Defines the finite vertical renderer offset.
  final double panY;

  /// Defines the stable zero-based anchor row.
  final int anchorRow;

  /// Defines the stable zero-based anchor column.
  final int anchorColumn;

  /// Defines the optional number of visible rows at save time.
  final int? visibleRows;

  /// Defines the optional number of visible columns at save time.
  final int? visibleColumns;

  /// Defines whether populated cells use their imported thread colors.
  final bool showCellColor;

  /// Defines whether legible populated cells display symbol glyphs.
  final bool showSymbols;

  /// Defines whether grid rules are visible.
  final bool showGrid;

  /// Defines thread-color fill opacity from zero through one.
  final double cellColorOpacity;

  /// Defines the canonical RGB value of the selected grid-color preset.
  final String gridColor;

  /// Defines whether source-region outlines are visible.
  final bool showRegions;
  const ViewportStateRow({
    required this.documentId,
    required this.zoom,
    required this.panX,
    required this.panY,
    required this.anchorRow,
    required this.anchorColumn,
    this.visibleRows,
    this.visibleColumns,
    required this.showCellColor,
    required this.showSymbols,
    required this.showGrid,
    required this.cellColorOpacity,
    required this.gridColor,
    required this.showRegions,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['document_id'] = Variable<String>(documentId);
    map['zoom'] = Variable<double>(zoom);
    map['pan_x'] = Variable<double>(panX);
    map['pan_y'] = Variable<double>(panY);
    map['anchor_row'] = Variable<int>(anchorRow);
    map['anchor_column'] = Variable<int>(anchorColumn);
    if (!nullToAbsent || visibleRows != null) {
      map['visible_rows'] = Variable<int>(visibleRows);
    }
    if (!nullToAbsent || visibleColumns != null) {
      map['visible_columns'] = Variable<int>(visibleColumns);
    }
    map['show_cell_color'] = Variable<bool>(showCellColor);
    map['show_symbols'] = Variable<bool>(showSymbols);
    map['show_grid'] = Variable<bool>(showGrid);
    map['cell_color_opacity'] = Variable<double>(cellColorOpacity);
    map['grid_color'] = Variable<String>(gridColor);
    map['show_regions'] = Variable<bool>(showRegions);
    return map;
  }

  ViewportStatesCompanion toCompanion(bool nullToAbsent) {
    return ViewportStatesCompanion(
      documentId: Value(documentId),
      zoom: Value(zoom),
      panX: Value(panX),
      panY: Value(panY),
      anchorRow: Value(anchorRow),
      anchorColumn: Value(anchorColumn),
      visibleRows: visibleRows == null && nullToAbsent
          ? const Value.absent()
          : Value(visibleRows),
      visibleColumns: visibleColumns == null && nullToAbsent
          ? const Value.absent()
          : Value(visibleColumns),
      showCellColor: Value(showCellColor),
      showSymbols: Value(showSymbols),
      showGrid: Value(showGrid),
      cellColorOpacity: Value(cellColorOpacity),
      gridColor: Value(gridColor),
      showRegions: Value(showRegions),
    );
  }

  factory ViewportStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ViewportStateRow(
      documentId: serializer.fromJson<String>(json['documentId']),
      zoom: serializer.fromJson<double>(json['zoom']),
      panX: serializer.fromJson<double>(json['panX']),
      panY: serializer.fromJson<double>(json['panY']),
      anchorRow: serializer.fromJson<int>(json['anchorRow']),
      anchorColumn: serializer.fromJson<int>(json['anchorColumn']),
      visibleRows: serializer.fromJson<int?>(json['visibleRows']),
      visibleColumns: serializer.fromJson<int?>(json['visibleColumns']),
      showCellColor: serializer.fromJson<bool>(json['showCellColor']),
      showSymbols: serializer.fromJson<bool>(json['showSymbols']),
      showGrid: serializer.fromJson<bool>(json['showGrid']),
      cellColorOpacity: serializer.fromJson<double>(json['cellColorOpacity']),
      gridColor: serializer.fromJson<String>(json['gridColor']),
      showRegions: serializer.fromJson<bool>(json['showRegions']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'documentId': serializer.toJson<String>(documentId),
      'zoom': serializer.toJson<double>(zoom),
      'panX': serializer.toJson<double>(panX),
      'panY': serializer.toJson<double>(panY),
      'anchorRow': serializer.toJson<int>(anchorRow),
      'anchorColumn': serializer.toJson<int>(anchorColumn),
      'visibleRows': serializer.toJson<int?>(visibleRows),
      'visibleColumns': serializer.toJson<int?>(visibleColumns),
      'showCellColor': serializer.toJson<bool>(showCellColor),
      'showSymbols': serializer.toJson<bool>(showSymbols),
      'showGrid': serializer.toJson<bool>(showGrid),
      'cellColorOpacity': serializer.toJson<double>(cellColorOpacity),
      'gridColor': serializer.toJson<String>(gridColor),
      'showRegions': serializer.toJson<bool>(showRegions),
    };
  }

  ViewportStateRow copyWith({
    String? documentId,
    double? zoom,
    double? panX,
    double? panY,
    int? anchorRow,
    int? anchorColumn,
    Value<int?> visibleRows = const Value.absent(),
    Value<int?> visibleColumns = const Value.absent(),
    bool? showCellColor,
    bool? showSymbols,
    bool? showGrid,
    double? cellColorOpacity,
    String? gridColor,
    bool? showRegions,
  }) => ViewportStateRow(
    documentId: documentId ?? this.documentId,
    zoom: zoom ?? this.zoom,
    panX: panX ?? this.panX,
    panY: panY ?? this.panY,
    anchorRow: anchorRow ?? this.anchorRow,
    anchorColumn: anchorColumn ?? this.anchorColumn,
    visibleRows: visibleRows.present ? visibleRows.value : this.visibleRows,
    visibleColumns: visibleColumns.present
        ? visibleColumns.value
        : this.visibleColumns,
    showCellColor: showCellColor ?? this.showCellColor,
    showSymbols: showSymbols ?? this.showSymbols,
    showGrid: showGrid ?? this.showGrid,
    cellColorOpacity: cellColorOpacity ?? this.cellColorOpacity,
    gridColor: gridColor ?? this.gridColor,
    showRegions: showRegions ?? this.showRegions,
  );
  ViewportStateRow copyWithCompanion(ViewportStatesCompanion data) {
    return ViewportStateRow(
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      zoom: data.zoom.present ? data.zoom.value : this.zoom,
      panX: data.panX.present ? data.panX.value : this.panX,
      panY: data.panY.present ? data.panY.value : this.panY,
      anchorRow: data.anchorRow.present ? data.anchorRow.value : this.anchorRow,
      anchorColumn: data.anchorColumn.present
          ? data.anchorColumn.value
          : this.anchorColumn,
      visibleRows: data.visibleRows.present
          ? data.visibleRows.value
          : this.visibleRows,
      visibleColumns: data.visibleColumns.present
          ? data.visibleColumns.value
          : this.visibleColumns,
      showCellColor: data.showCellColor.present
          ? data.showCellColor.value
          : this.showCellColor,
      showSymbols: data.showSymbols.present
          ? data.showSymbols.value
          : this.showSymbols,
      showGrid: data.showGrid.present ? data.showGrid.value : this.showGrid,
      cellColorOpacity: data.cellColorOpacity.present
          ? data.cellColorOpacity.value
          : this.cellColorOpacity,
      gridColor: data.gridColor.present ? data.gridColor.value : this.gridColor,
      showRegions: data.showRegions.present
          ? data.showRegions.value
          : this.showRegions,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ViewportStateRow(')
          ..write('documentId: $documentId, ')
          ..write('zoom: $zoom, ')
          ..write('panX: $panX, ')
          ..write('panY: $panY, ')
          ..write('anchorRow: $anchorRow, ')
          ..write('anchorColumn: $anchorColumn, ')
          ..write('visibleRows: $visibleRows, ')
          ..write('visibleColumns: $visibleColumns, ')
          ..write('showCellColor: $showCellColor, ')
          ..write('showSymbols: $showSymbols, ')
          ..write('showGrid: $showGrid, ')
          ..write('cellColorOpacity: $cellColorOpacity, ')
          ..write('gridColor: $gridColor, ')
          ..write('showRegions: $showRegions')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    documentId,
    zoom,
    panX,
    panY,
    anchorRow,
    anchorColumn,
    visibleRows,
    visibleColumns,
    showCellColor,
    showSymbols,
    showGrid,
    cellColorOpacity,
    gridColor,
    showRegions,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ViewportStateRow &&
          other.documentId == this.documentId &&
          other.zoom == this.zoom &&
          other.panX == this.panX &&
          other.panY == this.panY &&
          other.anchorRow == this.anchorRow &&
          other.anchorColumn == this.anchorColumn &&
          other.visibleRows == this.visibleRows &&
          other.visibleColumns == this.visibleColumns &&
          other.showCellColor == this.showCellColor &&
          other.showSymbols == this.showSymbols &&
          other.showGrid == this.showGrid &&
          other.cellColorOpacity == this.cellColorOpacity &&
          other.gridColor == this.gridColor &&
          other.showRegions == this.showRegions);
}

class ViewportStatesCompanion extends UpdateCompanion<ViewportStateRow> {
  final Value<String> documentId;
  final Value<double> zoom;
  final Value<double> panX;
  final Value<double> panY;
  final Value<int> anchorRow;
  final Value<int> anchorColumn;
  final Value<int?> visibleRows;
  final Value<int?> visibleColumns;
  final Value<bool> showCellColor;
  final Value<bool> showSymbols;
  final Value<bool> showGrid;
  final Value<double> cellColorOpacity;
  final Value<String> gridColor;
  final Value<bool> showRegions;
  final Value<int> rowid;
  const ViewportStatesCompanion({
    this.documentId = const Value.absent(),
    this.zoom = const Value.absent(),
    this.panX = const Value.absent(),
    this.panY = const Value.absent(),
    this.anchorRow = const Value.absent(),
    this.anchorColumn = const Value.absent(),
    this.visibleRows = const Value.absent(),
    this.visibleColumns = const Value.absent(),
    this.showCellColor = const Value.absent(),
    this.showSymbols = const Value.absent(),
    this.showGrid = const Value.absent(),
    this.cellColorOpacity = const Value.absent(),
    this.gridColor = const Value.absent(),
    this.showRegions = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ViewportStatesCompanion.insert({
    required String documentId,
    required double zoom,
    required double panX,
    required double panY,
    required int anchorRow,
    required int anchorColumn,
    this.visibleRows = const Value.absent(),
    this.visibleColumns = const Value.absent(),
    this.showCellColor = const Value.absent(),
    this.showSymbols = const Value.absent(),
    this.showGrid = const Value.absent(),
    this.cellColorOpacity = const Value.absent(),
    this.gridColor = const Value.absent(),
    this.showRegions = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : documentId = Value(documentId),
       zoom = Value(zoom),
       panX = Value(panX),
       panY = Value(panY),
       anchorRow = Value(anchorRow),
       anchorColumn = Value(anchorColumn);
  static Insertable<ViewportStateRow> custom({
    Expression<String>? documentId,
    Expression<double>? zoom,
    Expression<double>? panX,
    Expression<double>? panY,
    Expression<int>? anchorRow,
    Expression<int>? anchorColumn,
    Expression<int>? visibleRows,
    Expression<int>? visibleColumns,
    Expression<bool>? showCellColor,
    Expression<bool>? showSymbols,
    Expression<bool>? showGrid,
    Expression<double>? cellColorOpacity,
    Expression<String>? gridColor,
    Expression<bool>? showRegions,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (documentId != null) 'document_id': documentId,
      if (zoom != null) 'zoom': zoom,
      if (panX != null) 'pan_x': panX,
      if (panY != null) 'pan_y': panY,
      if (anchorRow != null) 'anchor_row': anchorRow,
      if (anchorColumn != null) 'anchor_column': anchorColumn,
      if (visibleRows != null) 'visible_rows': visibleRows,
      if (visibleColumns != null) 'visible_columns': visibleColumns,
      if (showCellColor != null) 'show_cell_color': showCellColor,
      if (showSymbols != null) 'show_symbols': showSymbols,
      if (showGrid != null) 'show_grid': showGrid,
      if (cellColorOpacity != null) 'cell_color_opacity': cellColorOpacity,
      if (gridColor != null) 'grid_color': gridColor,
      if (showRegions != null) 'show_regions': showRegions,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ViewportStatesCompanion copyWith({
    Value<String>? documentId,
    Value<double>? zoom,
    Value<double>? panX,
    Value<double>? panY,
    Value<int>? anchorRow,
    Value<int>? anchorColumn,
    Value<int?>? visibleRows,
    Value<int?>? visibleColumns,
    Value<bool>? showCellColor,
    Value<bool>? showSymbols,
    Value<bool>? showGrid,
    Value<double>? cellColorOpacity,
    Value<String>? gridColor,
    Value<bool>? showRegions,
    Value<int>? rowid,
  }) {
    return ViewportStatesCompanion(
      documentId: documentId ?? this.documentId,
      zoom: zoom ?? this.zoom,
      panX: panX ?? this.panX,
      panY: panY ?? this.panY,
      anchorRow: anchorRow ?? this.anchorRow,
      anchorColumn: anchorColumn ?? this.anchorColumn,
      visibleRows: visibleRows ?? this.visibleRows,
      visibleColumns: visibleColumns ?? this.visibleColumns,
      showCellColor: showCellColor ?? this.showCellColor,
      showSymbols: showSymbols ?? this.showSymbols,
      showGrid: showGrid ?? this.showGrid,
      cellColorOpacity: cellColorOpacity ?? this.cellColorOpacity,
      gridColor: gridColor ?? this.gridColor,
      showRegions: showRegions ?? this.showRegions,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (zoom.present) {
      map['zoom'] = Variable<double>(zoom.value);
    }
    if (panX.present) {
      map['pan_x'] = Variable<double>(panX.value);
    }
    if (panY.present) {
      map['pan_y'] = Variable<double>(panY.value);
    }
    if (anchorRow.present) {
      map['anchor_row'] = Variable<int>(anchorRow.value);
    }
    if (anchorColumn.present) {
      map['anchor_column'] = Variable<int>(anchorColumn.value);
    }
    if (visibleRows.present) {
      map['visible_rows'] = Variable<int>(visibleRows.value);
    }
    if (visibleColumns.present) {
      map['visible_columns'] = Variable<int>(visibleColumns.value);
    }
    if (showCellColor.present) {
      map['show_cell_color'] = Variable<bool>(showCellColor.value);
    }
    if (showSymbols.present) {
      map['show_symbols'] = Variable<bool>(showSymbols.value);
    }
    if (showGrid.present) {
      map['show_grid'] = Variable<bool>(showGrid.value);
    }
    if (cellColorOpacity.present) {
      map['cell_color_opacity'] = Variable<double>(cellColorOpacity.value);
    }
    if (gridColor.present) {
      map['grid_color'] = Variable<String>(gridColor.value);
    }
    if (showRegions.present) {
      map['show_regions'] = Variable<bool>(showRegions.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ViewportStatesCompanion(')
          ..write('documentId: $documentId, ')
          ..write('zoom: $zoom, ')
          ..write('panX: $panX, ')
          ..write('panY: $panY, ')
          ..write('anchorRow: $anchorRow, ')
          ..write('anchorColumn: $anchorColumn, ')
          ..write('visibleRows: $visibleRows, ')
          ..write('visibleColumns: $visibleColumns, ')
          ..write('showCellColor: $showCellColor, ')
          ..write('showSymbols: $showSymbols, ')
          ..write('showGrid: $showGrid, ')
          ..write('cellColorOpacity: $cellColorOpacity, ')
          ..write('gridColor: $gridColor, ')
          ..write('showRegions: $showRegions, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $PersistenceMetadataTable persistenceMetadata =
      $PersistenceMetadataTable(this);
  late final $PatternDocumentsTable patternDocuments = $PatternDocumentsTable(
    this,
  );
  late final $SourceMetadataEntriesTable sourceMetadataEntries =
      $SourceMetadataEntriesTable(this);
  late final $LibraryMetadataTable libraryMetadata = $LibraryMetadataTable(
    this,
  );
  late final $PatternSymbolsTable patternSymbols = $PatternSymbolsTable(this);
  late final $PatternRegionsTable patternRegions = $PatternRegionsTable(this);
  late final $PatternCellsTable patternCells = $PatternCellsTable(this);
  late final $ParserDiagnosticsTable parserDiagnostics =
      $ParserDiagnosticsTable(this);
  late final $ProgressStatesTable progressStates = $ProgressStatesTable(this);
  late final $CompletedCellsTable completedCells = $CompletedCellsTable(this);
  late final $LocationMarkersTable locationMarkers = $LocationMarkersTable(
    this,
  );
  late final $ViewportStatesTable viewportStates = $ViewportStatesTable(this);
  late final Index patternDocumentsTitle = Index(
    'pattern_documents_title',
    'CREATE INDEX pattern_documents_title ON pattern_documents (title)',
  );
  late final Index patternDocumentsSourceChecksum = Index(
    'pattern_documents_source_checksum',
    'CREATE INDEX pattern_documents_source_checksum ON pattern_documents (source_checksum)',
  );
  late final Index libraryMetadataLastOpened = Index(
    'library_metadata_last_opened',
    'CREATE INDEX library_metadata_last_opened ON library_metadata (last_opened_at)',
  );
  late final Index libraryMetadataLastModified = Index(
    'library_metadata_last_modified',
    'CREATE INDEX library_metadata_last_modified ON library_metadata (last_modified_at)',
  );
  late final Index patternSymbolsDocumentThread = Index(
    'pattern_symbols_document_thread',
    'CREATE INDEX pattern_symbols_document_thread ON pattern_symbols (document_id, thread_id)',
  );
  late final Index patternRegionsDocumentPage = Index(
    'pattern_regions_document_page',
    'CREATE INDEX pattern_regions_document_page ON pattern_regions (document_id, source_page)',
  );
  late final Index patternCellsDocumentSymbol = Index(
    'pattern_cells_document_symbol',
    'CREATE INDEX pattern_cells_document_symbol ON pattern_cells (document_id, symbol_id)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    persistenceMetadata,
    patternDocuments,
    sourceMetadataEntries,
    libraryMetadata,
    patternSymbols,
    patternRegions,
    patternCells,
    parserDiagnostics,
    progressStates,
    completedCells,
    locationMarkers,
    viewportStates,
    patternDocumentsTitle,
    patternDocumentsSourceChecksum,
    libraryMetadataLastOpened,
    libraryMetadataLastModified,
    patternSymbolsDocumentThread,
    patternRegionsDocumentPage,
    patternCellsDocumentSymbol,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pattern_documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('source_metadata_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pattern_documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('library_metadata', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pattern_documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('progress_states', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$PersistenceMetadataTableCreateCompanionBuilder =
    PersistenceMetadataCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$PersistenceMetadataTableUpdateCompanionBuilder =
    PersistenceMetadataCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$PersistenceMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $PersistenceMetadataTable> {
  $$PersistenceMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PersistenceMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $PersistenceMetadataTable> {
  $$PersistenceMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PersistenceMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $PersistenceMetadataTable> {
  $$PersistenceMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$PersistenceMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PersistenceMetadataTable,
          PersistenceMetadataData,
          $$PersistenceMetadataTableFilterComposer,
          $$PersistenceMetadataTableOrderingComposer,
          $$PersistenceMetadataTableAnnotationComposer,
          $$PersistenceMetadataTableCreateCompanionBuilder,
          $$PersistenceMetadataTableUpdateCompanionBuilder,
          (
            PersistenceMetadataData,
            BaseReferences<
              _$AppDatabase,
              $PersistenceMetadataTable,
              PersistenceMetadataData
            >,
          ),
          PersistenceMetadataData,
          PrefetchHooks Function()
        > {
  $$PersistenceMetadataTableTableManager(
    _$AppDatabase db,
    $PersistenceMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PersistenceMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PersistenceMetadataTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$PersistenceMetadataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PersistenceMetadataCompanion(
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => PersistenceMetadataCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $PersistenceMetadataTable,
                    PersistenceMetadataData
                  >(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PersistenceMetadataTable,
                    PersistenceMetadataData
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PersistenceMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PersistenceMetadataTable,
      PersistenceMetadataData,
      $$PersistenceMetadataTableFilterComposer,
      $$PersistenceMetadataTableOrderingComposer,
      $$PersistenceMetadataTableAnnotationComposer,
      $$PersistenceMetadataTableCreateCompanionBuilder,
      $$PersistenceMetadataTableUpdateCompanionBuilder,
      (
        PersistenceMetadataData,
        BaseReferences<
          _$AppDatabase,
          $PersistenceMetadataTable,
          PersistenceMetadataData
        >,
      ),
      PersistenceMetadataData,
      PrefetchHooks Function()
    >;
typedef $$PatternDocumentsTableCreateCompanionBuilder =
    PatternDocumentsCompanion Function({
      required String id,
      required String title,
      required int schemaVersion,
      required int rowCount,
      required int columnCount,
      Value<String?> sourceChecksum,
      Value<int> rowid,
    });
typedef $$PatternDocumentsTableUpdateCompanionBuilder =
    PatternDocumentsCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<int> schemaVersion,
      Value<int> rowCount,
      Value<int> columnCount,
      Value<String?> sourceChecksum,
      Value<int> rowid,
    });

final class $$PatternDocumentsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $PatternDocumentsTable,
          PatternDocumentRow
        > {
  $$PatternDocumentsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $SourceMetadataEntriesTable,
    List<SourceMetadataEntryRow>
  >
  _sourceMetadataEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.sourceMetadataEntries,
        aliasName:
            'pattern_documents__id__source_metadata_entries__document_id',
      );

  $$SourceMetadataEntriesTableProcessedTableManager
  get sourceMetadataEntriesRefs {
    final manager = $$SourceMetadataEntriesTableTableManager(
      $_db,
      $_db.sourceMetadataEntries,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sourceMetadataEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LibraryMetadataTable, List<LibraryMetadataRow>>
  _libraryMetadataRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.libraryMetadata,
    aliasName: 'pattern_documents__id__library_metadata__document_id',
  );

  $$LibraryMetadataTableProcessedTableManager get libraryMetadataRefs {
    final manager = $$LibraryMetadataTableTableManager(
      $_db,
      $_db.libraryMetadata,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _libraryMetadataRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProgressStatesTable, List<ProgressStateRow>>
  _progressStatesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.progressStates,
    aliasName: 'pattern_documents__id__progress_states__document_id',
  );

  $$ProgressStatesTableProcessedTableManager get progressStatesRefs {
    final manager = $$ProgressStatesTableTableManager(
      $_db,
      $_db.progressStates,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_progressStatesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PatternDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $PatternDocumentsTable> {
  $$PatternDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowCount => $composableBuilder(
    column: $table.rowCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get columnCount => $composableBuilder(
    column: $table.columnCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceChecksum => $composableBuilder(
    column: $table.sourceChecksum,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sourceMetadataEntriesRefs(
    Expression<bool> Function($$SourceMetadataEntriesTableFilterComposer f) f,
  ) {
    final $$SourceMetadataEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.sourceMetadataEntries,
          getReferencedColumn: (t) => t.documentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SourceMetadataEntriesTableFilterComposer(
                $db: $db,
                $table: $db.sourceMetadataEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> libraryMetadataRefs(
    Expression<bool> Function($$LibraryMetadataTableFilterComposer f) f,
  ) {
    final $$LibraryMetadataTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryMetadata,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryMetadataTableFilterComposer(
            $db: $db,
            $table: $db.libraryMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> progressStatesRefs(
    Expression<bool> Function($$ProgressStatesTableFilterComposer f) f,
  ) {
    final $$ProgressStatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progressStates,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressStatesTableFilterComposer(
            $db: $db,
            $table: $db.progressStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PatternDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatternDocumentsTable> {
  $$PatternDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowCount => $composableBuilder(
    column: $table.rowCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get columnCount => $composableBuilder(
    column: $table.columnCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceChecksum => $composableBuilder(
    column: $table.sourceChecksum,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatternDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatternDocumentsTable> {
  $$PatternDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowCount =>
      $composableBuilder(column: $table.rowCount, builder: (column) => column);

  GeneratedColumn<int> get columnCount => $composableBuilder(
    column: $table.columnCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceChecksum => $composableBuilder(
    column: $table.sourceChecksum,
    builder: (column) => column,
  );

  Expression<T> sourceMetadataEntriesRefs<T extends Object>(
    Expression<T> Function($$SourceMetadataEntriesTableAnnotationComposer a) f,
  ) {
    final $$SourceMetadataEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.sourceMetadataEntries,
          getReferencedColumn: (t) => t.documentId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$SourceMetadataEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.sourceMetadataEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> libraryMetadataRefs<T extends Object>(
    Expression<T> Function($$LibraryMetadataTableAnnotationComposer a) f,
  ) {
    final $$LibraryMetadataTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.libraryMetadata,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LibraryMetadataTableAnnotationComposer(
            $db: $db,
            $table: $db.libraryMetadata,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> progressStatesRefs<T extends Object>(
    Expression<T> Function($$ProgressStatesTableAnnotationComposer a) f,
  ) {
    final $$ProgressStatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.progressStates,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProgressStatesTableAnnotationComposer(
            $db: $db,
            $table: $db.progressStates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PatternDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PatternDocumentsTable,
          PatternDocumentRow,
          $$PatternDocumentsTableFilterComposer,
          $$PatternDocumentsTableOrderingComposer,
          $$PatternDocumentsTableAnnotationComposer,
          $$PatternDocumentsTableCreateCompanionBuilder,
          $$PatternDocumentsTableUpdateCompanionBuilder,
          (PatternDocumentRow, $$PatternDocumentsTableReferences),
          PatternDocumentRow,
          PrefetchHooks Function({
            bool sourceMetadataEntriesRefs,
            bool libraryMetadataRefs,
            bool progressStatesRefs,
          })
        > {
  $$PatternDocumentsTableTableManager(
    _$AppDatabase db,
    $PatternDocumentsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatternDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatternDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatternDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<int> rowCount = const Value.absent(),
                Value<int> columnCount = const Value.absent(),
                Value<String?> sourceChecksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatternDocumentsCompanion(
                id: id,
                title: title,
                schemaVersion: schemaVersion,
                rowCount: rowCount,
                columnCount: columnCount,
                sourceChecksum: sourceChecksum,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                required int schemaVersion,
                required int rowCount,
                required int columnCount,
                Value<String?> sourceChecksum = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatternDocumentsCompanion.insert(
                id: id,
                title: title,
                schemaVersion: schemaVersion,
                rowCount: rowCount,
                columnCount: columnCount,
                sourceChecksum: sourceChecksum,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PatternDocumentsTable, PatternDocumentRow>(
                    table,
                  ),
                  $$PatternDocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sourceMetadataEntriesRefs = false,
                libraryMetadataRefs = false,
                progressStatesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (sourceMetadataEntriesRefs) db.sourceMetadataEntries,
                    if (libraryMetadataRefs) db.libraryMetadata,
                    if (progressStatesRefs) db.progressStates,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (sourceMetadataEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          PatternDocumentRow,
                          $PatternDocumentsTable,
                          SourceMetadataEntryRow,
                          $SourceMetadataEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$PatternDocumentsTableReferences
                              ._sourceMetadataEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatternDocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).sourceMetadataEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'document_id',
                          typedResults: items,
                        ),
                      if (libraryMetadataRefs)
                        await $_getPrefetchedDataByColumns<
                          PatternDocumentRow,
                          $PatternDocumentsTable,
                          LibraryMetadataRow,
                          $LibraryMetadataTable
                        >(
                          currentTable: table,
                          referencedTable: $$PatternDocumentsTableReferences
                              ._libraryMetadataRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatternDocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).libraryMetadataRefs,
                          currentColumn: 'id',
                          referencedColumn: 'document_id',
                          typedResults: items,
                        ),
                      if (progressStatesRefs)
                        await $_getPrefetchedDataByColumns<
                          PatternDocumentRow,
                          $PatternDocumentsTable,
                          ProgressStateRow,
                          $ProgressStatesTable
                        >(
                          currentTable: table,
                          referencedTable: $$PatternDocumentsTableReferences
                              ._progressStatesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$PatternDocumentsTableReferences(
                                db,
                                table,
                                p0,
                              ).progressStatesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'document_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PatternDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PatternDocumentsTable,
      PatternDocumentRow,
      $$PatternDocumentsTableFilterComposer,
      $$PatternDocumentsTableOrderingComposer,
      $$PatternDocumentsTableAnnotationComposer,
      $$PatternDocumentsTableCreateCompanionBuilder,
      $$PatternDocumentsTableUpdateCompanionBuilder,
      (PatternDocumentRow, $$PatternDocumentsTableReferences),
      PatternDocumentRow,
      PrefetchHooks Function({
        bool sourceMetadataEntriesRefs,
        bool libraryMetadataRefs,
        bool progressStatesRefs,
      })
    >;
typedef $$SourceMetadataEntriesTableCreateCompanionBuilder =
    SourceMetadataEntriesCompanion Function({
      required String documentId,
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SourceMetadataEntriesTableUpdateCompanionBuilder =
    SourceMetadataEntriesCompanion Function({
      Value<String> documentId,
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

final class $$SourceMetadataEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SourceMetadataEntriesTable,
          SourceMetadataEntryRow
        > {
  $$SourceMetadataEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatternDocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.patternDocuments.createAlias(
        'source_metadata_entries__document_id__pattern_documents__id',
      );

  $$PatternDocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$PatternDocumentsTableTableManager(
      $_db,
      $_db.patternDocuments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SourceMetadataEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SourceMetadataEntriesTable> {
  $$SourceMetadataEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  $$PatternDocumentsTableFilterComposer get documentId {
    final $$PatternDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.patternDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.patternDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourceMetadataEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SourceMetadataEntriesTable> {
  $$SourceMetadataEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatternDocumentsTableOrderingComposer get documentId {
    final $$PatternDocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.patternDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternDocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.patternDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourceMetadataEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SourceMetadataEntriesTable> {
  $$SourceMetadataEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  $$PatternDocumentsTableAnnotationComposer get documentId {
    final $$PatternDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.patternDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.patternDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SourceMetadataEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SourceMetadataEntriesTable,
          SourceMetadataEntryRow,
          $$SourceMetadataEntriesTableFilterComposer,
          $$SourceMetadataEntriesTableOrderingComposer,
          $$SourceMetadataEntriesTableAnnotationComposer,
          $$SourceMetadataEntriesTableCreateCompanionBuilder,
          $$SourceMetadataEntriesTableUpdateCompanionBuilder,
          (SourceMetadataEntryRow, $$SourceMetadataEntriesTableReferences),
          SourceMetadataEntryRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$SourceMetadataEntriesTableTableManager(
    _$AppDatabase db,
    $SourceMetadataEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SourceMetadataEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$SourceMetadataEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$SourceMetadataEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SourceMetadataEntriesCompanion(
                documentId: documentId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SourceMetadataEntriesCompanion.insert(
                documentId: documentId,
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<
                    $SourceMetadataEntriesTable,
                    SourceMetadataEntryRow
                  >(table),
                  $$SourceMetadataEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.documentId,
                        referencedTable: $$SourceMetadataEntriesTableReferences
                            ._documentIdTable(db),
                        referencedColumn: $$SourceMetadataEntriesTableReferences
                            ._documentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SourceMetadataEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SourceMetadataEntriesTable,
      SourceMetadataEntryRow,
      $$SourceMetadataEntriesTableFilterComposer,
      $$SourceMetadataEntriesTableOrderingComposer,
      $$SourceMetadataEntriesTableAnnotationComposer,
      $$SourceMetadataEntriesTableCreateCompanionBuilder,
      $$SourceMetadataEntriesTableUpdateCompanionBuilder,
      (SourceMetadataEntryRow, $$SourceMetadataEntriesTableReferences),
      SourceMetadataEntryRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$LibraryMetadataTableCreateCompanionBuilder =
    LibraryMetadataCompanion Function({
      required String documentId,
      required DateTime createdAt,
      required DateTime importedAt,
      Value<DateTime?> lastOpenedAt,
      required DateTime lastModifiedAt,
      Value<String?> userTitle,
      Value<int> rowid,
    });
typedef $$LibraryMetadataTableUpdateCompanionBuilder =
    LibraryMetadataCompanion Function({
      Value<String> documentId,
      Value<DateTime> createdAt,
      Value<DateTime> importedAt,
      Value<DateTime?> lastOpenedAt,
      Value<DateTime> lastModifiedAt,
      Value<String?> userTitle,
      Value<int> rowid,
    });

final class $$LibraryMetadataTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $LibraryMetadataTable,
          LibraryMetadataRow
        > {
  $$LibraryMetadataTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatternDocumentsTable _documentIdTable(_$AppDatabase db) => db
      .patternDocuments
      .createAlias('library_metadata__document_id__pattern_documents__id');

  $$PatternDocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$PatternDocumentsTableTableManager(
      $_db,
      $_db.patternDocuments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LibraryMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryMetadataTable> {
  $$LibraryMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userTitle => $composableBuilder(
    column: $table.userTitle,
    builder: (column) => ColumnFilters(column),
  );

  $$PatternDocumentsTableFilterComposer get documentId {
    final $$PatternDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.patternDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.patternDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryMetadataTable> {
  $$LibraryMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userTitle => $composableBuilder(
    column: $table.userTitle,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatternDocumentsTableOrderingComposer get documentId {
    final $$PatternDocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.patternDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternDocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.patternDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryMetadataTable> {
  $$LibraryMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastOpenedAt => $composableBuilder(
    column: $table.lastOpenedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastModifiedAt => $composableBuilder(
    column: $table.lastModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userTitle =>
      $composableBuilder(column: $table.userTitle, builder: (column) => column);

  $$PatternDocumentsTableAnnotationComposer get documentId {
    final $$PatternDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.patternDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.patternDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LibraryMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryMetadataTable,
          LibraryMetadataRow,
          $$LibraryMetadataTableFilterComposer,
          $$LibraryMetadataTableOrderingComposer,
          $$LibraryMetadataTableAnnotationComposer,
          $$LibraryMetadataTableCreateCompanionBuilder,
          $$LibraryMetadataTableUpdateCompanionBuilder,
          (LibraryMetadataRow, $$LibraryMetadataTableReferences),
          LibraryMetadataRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$LibraryMetadataTableTableManager(
    _$AppDatabase db,
    $LibraryMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                Value<DateTime> lastModifiedAt = const Value.absent(),
                Value<String?> userTitle = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryMetadataCompanion(
                documentId: documentId,
                createdAt: createdAt,
                importedAt: importedAt,
                lastOpenedAt: lastOpenedAt,
                lastModifiedAt: lastModifiedAt,
                userTitle: userTitle,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required DateTime createdAt,
                required DateTime importedAt,
                Value<DateTime?> lastOpenedAt = const Value.absent(),
                required DateTime lastModifiedAt,
                Value<String?> userTitle = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LibraryMetadataCompanion.insert(
                documentId: documentId,
                createdAt: createdAt,
                importedAt: importedAt,
                lastOpenedAt: lastOpenedAt,
                lastModifiedAt: lastModifiedAt,
                userTitle: userTitle,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LibraryMetadataTable, LibraryMetadataRow>(table),
                  $$LibraryMetadataTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.documentId,
                        referencedTable: $$LibraryMetadataTableReferences
                            ._documentIdTable(db),
                        referencedColumn: $$LibraryMetadataTableReferences
                            ._documentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LibraryMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryMetadataTable,
      LibraryMetadataRow,
      $$LibraryMetadataTableFilterComposer,
      $$LibraryMetadataTableOrderingComposer,
      $$LibraryMetadataTableAnnotationComposer,
      $$LibraryMetadataTableCreateCompanionBuilder,
      $$LibraryMetadataTableUpdateCompanionBuilder,
      (LibraryMetadataRow, $$LibraryMetadataTableReferences),
      LibraryMetadataRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$PatternSymbolsTableCreateCompanionBuilder =
    PatternSymbolsCompanion Function({
      required String documentId,
      required String id,
      required int sortOrder,
      required String sourceSymbol,
      required String normalizedKey,
      required String displayGlyph,
      required String threadId,
      Value<String?> threadBrand,
      Value<String?> threadCatalogNumber,
      Value<String?> threadName,
      required String threadColor,
      Value<String?> threadConversionNotes,
      required String threadEvidence,
      Value<String?> legendEvidence,
      Value<int> rowid,
    });
typedef $$PatternSymbolsTableUpdateCompanionBuilder =
    PatternSymbolsCompanion Function({
      Value<String> documentId,
      Value<String> id,
      Value<int> sortOrder,
      Value<String> sourceSymbol,
      Value<String> normalizedKey,
      Value<String> displayGlyph,
      Value<String> threadId,
      Value<String?> threadBrand,
      Value<String?> threadCatalogNumber,
      Value<String?> threadName,
      Value<String> threadColor,
      Value<String?> threadConversionNotes,
      Value<String> threadEvidence,
      Value<String?> legendEvidence,
      Value<int> rowid,
    });

class $$PatternSymbolsTableFilterComposer
    extends Composer<_$AppDatabase, $PatternSymbolsTable> {
  $$PatternSymbolsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceSymbol => $composableBuilder(
    column: $table.sourceSymbol,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get normalizedKey => $composableBuilder(
    column: $table.normalizedKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayGlyph => $composableBuilder(
    column: $table.displayGlyph,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadBrand => $composableBuilder(
    column: $table.threadBrand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadCatalogNumber => $composableBuilder(
    column: $table.threadCatalogNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadName => $composableBuilder(
    column: $table.threadName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadColor => $composableBuilder(
    column: $table.threadColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadConversionNotes => $composableBuilder(
    column: $table.threadConversionNotes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get threadEvidence => $composableBuilder(
    column: $table.threadEvidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legendEvidence => $composableBuilder(
    column: $table.legendEvidence,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PatternSymbolsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatternSymbolsTable> {
  $$PatternSymbolsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceSymbol => $composableBuilder(
    column: $table.sourceSymbol,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get normalizedKey => $composableBuilder(
    column: $table.normalizedKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayGlyph => $composableBuilder(
    column: $table.displayGlyph,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadId => $composableBuilder(
    column: $table.threadId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadBrand => $composableBuilder(
    column: $table.threadBrand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadCatalogNumber => $composableBuilder(
    column: $table.threadCatalogNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadName => $composableBuilder(
    column: $table.threadName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadColor => $composableBuilder(
    column: $table.threadColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadConversionNotes => $composableBuilder(
    column: $table.threadConversionNotes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get threadEvidence => $composableBuilder(
    column: $table.threadEvidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legendEvidence => $composableBuilder(
    column: $table.legendEvidence,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatternSymbolsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatternSymbolsTable> {
  $$PatternSymbolsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<String> get sourceSymbol => $composableBuilder(
    column: $table.sourceSymbol,
    builder: (column) => column,
  );

  GeneratedColumn<String> get normalizedKey => $composableBuilder(
    column: $table.normalizedKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayGlyph => $composableBuilder(
    column: $table.displayGlyph,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadId =>
      $composableBuilder(column: $table.threadId, builder: (column) => column);

  GeneratedColumn<String> get threadBrand => $composableBuilder(
    column: $table.threadBrand,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadCatalogNumber => $composableBuilder(
    column: $table.threadCatalogNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadName => $composableBuilder(
    column: $table.threadName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadColor => $composableBuilder(
    column: $table.threadColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadConversionNotes => $composableBuilder(
    column: $table.threadConversionNotes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get threadEvidence => $composableBuilder(
    column: $table.threadEvidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get legendEvidence => $composableBuilder(
    column: $table.legendEvidence,
    builder: (column) => column,
  );
}

class $$PatternSymbolsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PatternSymbolsTable,
          PatternSymbolRow,
          $$PatternSymbolsTableFilterComposer,
          $$PatternSymbolsTableOrderingComposer,
          $$PatternSymbolsTableAnnotationComposer,
          $$PatternSymbolsTableCreateCompanionBuilder,
          $$PatternSymbolsTableUpdateCompanionBuilder,
          (
            PatternSymbolRow,
            BaseReferences<
              _$AppDatabase,
              $PatternSymbolsTable,
              PatternSymbolRow
            >,
          ),
          PatternSymbolRow,
          PrefetchHooks Function()
        > {
  $$PatternSymbolsTableTableManager(
    _$AppDatabase db,
    $PatternSymbolsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatternSymbolsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatternSymbolsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatternSymbolsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<String> sourceSymbol = const Value.absent(),
                Value<String> normalizedKey = const Value.absent(),
                Value<String> displayGlyph = const Value.absent(),
                Value<String> threadId = const Value.absent(),
                Value<String?> threadBrand = const Value.absent(),
                Value<String?> threadCatalogNumber = const Value.absent(),
                Value<String?> threadName = const Value.absent(),
                Value<String> threadColor = const Value.absent(),
                Value<String?> threadConversionNotes = const Value.absent(),
                Value<String> threadEvidence = const Value.absent(),
                Value<String?> legendEvidence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatternSymbolsCompanion(
                documentId: documentId,
                id: id,
                sortOrder: sortOrder,
                sourceSymbol: sourceSymbol,
                normalizedKey: normalizedKey,
                displayGlyph: displayGlyph,
                threadId: threadId,
                threadBrand: threadBrand,
                threadCatalogNumber: threadCatalogNumber,
                threadName: threadName,
                threadColor: threadColor,
                threadConversionNotes: threadConversionNotes,
                threadEvidence: threadEvidence,
                legendEvidence: legendEvidence,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required String id,
                required int sortOrder,
                required String sourceSymbol,
                required String normalizedKey,
                required String displayGlyph,
                required String threadId,
                Value<String?> threadBrand = const Value.absent(),
                Value<String?> threadCatalogNumber = const Value.absent(),
                Value<String?> threadName = const Value.absent(),
                required String threadColor,
                Value<String?> threadConversionNotes = const Value.absent(),
                required String threadEvidence,
                Value<String?> legendEvidence = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatternSymbolsCompanion.insert(
                documentId: documentId,
                id: id,
                sortOrder: sortOrder,
                sourceSymbol: sourceSymbol,
                normalizedKey: normalizedKey,
                displayGlyph: displayGlyph,
                threadId: threadId,
                threadBrand: threadBrand,
                threadCatalogNumber: threadCatalogNumber,
                threadName: threadName,
                threadColor: threadColor,
                threadConversionNotes: threadConversionNotes,
                threadEvidence: threadEvidence,
                legendEvidence: legendEvidence,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PatternSymbolsTable, PatternSymbolRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PatternSymbolsTable,
                    PatternSymbolRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PatternSymbolsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PatternSymbolsTable,
      PatternSymbolRow,
      $$PatternSymbolsTableFilterComposer,
      $$PatternSymbolsTableOrderingComposer,
      $$PatternSymbolsTableAnnotationComposer,
      $$PatternSymbolsTableCreateCompanionBuilder,
      $$PatternSymbolsTableUpdateCompanionBuilder,
      (
        PatternSymbolRow,
        BaseReferences<_$AppDatabase, $PatternSymbolsTable, PatternSymbolRow>,
      ),
      PatternSymbolRow,
      PrefetchHooks Function()
    >;
typedef $$PatternRegionsTableCreateCompanionBuilder =
    PatternRegionsCompanion Function({
      required String documentId,
      required String id,
      required int sortOrder,
      required int sourcePage,
      required int originRow,
      required int originColumn,
      required int rowCount,
      required int columnCount,
      Value<String?> label,
      Value<int> rowid,
    });
typedef $$PatternRegionsTableUpdateCompanionBuilder =
    PatternRegionsCompanion Function({
      Value<String> documentId,
      Value<String> id,
      Value<int> sortOrder,
      Value<int> sourcePage,
      Value<int> originRow,
      Value<int> originColumn,
      Value<int> rowCount,
      Value<int> columnCount,
      Value<String?> label,
      Value<int> rowid,
    });

class $$PatternRegionsTableFilterComposer
    extends Composer<_$AppDatabase, $PatternRegionsTable> {
  $$PatternRegionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourcePage => $composableBuilder(
    column: $table.sourcePage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originRow => $composableBuilder(
    column: $table.originRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get originColumn => $composableBuilder(
    column: $table.originColumn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get rowCount => $composableBuilder(
    column: $table.rowCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get columnCount => $composableBuilder(
    column: $table.columnCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PatternRegionsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatternRegionsTable> {
  $$PatternRegionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourcePage => $composableBuilder(
    column: $table.sourcePage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originRow => $composableBuilder(
    column: $table.originRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get originColumn => $composableBuilder(
    column: $table.originColumn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get rowCount => $composableBuilder(
    column: $table.rowCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get columnCount => $composableBuilder(
    column: $table.columnCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatternRegionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatternRegionsTable> {
  $$PatternRegionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get sourcePage => $composableBuilder(
    column: $table.sourcePage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get originRow =>
      $composableBuilder(column: $table.originRow, builder: (column) => column);

  GeneratedColumn<int> get originColumn => $composableBuilder(
    column: $table.originColumn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get rowCount =>
      $composableBuilder(column: $table.rowCount, builder: (column) => column);

  GeneratedColumn<int> get columnCount => $composableBuilder(
    column: $table.columnCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);
}

class $$PatternRegionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PatternRegionsTable,
          PatternRegionRow,
          $$PatternRegionsTableFilterComposer,
          $$PatternRegionsTableOrderingComposer,
          $$PatternRegionsTableAnnotationComposer,
          $$PatternRegionsTableCreateCompanionBuilder,
          $$PatternRegionsTableUpdateCompanionBuilder,
          (
            PatternRegionRow,
            BaseReferences<
              _$AppDatabase,
              $PatternRegionsTable,
              PatternRegionRow
            >,
          ),
          PatternRegionRow,
          PrefetchHooks Function()
        > {
  $$PatternRegionsTableTableManager(
    _$AppDatabase db,
    $PatternRegionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatternRegionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatternRegionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatternRegionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> sourcePage = const Value.absent(),
                Value<int> originRow = const Value.absent(),
                Value<int> originColumn = const Value.absent(),
                Value<int> rowCount = const Value.absent(),
                Value<int> columnCount = const Value.absent(),
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatternRegionsCompanion(
                documentId: documentId,
                id: id,
                sortOrder: sortOrder,
                sourcePage: sourcePage,
                originRow: originRow,
                originColumn: originColumn,
                rowCount: rowCount,
                columnCount: columnCount,
                label: label,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required String id,
                required int sortOrder,
                required int sourcePage,
                required int originRow,
                required int originColumn,
                required int rowCount,
                required int columnCount,
                Value<String?> label = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatternRegionsCompanion.insert(
                documentId: documentId,
                id: id,
                sortOrder: sortOrder,
                sourcePage: sourcePage,
                originRow: originRow,
                originColumn: originColumn,
                rowCount: rowCount,
                columnCount: columnCount,
                label: label,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PatternRegionsTable, PatternRegionRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PatternRegionsTable,
                    PatternRegionRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PatternRegionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PatternRegionsTable,
      PatternRegionRow,
      $$PatternRegionsTableFilterComposer,
      $$PatternRegionsTableOrderingComposer,
      $$PatternRegionsTableAnnotationComposer,
      $$PatternRegionsTableCreateCompanionBuilder,
      $$PatternRegionsTableUpdateCompanionBuilder,
      (
        PatternRegionRow,
        BaseReferences<_$AppDatabase, $PatternRegionsTable, PatternRegionRow>,
      ),
      PatternRegionRow,
      PrefetchHooks Function()
    >;
typedef $$PatternCellsTableCreateCompanionBuilder =
    PatternCellsCompanion Function({
      required String documentId,
      required int sortOrder,
      required int gridRow,
      required int gridColumn,
      required String symbolId,
      required String stitchType,
      Value<double?> confidence,
      Value<bool> needsReview,
      Value<String?> provenanceId,
      Value<int> rowid,
    });
typedef $$PatternCellsTableUpdateCompanionBuilder =
    PatternCellsCompanion Function({
      Value<String> documentId,
      Value<int> sortOrder,
      Value<int> gridRow,
      Value<int> gridColumn,
      Value<String> symbolId,
      Value<String> stitchType,
      Value<double?> confidence,
      Value<bool> needsReview,
      Value<String?> provenanceId,
      Value<int> rowid,
    });

class $$PatternCellsTableFilterComposer
    extends Composer<_$AppDatabase, $PatternCellsTable> {
  $$PatternCellsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridRow => $composableBuilder(
    column: $table.gridRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symbolId => $composableBuilder(
    column: $table.symbolId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stitchType => $composableBuilder(
    column: $table.stitchType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenanceId => $composableBuilder(
    column: $table.provenanceId,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PatternCellsTableOrderingComposer
    extends Composer<_$AppDatabase, $PatternCellsTable> {
  $$PatternCellsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridRow => $composableBuilder(
    column: $table.gridRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symbolId => $composableBuilder(
    column: $table.symbolId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stitchType => $composableBuilder(
    column: $table.stitchType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenanceId => $composableBuilder(
    column: $table.provenanceId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PatternCellsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PatternCellsTable> {
  $$PatternCellsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get gridRow =>
      $composableBuilder(column: $table.gridRow, builder: (column) => column);

  GeneratedColumn<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get symbolId =>
      $composableBuilder(column: $table.symbolId, builder: (column) => column);

  GeneratedColumn<String> get stitchType => $composableBuilder(
    column: $table.stitchType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get needsReview => $composableBuilder(
    column: $table.needsReview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get provenanceId => $composableBuilder(
    column: $table.provenanceId,
    builder: (column) => column,
  );
}

class $$PatternCellsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PatternCellsTable,
          PatternCellRow,
          $$PatternCellsTableFilterComposer,
          $$PatternCellsTableOrderingComposer,
          $$PatternCellsTableAnnotationComposer,
          $$PatternCellsTableCreateCompanionBuilder,
          $$PatternCellsTableUpdateCompanionBuilder,
          (
            PatternCellRow,
            BaseReferences<_$AppDatabase, $PatternCellsTable, PatternCellRow>,
          ),
          PatternCellRow,
          PrefetchHooks Function()
        > {
  $$PatternCellsTableTableManager(_$AppDatabase db, $PatternCellsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PatternCellsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PatternCellsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PatternCellsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> gridRow = const Value.absent(),
                Value<int> gridColumn = const Value.absent(),
                Value<String> symbolId = const Value.absent(),
                Value<String> stitchType = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<String?> provenanceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatternCellsCompanion(
                documentId: documentId,
                sortOrder: sortOrder,
                gridRow: gridRow,
                gridColumn: gridColumn,
                symbolId: symbolId,
                stitchType: stitchType,
                confidence: confidence,
                needsReview: needsReview,
                provenanceId: provenanceId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required int sortOrder,
                required int gridRow,
                required int gridColumn,
                required String symbolId,
                required String stitchType,
                Value<double?> confidence = const Value.absent(),
                Value<bool> needsReview = const Value.absent(),
                Value<String?> provenanceId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PatternCellsCompanion.insert(
                documentId: documentId,
                sortOrder: sortOrder,
                gridRow: gridRow,
                gridColumn: gridColumn,
                symbolId: symbolId,
                stitchType: stitchType,
                confidence: confidence,
                needsReview: needsReview,
                provenanceId: provenanceId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PatternCellsTable, PatternCellRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PatternCellsTable,
                    PatternCellRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PatternCellsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PatternCellsTable,
      PatternCellRow,
      $$PatternCellsTableFilterComposer,
      $$PatternCellsTableOrderingComposer,
      $$PatternCellsTableAnnotationComposer,
      $$PatternCellsTableCreateCompanionBuilder,
      $$PatternCellsTableUpdateCompanionBuilder,
      (
        PatternCellRow,
        BaseReferences<_$AppDatabase, $PatternCellsTable, PatternCellRow>,
      ),
      PatternCellRow,
      PrefetchHooks Function()
    >;
typedef $$ParserDiagnosticsTableCreateCompanionBuilder =
    ParserDiagnosticsCompanion Function({
      required String documentId,
      required int diagnosticIndex,
      required String severity,
      required String stage,
      required String message,
      Value<int?> gridRow,
      Value<int?> gridColumn,
      Value<int?> sourcePage,
      Value<String?> regionId,
      Value<double?> confidence,
      Value<String?> suggestedCorrection,
      Value<int> rowid,
    });
typedef $$ParserDiagnosticsTableUpdateCompanionBuilder =
    ParserDiagnosticsCompanion Function({
      Value<String> documentId,
      Value<int> diagnosticIndex,
      Value<String> severity,
      Value<String> stage,
      Value<String> message,
      Value<int?> gridRow,
      Value<int?> gridColumn,
      Value<int?> sourcePage,
      Value<String?> regionId,
      Value<double?> confidence,
      Value<String?> suggestedCorrection,
      Value<int> rowid,
    });

class $$ParserDiagnosticsTableFilterComposer
    extends Composer<_$AppDatabase, $ParserDiagnosticsTable> {
  $$ParserDiagnosticsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get diagnosticIndex => $composableBuilder(
    column: $table.diagnosticIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridRow => $composableBuilder(
    column: $table.gridRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sourcePage => $composableBuilder(
    column: $table.sourcePage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get regionId => $composableBuilder(
    column: $table.regionId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get suggestedCorrection => $composableBuilder(
    column: $table.suggestedCorrection,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ParserDiagnosticsTableOrderingComposer
    extends Composer<_$AppDatabase, $ParserDiagnosticsTable> {
  $$ParserDiagnosticsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get diagnosticIndex => $composableBuilder(
    column: $table.diagnosticIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get severity => $composableBuilder(
    column: $table.severity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stage => $composableBuilder(
    column: $table.stage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get message => $composableBuilder(
    column: $table.message,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridRow => $composableBuilder(
    column: $table.gridRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sourcePage => $composableBuilder(
    column: $table.sourcePage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get regionId => $composableBuilder(
    column: $table.regionId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get suggestedCorrection => $composableBuilder(
    column: $table.suggestedCorrection,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ParserDiagnosticsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ParserDiagnosticsTable> {
  $$ParserDiagnosticsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get diagnosticIndex => $composableBuilder(
    column: $table.diagnosticIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get severity =>
      $composableBuilder(column: $table.severity, builder: (column) => column);

  GeneratedColumn<String> get stage =>
      $composableBuilder(column: $table.stage, builder: (column) => column);

  GeneratedColumn<String> get message =>
      $composableBuilder(column: $table.message, builder: (column) => column);

  GeneratedColumn<int> get gridRow =>
      $composableBuilder(column: $table.gridRow, builder: (column) => column);

  GeneratedColumn<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sourcePage => $composableBuilder(
    column: $table.sourcePage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get regionId =>
      $composableBuilder(column: $table.regionId, builder: (column) => column);

  GeneratedColumn<double> get confidence => $composableBuilder(
    column: $table.confidence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get suggestedCorrection => $composableBuilder(
    column: $table.suggestedCorrection,
    builder: (column) => column,
  );
}

class $$ParserDiagnosticsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ParserDiagnosticsTable,
          ParserDiagnosticRow,
          $$ParserDiagnosticsTableFilterComposer,
          $$ParserDiagnosticsTableOrderingComposer,
          $$ParserDiagnosticsTableAnnotationComposer,
          $$ParserDiagnosticsTableCreateCompanionBuilder,
          $$ParserDiagnosticsTableUpdateCompanionBuilder,
          (
            ParserDiagnosticRow,
            BaseReferences<
              _$AppDatabase,
              $ParserDiagnosticsTable,
              ParserDiagnosticRow
            >,
          ),
          ParserDiagnosticRow,
          PrefetchHooks Function()
        > {
  $$ParserDiagnosticsTableTableManager(
    _$AppDatabase db,
    $ParserDiagnosticsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ParserDiagnosticsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ParserDiagnosticsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ParserDiagnosticsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<int> diagnosticIndex = const Value.absent(),
                Value<String> severity = const Value.absent(),
                Value<String> stage = const Value.absent(),
                Value<String> message = const Value.absent(),
                Value<int?> gridRow = const Value.absent(),
                Value<int?> gridColumn = const Value.absent(),
                Value<int?> sourcePage = const Value.absent(),
                Value<String?> regionId = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String?> suggestedCorrection = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParserDiagnosticsCompanion(
                documentId: documentId,
                diagnosticIndex: diagnosticIndex,
                severity: severity,
                stage: stage,
                message: message,
                gridRow: gridRow,
                gridColumn: gridColumn,
                sourcePage: sourcePage,
                regionId: regionId,
                confidence: confidence,
                suggestedCorrection: suggestedCorrection,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required int diagnosticIndex,
                required String severity,
                required String stage,
                required String message,
                Value<int?> gridRow = const Value.absent(),
                Value<int?> gridColumn = const Value.absent(),
                Value<int?> sourcePage = const Value.absent(),
                Value<String?> regionId = const Value.absent(),
                Value<double?> confidence = const Value.absent(),
                Value<String?> suggestedCorrection = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ParserDiagnosticsCompanion.insert(
                documentId: documentId,
                diagnosticIndex: diagnosticIndex,
                severity: severity,
                stage: stage,
                message: message,
                gridRow: gridRow,
                gridColumn: gridColumn,
                sourcePage: sourcePage,
                regionId: regionId,
                confidence: confidence,
                suggestedCorrection: suggestedCorrection,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ParserDiagnosticsTable, ParserDiagnosticRow>(
                    table,
                  ),
                  BaseReferences<
                    _$AppDatabase,
                    $ParserDiagnosticsTable,
                    ParserDiagnosticRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ParserDiagnosticsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ParserDiagnosticsTable,
      ParserDiagnosticRow,
      $$ParserDiagnosticsTableFilterComposer,
      $$ParserDiagnosticsTableOrderingComposer,
      $$ParserDiagnosticsTableAnnotationComposer,
      $$ParserDiagnosticsTableCreateCompanionBuilder,
      $$ParserDiagnosticsTableUpdateCompanionBuilder,
      (
        ParserDiagnosticRow,
        BaseReferences<
          _$AppDatabase,
          $ParserDiagnosticsTable,
          ParserDiagnosticRow
        >,
      ),
      ParserDiagnosticRow,
      PrefetchHooks Function()
    >;
typedef $$ProgressStatesTableCreateCompanionBuilder =
    ProgressStatesCompanion Function({
      required String documentId,
      required int schemaVersion,
      required DateTime lastInteractionAt,
      Value<int> rowid,
    });
typedef $$ProgressStatesTableUpdateCompanionBuilder =
    ProgressStatesCompanion Function({
      Value<String> documentId,
      Value<int> schemaVersion,
      Value<DateTime> lastInteractionAt,
      Value<int> rowid,
    });

final class $$ProgressStatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $ProgressStatesTable, ProgressStateRow> {
  $$ProgressStatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $PatternDocumentsTable _documentIdTable(_$AppDatabase db) => db
      .patternDocuments
      .createAlias('progress_states__document_id__pattern_documents__id');

  $$PatternDocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$PatternDocumentsTableTableManager(
      $_db,
      $_db.patternDocuments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ProgressStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ProgressStatesTable> {
  $$ProgressStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastInteractionAt => $composableBuilder(
    column: $table.lastInteractionAt,
    builder: (column) => ColumnFilters(column),
  );

  $$PatternDocumentsTableFilterComposer get documentId {
    final $$PatternDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.patternDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.patternDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgressStatesTable> {
  $$ProgressStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastInteractionAt => $composableBuilder(
    column: $table.lastInteractionAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$PatternDocumentsTableOrderingComposer get documentId {
    final $$PatternDocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.patternDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternDocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.patternDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgressStatesTable> {
  $$ProgressStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get schemaVersion => $composableBuilder(
    column: $table.schemaVersion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastInteractionAt => $composableBuilder(
    column: $table.lastInteractionAt,
    builder: (column) => column,
  );

  $$PatternDocumentsTableAnnotationComposer get documentId {
    final $$PatternDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.patternDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PatternDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.patternDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProgressStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgressStatesTable,
          ProgressStateRow,
          $$ProgressStatesTableFilterComposer,
          $$ProgressStatesTableOrderingComposer,
          $$ProgressStatesTableAnnotationComposer,
          $$ProgressStatesTableCreateCompanionBuilder,
          $$ProgressStatesTableUpdateCompanionBuilder,
          (ProgressStateRow, $$ProgressStatesTableReferences),
          ProgressStateRow,
          PrefetchHooks Function({bool documentId})
        > {
  $$ProgressStatesTableTableManager(
    _$AppDatabase db,
    $ProgressStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<int> schemaVersion = const Value.absent(),
                Value<DateTime> lastInteractionAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressStatesCompanion(
                documentId: documentId,
                schemaVersion: schemaVersion,
                lastInteractionAt: lastInteractionAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required int schemaVersion,
                required DateTime lastInteractionAt,
                Value<int> rowid = const Value.absent(),
              }) => ProgressStatesCompanion.insert(
                documentId: documentId,
                schemaVersion: schemaVersion,
                lastInteractionAt: lastInteractionAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgressStatesTable, ProgressStateRow>(table),
                  $$ProgressStatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.documentId,
                        referencedTable: $$ProgressStatesTableReferences
                            ._documentIdTable(db),
                        referencedColumn: $$ProgressStatesTableReferences
                            ._documentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ProgressStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgressStatesTable,
      ProgressStateRow,
      $$ProgressStatesTableFilterComposer,
      $$ProgressStatesTableOrderingComposer,
      $$ProgressStatesTableAnnotationComposer,
      $$ProgressStatesTableCreateCompanionBuilder,
      $$ProgressStatesTableUpdateCompanionBuilder,
      (ProgressStateRow, $$ProgressStatesTableReferences),
      ProgressStateRow,
      PrefetchHooks Function({bool documentId})
    >;
typedef $$CompletedCellsTableCreateCompanionBuilder =
    CompletedCellsCompanion Function({
      required String documentId,
      required int gridRow,
      required int gridColumn,
      Value<int> rowid,
    });
typedef $$CompletedCellsTableUpdateCompanionBuilder =
    CompletedCellsCompanion Function({
      Value<String> documentId,
      Value<int> gridRow,
      Value<int> gridColumn,
      Value<int> rowid,
    });

class $$CompletedCellsTableFilterComposer
    extends Composer<_$AppDatabase, $CompletedCellsTable> {
  $$CompletedCellsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridRow => $composableBuilder(
    column: $table.gridRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CompletedCellsTableOrderingComposer
    extends Composer<_$AppDatabase, $CompletedCellsTable> {
  $$CompletedCellsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridRow => $composableBuilder(
    column: $table.gridRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CompletedCellsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CompletedCellsTable> {
  $$CompletedCellsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get gridRow =>
      $composableBuilder(column: $table.gridRow, builder: (column) => column);

  GeneratedColumn<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => column,
  );
}

class $$CompletedCellsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CompletedCellsTable,
          CompletedCellRow,
          $$CompletedCellsTableFilterComposer,
          $$CompletedCellsTableOrderingComposer,
          $$CompletedCellsTableAnnotationComposer,
          $$CompletedCellsTableCreateCompanionBuilder,
          $$CompletedCellsTableUpdateCompanionBuilder,
          (
            CompletedCellRow,
            BaseReferences<
              _$AppDatabase,
              $CompletedCellsTable,
              CompletedCellRow
            >,
          ),
          CompletedCellRow,
          PrefetchHooks Function()
        > {
  $$CompletedCellsTableTableManager(
    _$AppDatabase db,
    $CompletedCellsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CompletedCellsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CompletedCellsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CompletedCellsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<int> gridRow = const Value.absent(),
                Value<int> gridColumn = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CompletedCellsCompanion(
                documentId: documentId,
                gridRow: gridRow,
                gridColumn: gridColumn,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required int gridRow,
                required int gridColumn,
                Value<int> rowid = const Value.absent(),
              }) => CompletedCellsCompanion.insert(
                documentId: documentId,
                gridRow: gridRow,
                gridColumn: gridColumn,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CompletedCellsTable, CompletedCellRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $CompletedCellsTable,
                    CompletedCellRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CompletedCellsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CompletedCellsTable,
      CompletedCellRow,
      $$CompletedCellsTableFilterComposer,
      $$CompletedCellsTableOrderingComposer,
      $$CompletedCellsTableAnnotationComposer,
      $$CompletedCellsTableCreateCompanionBuilder,
      $$CompletedCellsTableUpdateCompanionBuilder,
      (
        CompletedCellRow,
        BaseReferences<_$AppDatabase, $CompletedCellsTable, CompletedCellRow>,
      ),
      CompletedCellRow,
      PrefetchHooks Function()
    >;
typedef $$LocationMarkersTableCreateCompanionBuilder =
    LocationMarkersCompanion Function({
      required String documentId,
      required String id,
      required int sortOrder,
      required int gridRow,
      required int gridColumn,
      required String label,
      required String color,
      required double opacity,
      Value<bool> visible,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$LocationMarkersTableUpdateCompanionBuilder =
    LocationMarkersCompanion Function({
      Value<String> documentId,
      Value<String> id,
      Value<int> sortOrder,
      Value<int> gridRow,
      Value<int> gridColumn,
      Value<String> label,
      Value<String> color,
      Value<double> opacity,
      Value<bool> visible,
      Value<String?> note,
      Value<int> rowid,
    });

class $$LocationMarkersTableFilterComposer
    extends Composer<_$AppDatabase, $LocationMarkersTable> {
  $$LocationMarkersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridRow => $composableBuilder(
    column: $table.gridRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get visible => $composableBuilder(
    column: $table.visible,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocationMarkersTableOrderingComposer
    extends Composer<_$AppDatabase, $LocationMarkersTable> {
  $$LocationMarkersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridRow => $composableBuilder(
    column: $table.gridRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get opacity => $composableBuilder(
    column: $table.opacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get visible => $composableBuilder(
    column: $table.visible,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocationMarkersTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocationMarkersTable> {
  $$LocationMarkersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get gridRow =>
      $composableBuilder(column: $table.gridRow, builder: (column) => column);

  GeneratedColumn<int> get gridColumn => $composableBuilder(
    column: $table.gridColumn,
    builder: (column) => column,
  );

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<String> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<double> get opacity =>
      $composableBuilder(column: $table.opacity, builder: (column) => column);

  GeneratedColumn<bool> get visible =>
      $composableBuilder(column: $table.visible, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$LocationMarkersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocationMarkersTable,
          LocationMarkerRow,
          $$LocationMarkersTableFilterComposer,
          $$LocationMarkersTableOrderingComposer,
          $$LocationMarkersTableAnnotationComposer,
          $$LocationMarkersTableCreateCompanionBuilder,
          $$LocationMarkersTableUpdateCompanionBuilder,
          (
            LocationMarkerRow,
            BaseReferences<
              _$AppDatabase,
              $LocationMarkersTable,
              LocationMarkerRow
            >,
          ),
          LocationMarkerRow,
          PrefetchHooks Function()
        > {
  $$LocationMarkersTableTableManager(
    _$AppDatabase db,
    $LocationMarkersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocationMarkersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocationMarkersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocationMarkersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<String> id = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int> gridRow = const Value.absent(),
                Value<int> gridColumn = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<String> color = const Value.absent(),
                Value<double> opacity = const Value.absent(),
                Value<bool> visible = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocationMarkersCompanion(
                documentId: documentId,
                id: id,
                sortOrder: sortOrder,
                gridRow: gridRow,
                gridColumn: gridColumn,
                label: label,
                color: color,
                opacity: opacity,
                visible: visible,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required String id,
                required int sortOrder,
                required int gridRow,
                required int gridColumn,
                required String label,
                required String color,
                required double opacity,
                Value<bool> visible = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocationMarkersCompanion.insert(
                documentId: documentId,
                id: id,
                sortOrder: sortOrder,
                gridRow: gridRow,
                gridColumn: gridColumn,
                label: label,
                color: color,
                opacity: opacity,
                visible: visible,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$LocationMarkersTable, LocationMarkerRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $LocationMarkersTable,
                    LocationMarkerRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocationMarkersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocationMarkersTable,
      LocationMarkerRow,
      $$LocationMarkersTableFilterComposer,
      $$LocationMarkersTableOrderingComposer,
      $$LocationMarkersTableAnnotationComposer,
      $$LocationMarkersTableCreateCompanionBuilder,
      $$LocationMarkersTableUpdateCompanionBuilder,
      (
        LocationMarkerRow,
        BaseReferences<_$AppDatabase, $LocationMarkersTable, LocationMarkerRow>,
      ),
      LocationMarkerRow,
      PrefetchHooks Function()
    >;
typedef $$ViewportStatesTableCreateCompanionBuilder =
    ViewportStatesCompanion Function({
      required String documentId,
      required double zoom,
      required double panX,
      required double panY,
      required int anchorRow,
      required int anchorColumn,
      Value<int?> visibleRows,
      Value<int?> visibleColumns,
      Value<bool> showCellColor,
      Value<bool> showSymbols,
      Value<bool> showGrid,
      Value<double> cellColorOpacity,
      Value<String> gridColor,
      Value<bool> showRegions,
      Value<int> rowid,
    });
typedef $$ViewportStatesTableUpdateCompanionBuilder =
    ViewportStatesCompanion Function({
      Value<String> documentId,
      Value<double> zoom,
      Value<double> panX,
      Value<double> panY,
      Value<int> anchorRow,
      Value<int> anchorColumn,
      Value<int?> visibleRows,
      Value<int?> visibleColumns,
      Value<bool> showCellColor,
      Value<bool> showSymbols,
      Value<bool> showGrid,
      Value<double> cellColorOpacity,
      Value<String> gridColor,
      Value<bool> showRegions,
      Value<int> rowid,
    });

class $$ViewportStatesTableFilterComposer
    extends Composer<_$AppDatabase, $ViewportStatesTable> {
  $$ViewportStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zoom => $composableBuilder(
    column: $table.zoom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get panX => $composableBuilder(
    column: $table.panX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get panY => $composableBuilder(
    column: $table.panY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anchorRow => $composableBuilder(
    column: $table.anchorRow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get anchorColumn => $composableBuilder(
    column: $table.anchorColumn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visibleRows => $composableBuilder(
    column: $table.visibleRows,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get visibleColumns => $composableBuilder(
    column: $table.visibleColumns,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showCellColor => $composableBuilder(
    column: $table.showCellColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showSymbols => $composableBuilder(
    column: $table.showSymbols,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showGrid => $composableBuilder(
    column: $table.showGrid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cellColorOpacity => $composableBuilder(
    column: $table.cellColorOpacity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get gridColor => $composableBuilder(
    column: $table.gridColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showRegions => $composableBuilder(
    column: $table.showRegions,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ViewportStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $ViewportStatesTable> {
  $$ViewportStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zoom => $composableBuilder(
    column: $table.zoom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get panX => $composableBuilder(
    column: $table.panX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get panY => $composableBuilder(
    column: $table.panY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anchorRow => $composableBuilder(
    column: $table.anchorRow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get anchorColumn => $composableBuilder(
    column: $table.anchorColumn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visibleRows => $composableBuilder(
    column: $table.visibleRows,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get visibleColumns => $composableBuilder(
    column: $table.visibleColumns,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showCellColor => $composableBuilder(
    column: $table.showCellColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showSymbols => $composableBuilder(
    column: $table.showSymbols,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showGrid => $composableBuilder(
    column: $table.showGrid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cellColorOpacity => $composableBuilder(
    column: $table.cellColorOpacity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get gridColor => $composableBuilder(
    column: $table.gridColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showRegions => $composableBuilder(
    column: $table.showRegions,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ViewportStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ViewportStatesTable> {
  $$ViewportStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get documentId => $composableBuilder(
    column: $table.documentId,
    builder: (column) => column,
  );

  GeneratedColumn<double> get zoom =>
      $composableBuilder(column: $table.zoom, builder: (column) => column);

  GeneratedColumn<double> get panX =>
      $composableBuilder(column: $table.panX, builder: (column) => column);

  GeneratedColumn<double> get panY =>
      $composableBuilder(column: $table.panY, builder: (column) => column);

  GeneratedColumn<int> get anchorRow =>
      $composableBuilder(column: $table.anchorRow, builder: (column) => column);

  GeneratedColumn<int> get anchorColumn => $composableBuilder(
    column: $table.anchorColumn,
    builder: (column) => column,
  );

  GeneratedColumn<int> get visibleRows => $composableBuilder(
    column: $table.visibleRows,
    builder: (column) => column,
  );

  GeneratedColumn<int> get visibleColumns => $composableBuilder(
    column: $table.visibleColumns,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showCellColor => $composableBuilder(
    column: $table.showCellColor,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showSymbols => $composableBuilder(
    column: $table.showSymbols,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showGrid =>
      $composableBuilder(column: $table.showGrid, builder: (column) => column);

  GeneratedColumn<double> get cellColorOpacity => $composableBuilder(
    column: $table.cellColorOpacity,
    builder: (column) => column,
  );

  GeneratedColumn<String> get gridColor =>
      $composableBuilder(column: $table.gridColor, builder: (column) => column);

  GeneratedColumn<bool> get showRegions => $composableBuilder(
    column: $table.showRegions,
    builder: (column) => column,
  );
}

class $$ViewportStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ViewportStatesTable,
          ViewportStateRow,
          $$ViewportStatesTableFilterComposer,
          $$ViewportStatesTableOrderingComposer,
          $$ViewportStatesTableAnnotationComposer,
          $$ViewportStatesTableCreateCompanionBuilder,
          $$ViewportStatesTableUpdateCompanionBuilder,
          (
            ViewportStateRow,
            BaseReferences<
              _$AppDatabase,
              $ViewportStatesTable,
              ViewportStateRow
            >,
          ),
          ViewportStateRow,
          PrefetchHooks Function()
        > {
  $$ViewportStatesTableTableManager(
    _$AppDatabase db,
    $ViewportStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ViewportStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ViewportStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ViewportStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> documentId = const Value.absent(),
                Value<double> zoom = const Value.absent(),
                Value<double> panX = const Value.absent(),
                Value<double> panY = const Value.absent(),
                Value<int> anchorRow = const Value.absent(),
                Value<int> anchorColumn = const Value.absent(),
                Value<int?> visibleRows = const Value.absent(),
                Value<int?> visibleColumns = const Value.absent(),
                Value<bool> showCellColor = const Value.absent(),
                Value<bool> showSymbols = const Value.absent(),
                Value<bool> showGrid = const Value.absent(),
                Value<double> cellColorOpacity = const Value.absent(),
                Value<String> gridColor = const Value.absent(),
                Value<bool> showRegions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ViewportStatesCompanion(
                documentId: documentId,
                zoom: zoom,
                panX: panX,
                panY: panY,
                anchorRow: anchorRow,
                anchorColumn: anchorColumn,
                visibleRows: visibleRows,
                visibleColumns: visibleColumns,
                showCellColor: showCellColor,
                showSymbols: showSymbols,
                showGrid: showGrid,
                cellColorOpacity: cellColorOpacity,
                gridColor: gridColor,
                showRegions: showRegions,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String documentId,
                required double zoom,
                required double panX,
                required double panY,
                required int anchorRow,
                required int anchorColumn,
                Value<int?> visibleRows = const Value.absent(),
                Value<int?> visibleColumns = const Value.absent(),
                Value<bool> showCellColor = const Value.absent(),
                Value<bool> showSymbols = const Value.absent(),
                Value<bool> showGrid = const Value.absent(),
                Value<double> cellColorOpacity = const Value.absent(),
                Value<String> gridColor = const Value.absent(),
                Value<bool> showRegions = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ViewportStatesCompanion.insert(
                documentId: documentId,
                zoom: zoom,
                panX: panX,
                panY: panY,
                anchorRow: anchorRow,
                anchorColumn: anchorColumn,
                visibleRows: visibleRows,
                visibleColumns: visibleColumns,
                showCellColor: showCellColor,
                showSymbols: showSymbols,
                showGrid: showGrid,
                cellColorOpacity: cellColorOpacity,
                gridColor: gridColor,
                showRegions: showRegions,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ViewportStatesTable, ViewportStateRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $ViewportStatesTable,
                    ViewportStateRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ViewportStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ViewportStatesTable,
      ViewportStateRow,
      $$ViewportStatesTableFilterComposer,
      $$ViewportStatesTableOrderingComposer,
      $$ViewportStatesTableAnnotationComposer,
      $$ViewportStatesTableCreateCompanionBuilder,
      $$ViewportStatesTableUpdateCompanionBuilder,
      (
        ViewportStateRow,
        BaseReferences<_$AppDatabase, $ViewportStatesTable, ViewportStateRow>,
      ),
      ViewportStateRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$PersistenceMetadataTableTableManager get persistenceMetadata =>
      $$PersistenceMetadataTableTableManager(_db, _db.persistenceMetadata);
  $$PatternDocumentsTableTableManager get patternDocuments =>
      $$PatternDocumentsTableTableManager(_db, _db.patternDocuments);
  $$SourceMetadataEntriesTableTableManager get sourceMetadataEntries =>
      $$SourceMetadataEntriesTableTableManager(_db, _db.sourceMetadataEntries);
  $$LibraryMetadataTableTableManager get libraryMetadata =>
      $$LibraryMetadataTableTableManager(_db, _db.libraryMetadata);
  $$PatternSymbolsTableTableManager get patternSymbols =>
      $$PatternSymbolsTableTableManager(_db, _db.patternSymbols);
  $$PatternRegionsTableTableManager get patternRegions =>
      $$PatternRegionsTableTableManager(_db, _db.patternRegions);
  $$PatternCellsTableTableManager get patternCells =>
      $$PatternCellsTableTableManager(_db, _db.patternCells);
  $$ParserDiagnosticsTableTableManager get parserDiagnostics =>
      $$ParserDiagnosticsTableTableManager(_db, _db.parserDiagnostics);
  $$ProgressStatesTableTableManager get progressStates =>
      $$ProgressStatesTableTableManager(_db, _db.progressStates);
  $$CompletedCellsTableTableManager get completedCells =>
      $$CompletedCellsTableTableManager(_db, _db.completedCells);
  $$LocationMarkersTableTableManager get locationMarkers =>
      $$LocationMarkersTableTableManager(_db, _db.locationMarkers);
  $$ViewportStatesTableTableManager get viewportStates =>
      $$ViewportStatesTableTableManager(_db, _db.viewportStates);
}

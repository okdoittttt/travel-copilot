// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_db.dart';

// ignore_for_file: type=lint
class $CacheMetaTable extends CacheMeta with TableInfo<$CacheMetaTable, CacheMetaData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CacheMetaTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'cache_meta';
  @override
  VerificationContext validateIntegrity(
    Insertable<CacheMetaData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(_keyMeta, key.isAcceptableOrUnknown(data['key']!, _keyMeta));
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(_valueMeta, value.isAcceptableOrUnknown(data['value']!, _valueMeta));
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  CacheMetaData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CacheMetaData(
      key: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}key'])!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $CacheMetaTable createAlias(String alias) {
    return $CacheMetaTable(attachedDatabase, alias);
  }
}

class CacheMetaData extends DataClass implements Insertable<CacheMetaData> {
  final String key;
  final String value;
  const CacheMetaData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  CacheMetaCompanion toCompanion(bool nullToAbsent) {
    return CacheMetaCompanion(key: Value(key), value: Value(value));
  }

  factory CacheMetaData.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CacheMetaData(
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

  CacheMetaData copyWith({String? key, String? value}) =>
      CacheMetaData(key: key ?? this.key, value: value ?? this.value);
  CacheMetaData copyWithCompanion(CacheMetaCompanion data) {
    return CacheMetaData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CacheMetaData(')
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
      (other is CacheMetaData && other.key == this.key && other.value == this.value);
}

class CacheMetaCompanion extends UpdateCompanion<CacheMetaData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const CacheMetaCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CacheMetaCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<CacheMetaData> custom({
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

  CacheMetaCompanion copyWith({Value<String>? key, Value<String>? value, Value<int>? rowid}) {
    return CacheMetaCompanion(
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
    return (StringBuffer('CacheMetaCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedTripsTable extends CachedTrips with TableInfo<$CachedTripsTable, CachedTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedTripsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta('position');
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tripId, json, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedTrip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta, tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(_jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tripId};
  @override
  CachedTrip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedTrip(
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      json: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $CachedTripsTable createAlias(String alias) {
    return $CachedTripsTable(attachedDatabase, alias);
  }
}

class CachedTrip extends DataClass implements Insertable<CachedTrip> {
  final String tripId;
  final String json;
  final int position;
  const CachedTrip({required this.tripId, required this.json, required this.position});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trip_id'] = Variable<String>(tripId);
    map['json'] = Variable<String>(json);
    map['position'] = Variable<int>(position);
    return map;
  }

  CachedTripsCompanion toCompanion(bool nullToAbsent) {
    return CachedTripsCompanion(
      tripId: Value(tripId),
      json: Value(json),
      position: Value(position),
    );
  }

  factory CachedTrip.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedTrip(
      tripId: serializer.fromJson<String>(json['tripId']),
      json: serializer.fromJson<String>(json['json']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tripId': serializer.toJson<String>(tripId),
      'json': serializer.toJson<String>(json),
      'position': serializer.toJson<int>(position),
    };
  }

  CachedTrip copyWith({String? tripId, String? json, int? position}) => CachedTrip(
    tripId: tripId ?? this.tripId,
    json: json ?? this.json,
    position: position ?? this.position,
  );
  CachedTrip copyWithCompanion(CachedTripsCompanion data) {
    return CachedTrip(
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      json: data.json.present ? data.json.value : this.json,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedTrip(')
          ..write('tripId: $tripId, ')
          ..write('json: $json, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tripId, json, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedTrip &&
          other.tripId == this.tripId &&
          other.json == this.json &&
          other.position == this.position);
}

class CachedTripsCompanion extends UpdateCompanion<CachedTrip> {
  final Value<String> tripId;
  final Value<String> json;
  final Value<int> position;
  final Value<int> rowid;
  const CachedTripsCompanion({
    this.tripId = const Value.absent(),
    this.json = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedTripsCompanion.insert({
    required String tripId,
    required String json,
    required int position,
    this.rowid = const Value.absent(),
  }) : tripId = Value(tripId),
       json = Value(json),
       position = Value(position);
  static Insertable<CachedTrip> custom({
    Expression<String>? tripId,
    Expression<String>? json,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tripId != null) 'trip_id': tripId,
      if (json != null) 'json': json,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedTripsCompanion copyWith({
    Value<String>? tripId,
    Value<String>? json,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return CachedTripsCompanion(
      tripId: tripId ?? this.tripId,
      json: json ?? this.json,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedTripsCompanion(')
          ..write('tripId: $tripId, ')
          ..write('json: $json, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedSnapshotsTable extends CachedSnapshots
    with TableInfo<$CachedSnapshotsTable, CachedSnapshot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSnapshotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _tripIdMeta = const VerificationMeta('tripId');
  @override
  late final GeneratedColumn<String> tripId = GeneratedColumn<String>(
    'trip_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jsonMeta = const VerificationMeta('json');
  @override
  late final GeneratedColumn<String> json = GeneratedColumn<String>(
    'json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta('syncedAt');
  @override
  late final GeneratedColumn<DateTime> syncedAt = GeneratedColumn<DateTime>(
    'synced_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [tripId, json, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_snapshots';
  @override
  VerificationContext validateIntegrity(
    Insertable<CachedSnapshot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('trip_id')) {
      context.handle(_tripIdMeta, tripId.isAcceptableOrUnknown(data['trip_id']!, _tripIdMeta));
    } else if (isInserting) {
      context.missing(_tripIdMeta);
    }
    if (data.containsKey('json')) {
      context.handle(_jsonMeta, json.isAcceptableOrUnknown(data['json']!, _jsonMeta));
    } else if (isInserting) {
      context.missing(_jsonMeta);
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_syncedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {tripId};
  @override
  CachedSnapshot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSnapshot(
      tripId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}trip_id'],
      )!,
      json: attachedDatabase.typeMapping.read(DriftSqlType.string, data['${effectivePrefix}json'])!,
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}synced_at'],
      )!,
    );
  }

  @override
  $CachedSnapshotsTable createAlias(String alias) {
    return $CachedSnapshotsTable(attachedDatabase, alias);
  }
}

class CachedSnapshot extends DataClass implements Insertable<CachedSnapshot> {
  final String tripId;
  final String json;
  final DateTime syncedAt;
  const CachedSnapshot({required this.tripId, required this.json, required this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['trip_id'] = Variable<String>(tripId);
    map['json'] = Variable<String>(json);
    map['synced_at'] = Variable<DateTime>(syncedAt);
    return map;
  }

  CachedSnapshotsCompanion toCompanion(bool nullToAbsent) {
    return CachedSnapshotsCompanion(
      tripId: Value(tripId),
      json: Value(json),
      syncedAt: Value(syncedAt),
    );
  }

  factory CachedSnapshot.fromJson(Map<String, dynamic> json, {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSnapshot(
      tripId: serializer.fromJson<String>(json['tripId']),
      json: serializer.fromJson<String>(json['json']),
      syncedAt: serializer.fromJson<DateTime>(json['syncedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'tripId': serializer.toJson<String>(tripId),
      'json': serializer.toJson<String>(json),
      'syncedAt': serializer.toJson<DateTime>(syncedAt),
    };
  }

  CachedSnapshot copyWith({String? tripId, String? json, DateTime? syncedAt}) => CachedSnapshot(
    tripId: tripId ?? this.tripId,
    json: json ?? this.json,
    syncedAt: syncedAt ?? this.syncedAt,
  );
  CachedSnapshot copyWithCompanion(CachedSnapshotsCompanion data) {
    return CachedSnapshot(
      tripId: data.tripId.present ? data.tripId.value : this.tripId,
      json: data.json.present ? data.json.value : this.json,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSnapshot(')
          ..write('tripId: $tripId, ')
          ..write('json: $json, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(tripId, json, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSnapshot &&
          other.tripId == this.tripId &&
          other.json == this.json &&
          other.syncedAt == this.syncedAt);
}

class CachedSnapshotsCompanion extends UpdateCompanion<CachedSnapshot> {
  final Value<String> tripId;
  final Value<String> json;
  final Value<DateTime> syncedAt;
  final Value<int> rowid;
  const CachedSnapshotsCompanion({
    this.tripId = const Value.absent(),
    this.json = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSnapshotsCompanion.insert({
    required String tripId,
    required String json,
    required DateTime syncedAt,
    this.rowid = const Value.absent(),
  }) : tripId = Value(tripId),
       json = Value(json),
       syncedAt = Value(syncedAt);
  static Insertable<CachedSnapshot> custom({
    Expression<String>? tripId,
    Expression<String>? json,
    Expression<DateTime>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (tripId != null) 'trip_id': tripId,
      if (json != null) 'json': json,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSnapshotsCompanion copyWith({
    Value<String>? tripId,
    Value<String>? json,
    Value<DateTime>? syncedAt,
    Value<int>? rowid,
  }) {
    return CachedSnapshotsCompanion(
      tripId: tripId ?? this.tripId,
      json: json ?? this.json,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (tripId.present) {
      map['trip_id'] = Variable<String>(tripId.value);
    }
    if (json.present) {
      map['json'] = Variable<String>(json.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<DateTime>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSnapshotsCompanion(')
          ..write('tripId: $tripId, ')
          ..write('json: $json, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$CacheDatabase extends GeneratedDatabase {
  _$CacheDatabase(QueryExecutor e) : super(e);
  $CacheDatabaseManager get managers => $CacheDatabaseManager(this);
  late final $CacheMetaTable cacheMeta = $CacheMetaTable(this);
  late final $CachedTripsTable cachedTrips = $CachedTripsTable(this);
  late final $CachedSnapshotsTable cachedSnapshots = $CachedSnapshotsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [cacheMeta, cachedTrips, cachedSnapshots];
}

typedef $$CacheMetaTableCreateCompanionBuilder = CacheMetaCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$CacheMetaTableUpdateCompanionBuilder = CacheMetaCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$CacheMetaTableFilterComposer extends Composer<_$CacheDatabase, $CacheMetaTable> {
  $$CacheMetaTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnFilters(column));
}

class $$CacheMetaTableOrderingComposer extends Composer<_$CacheDatabase, $CacheMetaTable> {
  $$CacheMetaTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => ColumnOrderings(column));
}

class $$CacheMetaTableAnnotationComposer extends Composer<_$CacheDatabase, $CacheMetaTable> {
  $$CacheMetaTableAnnotationComposer({
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

class $$CacheMetaTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $CacheMetaTable,
          CacheMetaData,
          $$CacheMetaTableFilterComposer,
          $$CacheMetaTableOrderingComposer,
          $$CacheMetaTableAnnotationComposer,
          $$CacheMetaTableCreateCompanionBuilder,
          $$CacheMetaTableUpdateCompanionBuilder,
          (CacheMetaData, BaseReferences<_$CacheDatabase, $CacheMetaTable, CacheMetaData>),
          CacheMetaData,
          PrefetchHooks Function()
        > {
  $$CacheMetaTableTableManager(_$CacheDatabase db, $CacheMetaTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CacheMetaTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CacheMetaTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CacheMetaTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => CacheMetaCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => CacheMetaCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CacheMetaTable, CacheMetaData>(table),
                  BaseReferences<_$CacheDatabase, $CacheMetaTable, CacheMetaData>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CacheMetaTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $CacheMetaTable,
      CacheMetaData,
      $$CacheMetaTableFilterComposer,
      $$CacheMetaTableOrderingComposer,
      $$CacheMetaTableAnnotationComposer,
      $$CacheMetaTableCreateCompanionBuilder,
      $$CacheMetaTableUpdateCompanionBuilder,
      (CacheMetaData, BaseReferences<_$CacheDatabase, $CacheMetaTable, CacheMetaData>),
      CacheMetaData,
      PrefetchHooks Function()
    >;
typedef $$CachedTripsTableCreateCompanionBuilder = CachedTripsCompanion Function({
  required String tripId,
  required String json,
  required int position,
  Value<int> rowid,
});
typedef $$CachedTripsTableUpdateCompanionBuilder = CachedTripsCompanion Function({
  Value<String> tripId,
  Value<String> json,
  Value<int> position,
  Value<int> rowid,
});

class $$CachedTripsTableFilterComposer extends Composer<_$CacheDatabase, $CachedTripsTable> {
  $$CachedTripsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnFilters(column));
}

class $$CachedTripsTableOrderingComposer extends Composer<_$CacheDatabase, $CachedTripsTable> {
  $$CachedTripsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => ColumnOrderings(column));
}

class $$CachedTripsTableAnnotationComposer extends Composer<_$CacheDatabase, $CachedTripsTable> {
  $$CachedTripsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);
}

class $$CachedTripsTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $CachedTripsTable,
          CachedTrip,
          $$CachedTripsTableFilterComposer,
          $$CachedTripsTableOrderingComposer,
          $$CachedTripsTableAnnotationComposer,
          $$CachedTripsTableCreateCompanionBuilder,
          $$CachedTripsTableUpdateCompanionBuilder,
          (CachedTrip, BaseReferences<_$CacheDatabase, $CachedTripsTable, CachedTrip>),
          CachedTrip,
          PrefetchHooks Function()
        > {
  $$CachedTripsTableTableManager(_$CacheDatabase db, $CachedTripsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () => $$CachedTripsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () => $$CachedTripsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedTripsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> tripId = const Value.absent(),
            Value<String> json = const Value.absent(),
            Value<int> position = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => CachedTripsCompanion(tripId: tripId, json: json, position: position, rowid: rowid),
          createCompanionCallback:
              ({
                required String tripId,
                required String json,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => CachedTripsCompanion.insert(
                tripId: tripId,
                json: json,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedTripsTable, CachedTrip>(table),
                  BaseReferences<_$CacheDatabase, $CachedTripsTable, CachedTrip>(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedTripsTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $CachedTripsTable,
      CachedTrip,
      $$CachedTripsTableFilterComposer,
      $$CachedTripsTableOrderingComposer,
      $$CachedTripsTableAnnotationComposer,
      $$CachedTripsTableCreateCompanionBuilder,
      $$CachedTripsTableUpdateCompanionBuilder,
      (CachedTrip, BaseReferences<_$CacheDatabase, $CachedTripsTable, CachedTrip>),
      CachedTrip,
      PrefetchHooks Function()
    >;
typedef $$CachedSnapshotsTableCreateCompanionBuilder = CachedSnapshotsCompanion Function({
  required String tripId,
  required String json,
  required DateTime syncedAt,
  Value<int> rowid,
});
typedef $$CachedSnapshotsTableUpdateCompanionBuilder = CachedSnapshotsCompanion Function({
  Value<String> tripId,
  Value<String> json,
  Value<DateTime> syncedAt,
  Value<int> rowid,
});

class $$CachedSnapshotsTableFilterComposer
    extends Composer<_$CacheDatabase, $CachedSnapshotsTable> {
  $$CachedSnapshotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedSnapshotsTableOrderingComposer
    extends Composer<_$CacheDatabase, $CachedSnapshotsTable> {
  $$CachedSnapshotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedSnapshotsTableAnnotationComposer
    extends Composer<_$CacheDatabase, $CachedSnapshotsTable> {
  $$CachedSnapshotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get tripId =>
      $composableBuilder(column: $table.tripId, builder: (column) => column);

  GeneratedColumn<String> get json =>
      $composableBuilder(column: $table.json, builder: (column) => column);

  GeneratedColumn<DateTime> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $$CachedSnapshotsTableTableManager
    extends
        RootTableManager<
          _$CacheDatabase,
          $CachedSnapshotsTable,
          CachedSnapshot,
          $$CachedSnapshotsTableFilterComposer,
          $$CachedSnapshotsTableOrderingComposer,
          $$CachedSnapshotsTableAnnotationComposer,
          $$CachedSnapshotsTableCreateCompanionBuilder,
          $$CachedSnapshotsTableUpdateCompanionBuilder,
          (CachedSnapshot, BaseReferences<_$CacheDatabase, $CachedSnapshotsTable, CachedSnapshot>),
          CachedSnapshot,
          PrefetchHooks Function()
        > {
  $$CachedSnapshotsTableTableManager(_$CacheDatabase db, $CachedSnapshotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSnapshotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSnapshotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSnapshotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> tripId = const Value.absent(),
                Value<String> json = const Value.absent(),
                Value<DateTime> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CachedSnapshotsCompanion(
                tripId: tripId,
                json: json,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String tripId,
                required String json,
                required DateTime syncedAt,
                Value<int> rowid = const Value.absent(),
              }) => CachedSnapshotsCompanion.insert(
                tripId: tripId,
                json: json,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CachedSnapshotsTable, CachedSnapshot>(table),
                  BaseReferences<_$CacheDatabase, $CachedSnapshotsTable, CachedSnapshot>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CachedSnapshotsTableProcessedTableManager =
    ProcessedTableManager<
      _$CacheDatabase,
      $CachedSnapshotsTable,
      CachedSnapshot,
      $$CachedSnapshotsTableFilterComposer,
      $$CachedSnapshotsTableOrderingComposer,
      $$CachedSnapshotsTableAnnotationComposer,
      $$CachedSnapshotsTableCreateCompanionBuilder,
      $$CachedSnapshotsTableUpdateCompanionBuilder,
      (CachedSnapshot, BaseReferences<_$CacheDatabase, $CachedSnapshotsTable, CachedSnapshot>),
      CachedSnapshot,
      PrefetchHooks Function()
    >;

class $CacheDatabaseManager {
  final _$CacheDatabase _db;
  $CacheDatabaseManager(this._db);
  $$CacheMetaTableTableManager get cacheMeta => $$CacheMetaTableTableManager(_db, _db.cacheMeta);
  $$CachedTripsTableTableManager get cachedTrips =>
      $$CachedTripsTableTableManager(_db, _db.cachedTrips);
  $$CachedSnapshotsTableTableManager get cachedSnapshots =>
      $$CachedSnapshotsTableTableManager(_db, _db.cachedSnapshots);
}

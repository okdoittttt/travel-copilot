import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/storage/cache_db.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';

part 'trip_cache.g.dart';

final _log = Logger('TripCache');

const _ownerKey = 'owner_user_id';
const _tripsSyncedKey = 'trips_synced_at';
const _dbFileName = 'trip_cache.sqlite';
const _storageChannel = MethodChannel('travelcopilot/storage');

/// 캐시에서 읽은 값과 그 값을 서버에서 받은 시각.
typedef Cached<T> = ({T data, DateTime syncedAt});

/// 여행 목록·스냅샷의 기기 캐시 (features/sync-offline.md 5.1·5.2·5.7).
///
/// - 좌표는 저장하지 않는다 (Google 약관)
/// - 캐시 내용(제목·메모·이름)은 로그에 남기지 않는다
/// - 읽기·쓰기 실패는 "캐시 없음"으로 다룬다. 캐시가 없어도 앱은 온라인으로 동작한다
class TripCache {
  /// 파일 DB. `directory` 안에 DB 파일과 SQLite 보조 파일(-wal, -shm, -journal)이 생긴다.
  new({required this._directory, required this._openFile});

  /// 메모리 DB (테스트용). [wipe]하면 새 메모리 DB로 바뀐다.
  new memory() : _directory = null, _openFile = null;

  final Future<Directory> Function()? _directory;
  final QueryExecutor Function(File file)? _openFile;
  Future<CacheDatabase>? _opening;

  Future<CacheDatabase> get _db => _opening ??= _open();

  Future<CacheDatabase> _open() async {
    final directoryOf = _directory;
    final openFile = _openFile;
    if (directoryOf == null || openFile == null) return CacheDatabase(NativeDatabase.memory());
    final directory = await directoryOf();
    await directory.create(recursive: true);
    return CacheDatabase(openFile(File('${directory.path}/$_dbFileName')));
  }

  /// 로그인한 사용자를 캐시 주인으로 정한다. 주인이 다르면 이전 사용자의 캐시를 모두 지운다 (T34).
  Future<void> claim(String userId) async {
    final owner = await _guard(() async => await _meta(await _db, _ownerKey), null);
    if (owner != null && owner != userId) {
      _log.info('다른 계정 로그인: 캐시 전체 삭제');
      await wipe();
    }
    await _guard(() async => await _setMeta(await _db, _ownerKey, userId), null);
  }

  Future<Cached<List<Trip>>?> readTrips() => _guard(() async {
    final db = await _db;
    final synced = await _meta(db, _tripsSyncedKey);
    if (synced == null) return null;
    final rows = await (db.select(
      db.cachedTrips,
    )..orderBy([(t) => OrderingTerm.asc(t.position)])).get();
    final trips = <Trip>[];
    for (final row in rows) {
      final trip = _decode(row.json, Trip.fromJson);
      if (trip == null) {
        await (db.delete(db.cachedTrips)..where((t) => t.tripId.equals(row.tripId))).go();
      } else {
        trips.add(trip);
      }
    }
    return (data: trips, syncedAt: DateTime.parse(synced));
  }, null);

  /// 서버에서 받은 **전체** 목록으로 바꾼다. 목록에 없는 여행의 스냅샷도 지운다 (T08).
  ///
  /// 일부 페이지만 받은 결과로 부르면 안 된다. 그러면 멀쩡한 여행 캐시가 사라진다.
  Future<int> replaceTrips(List<Trip> trips, DateTime syncedAt) => _guard(() async {
    final db = await _db;
    final ids = [for (final trip in trips) trip.id];
    return await db.transaction(() async {
      final removed = await (db.delete(db.cachedTrips)..where((t) => t.tripId.isNotIn(ids))).go();
      await (db.delete(db.cachedSnapshots)..where((t) => t.tripId.isNotIn(ids))).go();
      for (final (index, trip) in trips.indexed) {
        await db
            .into(db.cachedTrips)
            .insertOnConflictUpdate(
              CachedTripsCompanion.insert(
                tripId: trip.id,
                json: jsonEncode(trip.toJson()),
                position: index,
              ),
            );
      }
      await _setMeta(db, _tripsSyncedKey, syncedAt.toUtc().toIso8601String());
      return removed;
    });
  }, 0);

  Future<Cached<TripSnapshot>?> readSnapshot(String tripId) => _guard(() async {
    final db = await _db;
    final row = await (db.select(
      db.cachedSnapshots,
    )..where((t) => t.tripId.equals(tripId))).getSingleOrNull();
    if (row == null) return null;
    final snapshot = _decode(row.json, TripSnapshot.fromJson);
    if (snapshot == null) {
      await removeTrip(tripId);
      return null;
    }
    return (data: snapshot, syncedAt: row.syncedAt);
  }, null);

  /// 스냅샷을 저장한다. **좌표를 지운 뒤** 저장한다.
  Future<void> saveSnapshot(TripSnapshot snapshot, DateTime syncedAt) => _guard(() async {
    final db = await _db;
    await db
        .into(db.cachedSnapshots)
        .insertOnConflictUpdate(
          CachedSnapshotsCompanion.insert(
            tripId: snapshot.trip.id,
            json: jsonEncode(withoutLocations(snapshot).toJson()),
            syncedAt: syncedAt,
          ),
        );
  }, null);

  /// 여행 하나의 목록 행과 스냅샷을 지운다 (404, 삭제, 나가기).
  Future<void> removeTrip(String tripId) => _guard(() async {
    final db = await _db;
    await db.transaction(() async {
      await (db.delete(db.cachedTrips)..where((t) => t.tripId.equals(tripId))).go();
      await (db.delete(db.cachedSnapshots)..where((t) => t.tripId.equals(tripId))).go();
    });
  }, null);

  /// 캐시 전체 삭제. 행을 지우는 대신 DB를 닫고 **파일을 지운다** (로그아웃, 계정 전환).
  Future<void> wipe() async {
    final opening = _opening;
    _opening = null;
    if (opening != null) {
      try {
        await (await opening).close();
      } on Exception catch (error) {
        _log.warning('캐시 DB 닫기 실패: ${error.runtimeType}');
      }
    }
    final directoryOf = _directory;
    if (directoryOf == null) return;
    try {
      final directory = await directoryOf();
      if (directory.existsSync()) await directory.delete(recursive: true);
    } on Exception catch (error) {
      _log.warning('캐시 파일 삭제 실패: ${error.runtimeType}');
    }
  }

  Future<void> close() async {
    final opening = _opening;
    _opening = null;
    if (opening != null) await (await opening).close();
  }

  static Future<String?> _meta(CacheDatabase db, String key) async =>
      (await (db.select(db.cacheMeta)..where((t) => t.key.equals(key))).getSingleOrNull())?.value;

  static Future<void> _setMeta(CacheDatabase db, String key, String value) => db
      .into(db.cacheMeta)
      .insertOnConflictUpdate(CacheMetaCompanion.insert(key: key, value: value));

  /// 캐시 형식이 바뀌어 해석할 수 없으면 null (그 행은 호출한 쪽이 지운다).
  static T? _decode<T>(String json, T Function(Map<String, dynamic>) fromJson) {
    try {
      return fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object catch (error) {
      _log.info('캐시 해석 실패: ${error.runtimeType}');
      return null;
    }
  }

  static Future<T> _guard<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } on Exception catch (error) {
      // 캐시 실패로 화면이 깨지지 않게 한다. 내용은 남기지 않고 종류만
      _log.warning('캐시 작업 실패: ${error.runtimeType}');
      return fallback;
    }
  }
}

/// 스냅샷에서 좌표를 지운다. 기기에는 좌표를 저장하지 않는다 (05-data-model 2절).
TripSnapshot withoutLocations(TripSnapshot snapshot) =>
    snapshot.copyWith(items: [for (final item in snapshot.items) item.copyWith(location: null)]);

/// 앱 지원 폴더 안의 캐시 폴더. iOS는 기기 백업에서 제외한다 (T19).
///
/// Documents는 설정에 따라 파일 앱에 보일 수 있어서 쓰지 않는다 (5.8).
Future<Directory> _cacheDirectory() async {
  final support = await getApplicationSupportDirectory();
  final directory = Directory('${support.path}/trip_cache');
  await directory.create(recursive: true);
  if (Platform.isIOS) {
    try {
      await _storageChannel.invokeMethod<void>('excludeFromBackup', directory.path);
    } on PlatformException catch (error) {
      _log.warning('백업 제외 설정 실패: ${error.code}');
    } on MissingPluginException {
      _log.warning('백업 제외 설정 불가');
    }
  }
  return directory;
}

@Riverpod(keepAlive: true)
TripCache tripCache(Ref ref) {
  final cache = TripCache(
    directory: _cacheDirectory,
    openFile: (file) => driftDatabase(
      name: 'trip_cache',
      native: DriftNativeOptions(databasePath: () async => file.path),
    ),
  );
  ref.onDispose(cache.close);
  return cache;
}

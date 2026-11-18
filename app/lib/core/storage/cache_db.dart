import 'package:drift/drift.dart';

part 'cache_db.g.dart';

/// 캐시 정보 (캐시 주인 사용자 ID, 목록 마지막 동기화 시각).
class CacheMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// 여행 목록 한 줄 = 서버의 Trip JSON.
class CachedTrips extends Table {
  TextColumn get tripId => text()();
  TextColumn get json => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {tripId};
}

/// 여행 스냅샷 JSON. 좌표(location)는 저장 전에 지운다 (features/sync-offline.md 5.1).
class CachedSnapshots extends Table {
  TextColumn get tripId => text()();
  TextColumn get json => text()();
  DateTimeColumn get syncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {tripId};
}

/// 오프라인 열람용 기기 DB. 서버 응답의 사본일 뿐이고, 진실 원천은 서버다.
///
/// 항목을 컬럼으로 나누지 않고 응답 JSON을 여행 단위로 통째로 저장한다 (5.2).
@DriftDatabase(tables: [CacheMeta, CachedTrips, CachedSnapshots])
class CacheDatabase extends _$CacheDatabase {
  new(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    // 지운 행의 내용이 파일의 빈 공간에 남지 않게 0으로 덮는다 (T34)
    beforeOpen: (_) => customStatement('PRAGMA secure_delete = ON'),
  );
}

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/core/storage/cache_db.dart';
import 'package:travelcopilot/features/places/data/place_models.dart';
import 'package:travelcopilot/features/trips/data/trip_cache.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';

import '../itinerary/itinerary_fixtures.dart';
import 'trip_fixtures.dart';

final _synced = DateTime.utc(2026, 11, 15, 9);

TripSnapshot _snapshot({String id = 't1', String title = '파리 가족여행'}) => TripSnapshot(
  trip: makeTrip(id: id, title: title),
  members: [makeMember('me', '나여행', TripRole.owner)],
  items: [
    makeItem(
      placeId: 'ChIJLU7jZClu5kcR4PcOOO6p3I0',
      memo: '야간 개장',
    ).copyWith(location: const LatLng(lat: 48.8584, lng: 2.2945)),
  ],
);

void main() {
  group('저장 내용 (features/sync-offline.md 5.1)', () {
    late TripCache cache;

    setUp(() => cache = TripCache.memory());
    tearDown(() => cache.close());

    test('cached_snapshot_has_no_location: 좌표는 지우고 place_id·제목·메모는 남긴다', () async {
      await cache.saveSnapshot(_snapshot(), _synced);

      final cached = (await cache.readSnapshot('t1'))!;
      expect(cached.data.items.single.location, isNull);
      expect(cached.data.items.single.placeId, 'ChIJLU7jZClu5kcR4PcOOO6p3I0');
      expect(cached.data.items.single.memo, '야간 개장');
      expect(cached.syncedAt.isAtSameMomentAs(_synced), isTrue);
    });

    test('목록을 순서대로 저장하고 동기화 시각과 함께 읽는다', () async {
      expect(await cache.readTrips(), isNull);
      await cache.replaceTrips([makeTrip(id: 'b'), makeTrip(id: 'a')], _synced);

      final cached = (await cache.readTrips())!;
      expect(cached.data.map((t) => t.id), ['b', 'a']);
      expect(cached.syncedAt.isAtSameMomentAs(_synced), isTrue);
    });

    test('빈 목록도 "받은 적 있음"으로 저장한다', () async {
      await cache.replaceTrips([], _synced);
      expect((await cache.readTrips())!.data, isEmpty);
    });
  });

  group('기기 데이터 정리 (5.7, T08)', () {
    late TripCache cache;

    setUp(() => cache = TripCache.memory());
    tearDown(() => cache.close());

    test('list_refresh_removes_missing_trips: 목록에 없는 여행의 행과 스냅샷을 지운다', () async {
      await cache.replaceTrips([makeTrip(id: 'a'), makeTrip(id: 'b')], _synced);
      await cache.saveSnapshot(_snapshot(id: 'a'), _synced);
      await cache.saveSnapshot(_snapshot(id: 'b'), _synced);

      final removed = await cache.replaceTrips([makeTrip(id: 'a')], _synced);

      expect(removed, 1);
      expect((await cache.readTrips())!.data.map((t) => t.id), ['a']);
      expect(await cache.readSnapshot('a'), isNotNull);
      expect(await cache.readSnapshot('b'), isNull);
    });

    test('not_found_removes_trip_cache: 여행 하나를 지운다', () async {
      await cache.replaceTrips([makeTrip(id: 'a'), makeTrip(id: 'b')], _synced);
      await cache.saveSnapshot(_snapshot(id: 'a'), _synced);

      await cache.removeTrip('a');

      expect((await cache.readTrips())!.data.map((t) => t.id), ['b']);
      expect(await cache.readSnapshot('a'), isNull);
    });
  });

  group('계정 전환 (T34)', () {
    late TripCache cache;

    setUp(() => cache = TripCache.memory());
    tearDown(() => cache.close());

    test('other_account_login_wipes_cache: 주인이 다르면 전부 지운다', () async {
      await cache.claim('alice');
      await cache.replaceTrips([makeTrip()], _synced);
      await cache.saveSnapshot(_snapshot(), _synced);

      await cache.claim('bob');

      expect(await cache.readTrips(), isNull);
      expect(await cache.readSnapshot('t1'), isNull);
    });

    test('same_account_relogin_keeps_cache: 같은 계정이면 그대로 쓴다', () async {
      await cache.claim('alice');
      await cache.replaceTrips([makeTrip()], _synced);

      await cache.claim('alice');

      expect((await cache.readTrips())!.data, hasLength(1));
    });
  });

  group('파일 DB (5.7·5.8)', () {
    late Directory root;
    late Directory dir;
    late TripCache cache;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('trip_cache_test');
      dir = Directory('${root.path}/trip_cache');
      cache = TripCache(directory: () async => dir, openFile: NativeDatabase.new);
    });

    tearDown(() async {
      await cache.close();
      if (root.existsSync()) await root.delete(recursive: true);
    });

    test('secure_delete_enabled: 지운 자리를 0으로 덮는 설정이 켜져 있다', () async {
      await cache.replaceTrips([makeTrip()], _synced);
      await cache.close();

      final db = CacheDatabase(NativeDatabase(File('${dir.path}/trip_cache.sqlite')));
      addTearDown(db.close);
      final row = await db.customSelect('PRAGMA secure_delete').getSingle();
      expect(row.data.values.single, 1);
    });

    test('지운 여행의 제목이 DB 파일 바이트에 남지 않는다', () async {
      const marker = 'ZZ-DELETED-TRIP-MARKER-7f3a';
      await cache.replaceTrips([
        makeTrip(id: 'gone', title: marker),
        makeTrip(id: 'keep'),
      ], _synced);
      await cache.saveSnapshot(_snapshot(id: 'gone', title: marker), _synced);
      final file = File('${dir.path}/trip_cache.sqlite');
      expect(latin1.decode(file.readAsBytesSync()), contains(marker)); // 대조군

      await cache.replaceTrips([makeTrip(id: 'keep')], _synced);
      await cache.close();

      expect(latin1.decode(file.readAsBytesSync()), isNot(contains(marker)));
    });

    test('해석할 수 없는 스냅샷(형식 변경 등)은 지우고 캐시 없음으로 다룬다', () async {
      await cache.saveSnapshot(_snapshot(), _synced);
      await cache.close();
      final db = CacheDatabase(NativeDatabase(File('${dir.path}/trip_cache.sqlite')));
      await (db.update(db.cachedSnapshots)..where((t) => t.tripId.equals('t1'))).write(
        const CachedSnapshotsCompanion(json: Value('{"trip": 1}')),
      );
      await db.close();

      expect(await cache.readSnapshot('t1'), isNull);
      await cache.close();
      final check = CacheDatabase(NativeDatabase(File('${dir.path}/trip_cache.sqlite')));
      addTearDown(check.close);
      expect(await check.select(check.cachedSnapshots).get(), isEmpty);
    });

    test('logout_deletes_db_files: 전체 삭제는 DB 폴더째 지우고, 다시 쓰면 새로 만든다', () async {
      await cache.replaceTrips([makeTrip()], _synced);
      expect(File('${dir.path}/trip_cache.sqlite').existsSync(), isTrue);

      await cache.wipe();

      expect(dir.existsSync(), isFalse);
      expect(await cache.readTrips(), isNull);
      expect(dir.existsSync(), isTrue); // 다시 열면 빈 DB
    });
  });
}

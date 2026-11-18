import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/logging/app_logger.dart';
import 'package:travelcopilot/core/state/provider_retry.dart';
import 'package:travelcopilot/features/places/data/place_models.dart';
import 'package:travelcopilot/features/trips/data/trip_cache.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/data/trips_api.dart';
import 'package:travelcopilot/features/trips/data/trips_repository.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';

import '../itinerary/itinerary_fixtures.dart';
import 'trip_fixtures.dart';

class _MockTripsApi extends Mock implements TripsApi;

final _now = DateTime(2026, 11, 15, 9);

TripSnapshot _snapshot({String id = 't1', String title = '파리 가족여행', String memo = '야간 개장'}) =>
    TripSnapshot(
      trip: makeTrip(id: id, title: title),
      members: const [],
      items: [
        makeItem(placeId: 'p1', memo: memo).copyWith(location: const LatLng(lat: 48.8, lng: 2.3)),
      ],
    );

void main() {
  late _MockTripsApi api;
  late TripCache cache;
  late TripsRepository repository;

  setUp(() {
    api = _MockTripsApi();
    cache = TripCache.memory();
    repository = TripsRepository(api: api, cache: cache, clock: () => _now, prefetchLimit: 3);
    when(() => api.snapshot(any())).thenAnswer(
      (invocation) async => _snapshot(id: invocation.positionalArguments.first as String),
    );
  });

  tearDown(() => cache.close());

  group('목록 (features/sync-offline.md 5.3·5.7)', () {
    test('partial_list_failure_keeps_cache: 목록을 끝까지 못 받으면 캐시를 지우지 않는다', () async {
      when(api.fetchAll).thenAnswer((_) async => [makeTrip(id: 'a'), makeTrip(id: 'b')]);
      await repository.refreshTrips();
      // 다음 갱신에서 둘째 페이지가 실패: TripsApi.fetchAll이 예외를 던진다
      when(api.fetchAll).thenThrow(const NetworkException());

      await expectLater(repository.refreshTrips(), throwsA(isA<NetworkException>()));

      expect((await repository.cachedTrips())!.data.map((t) => t.id), ['a', 'b']);
    });

    test('갱신에 성공하면 목록에서 사라진 여행의 캐시를 지운다', () async {
      when(api.fetchAll).thenAnswer((_) async => [makeTrip(id: 'a'), makeTrip(id: 'b')]);
      await repository.refreshTrips();
      await repository.refreshSnapshot('b');
      when(api.fetchAll).thenAnswer((_) async => [makeTrip(id: 'a')]);

      await repository.refreshTrips();

      expect((await repository.cachedTrips())!.data.map((t) => t.id), ['a']);
      expect(await repository.cachedSnapshot('b'), isNull);
    });
  });

  group('스냅샷', () {
    test('서버 원본(좌표 포함)을 돌려주고, 캐시에는 좌표 없이 저장한다', () async {
      final fresh = await repository.refreshSnapshot('t1');

      expect(fresh.data.items.single.location, isNotNull);
      expect((await repository.cachedSnapshot('t1'))!.data.items.single.location, isNull);
    });

    test('404면 그 여행 캐시를 지우고 예외를 다시 던진다', () async {
      when(api.fetchAll).thenAnswer((_) async => [makeTrip()]);
      await repository.refreshTrips();
      await repository.refreshSnapshot('t1');
      when(() => api.snapshot('t1'))
          .thenThrow(const ServerException(statusCode: 404, code: 'trip_not_found'));

      await expectLater(repository.refreshSnapshot('t1'), throwsA(isA<ServerException>()));

      expect(await repository.cachedSnapshot('t1'), isNull);
      expect((await repository.cachedTrips())!.data, isEmpty);
    });

    test('네트워크 오류면 캐시는 그대로 둔다', () async {
      await repository.refreshSnapshot('t1');
      when(() => api.snapshot('t1')).thenThrow(const NetworkException());

      await expectLater(repository.refreshSnapshot('t1'), throwsA(isA<NetworkException>()));

      expect(await repository.cachedSnapshot('t1'), isNotNull);
    });
  });

  group('미리 받기 (5.6)', () {
    test('끝나지 않은 여행만, 시작일이 가까운 순으로 최대 N개', () async {
      final trips = [
        makeTrip(id: 'past', start: DateTime(2026, 10), end: DateTime(2026, 10, 5)),
        makeTrip(id: 'ongoing', start: DateTime(2026, 11, 10), end: DateTime(2026, 11, 15)),
        makeTrip(id: 'far', start: DateTime(2027, 5), end: DateTime(2027, 5, 3)),
        makeTrip(id: 'soon', start: DateTime(2026, 12), end: DateTime(2026, 12, 3)),
        makeTrip(id: 'later', start: DateTime(2027, 1, 2), end: DateTime(2027, 1, 3)),
      ];

      await repository.prefetch(trips);

      verify(() => api.snapshot('ongoing')).called(1);
      verify(() => api.snapshot('soon')).called(1);
      verify(() => api.snapshot('later')).called(1);
      verifyNever(() => api.snapshot('far')); // 4번째라 제외 (최대 3개)
      verifyNever(() => api.snapshot('past'));
      expect(await repository.cachedSnapshot('soon'), isNotNull);
    });

    test('실패해도 예외를 밖으로 내지 않는다', () async {
      when(() => api.snapshot(any())).thenThrow(const NetworkException());

      await repository.prefetch([makeTrip(start: DateTime(2026, 12), end: DateTime(2026, 12, 2))]);
    });
  });

  test('캐시 동작 로그에 여행 제목·메모가 남지 않는다 (5.9)', () async {
    const title = '비밀여행-제목-로그검사';
    const memo = '예약번호-AB12345';
    final records = <LogRecord>[];
    setupLogging(sink: records.add);
    addTearDown(() => setupLogging(sink: (_) {}));
    when(api.fetchAll).thenAnswer((_) async => [makeTrip(title: title)]);
    when(() => api.snapshot('t1')).thenAnswer((_) async => _snapshot(title: title, memo: memo));

    await repository.refreshTrips();
    await repository.refreshSnapshot('t1');
    when(api.fetchAll).thenAnswer((_) async => []);
    await repository.refreshTrips();
    await cache.claim('someone');
    await cache.claim('other');

    expect(records, isNotEmpty);
    for (final record in records) {
      expect(record.message, isNot(contains(title)));
      expect(record.message, isNot(contains(memo)));
    }
  });

  group('provider: 캐시 먼저, 온라인이면 갱신 (5.3)', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        retry: disableAutoRetry,
        overrides: [
          tripsApiProvider.overrideWithValue(api),
          tripCacheProvider.overrideWithValue(cache),
        ],
      );
    });

    tearDown(() => container.dispose());

    test('캐시가 있으면 캐시를 먼저 내보내고 서버 값으로 바꾼다', () async {
      await cache.replaceTrips([makeTrip(title: '캐시 제목')], DateTime(2026, 11, 14));
      when(api.fetchAll).thenAnswer((_) async => [makeTrip(title: '서버 제목')]);
      final seen = <String>[];
      container.listen(tripListProvider, (_, next) {
        if (next.hasValue) seen.add(next.value!.single.title);
      }, fireImmediately: true);

      await container.read(tripListProvider.future);
      await pumpEventQueue();

      expect(seen, ['캐시 제목', '서버 제목']);
      expect(container.read(syncTimesProvider)[tripListSyncKey], isNotNull);
    });

    test('오프라인이면 캐시를 그대로 보여주고 마지막 동기화 시각을 남긴다', () async {
      final synced = DateTime(2026, 11, 14, 6);
      await cache.replaceTrips([makeTrip(title: '캐시 제목')], synced);
      when(api.fetchAll).thenThrow(const NetworkException());
      container.listen(tripListProvider, (_, _) {});

      final trips = await container.read(tripListProvider.future);
      await pumpEventQueue();

      expect(trips.single.title, '캐시 제목');
      expect(container.read(tripListProvider).hasError, isFalse);
      expect(container.read(syncTimesProvider)[tripListSyncKey]!.isAtSameMomentAs(synced), isTrue);
    });

    test('캐시도 없고 오프라인이면 오류', () async {
      when(api.fetchAll).thenThrow(const NetworkException());
      container.listen(tripListProvider, (_, _) {});

      await expectLater(container.read(tripListProvider.future), throwsA(isA<NetworkException>()));
    });

    test('스냅샷 갱신이 404면 캐시를 보여주던 화면도 오류로 바뀐다', () async {
      await cache.saveSnapshot(_snapshot(), DateTime(2026, 11, 14));
      when(() => api.snapshot('t1'))
          .thenThrow(const ServerException(statusCode: 404, code: 'trip_not_found'));
      container.listen(tripSnapshotProvider('t1'), (_, _) {});

      await container.read(tripSnapshotProvider('t1').future);
      await pumpEventQueue();

      final state = container.read(tripSnapshotProvider('t1'));
      expect(state.error, isA<ServerException>());
      expect(await cache.readSnapshot('t1'), isNull);
    });
  });
}

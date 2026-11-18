import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/trips/data/trip_cache.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/data/trips_repository.dart';

part 'trips_providers.g.dart';

final _log = Logger('TripsProviders');

/// 오프라인 배너가 보여줄 "마지막 동기화" 시각. 키는 [tripListSyncKey] 또는 여행 ID.
@Riverpod(keepAlive: true)
class SyncTimes extends _$SyncTimes {
  @override
  Map<String, DateTime> build() => const {};

  void mark(String key, DateTime syncedAt) => state = {...state, key: syncedAt};
}

const tripListSyncKey = 'trips';

/// 내 여행 목록. 캐시가 있으면 먼저 내보내고 뒤에서 서버 값으로 바꾼다 (features/sync-offline.md 5.3).
///
/// 여행을 만들거나 지우거나 나가면 무효화해서 다시 받는다.
@riverpod
class TripList extends _$TripList {
  @override
  Future<List<Trip>> build() async {
    final cached = await ref.watch(tripsRepositoryProvider).cachedTrips();
    if (cached == null) return (await _fetch()).data;
    _mark(cached);
    unawaited(Future(_refreshInBackground));
    return cached.data;
  }

  /// 당겨서 새로고침·[다시 시도]. 실패하면(오프라인 등) 지금 값을 그대로 둔다.
  Future<void> refresh() async {
    if (!state.hasValue) {
      ref.invalidateSelf();
      await future.then((_) {}, onError: (Object _) {});
      return;
    }
    await _refreshInBackground();
  }

  Future<Cached<List<Trip>>> _fetch() async {
    final fresh = await ref.read(tripsRepositoryProvider).refreshTrips();
    _mark(fresh);
    return fresh;
  }

  Future<void> _refreshInBackground() async {
    try {
      final fresh = await _fetch();
      if (ref.mounted) state = AsyncData(fresh.data);
    } on AppException catch (error) {
      _log.info('목록 갱신 실패: ${error is ServerException ? error.code : error.runtimeType}');
    }
  }

  void _mark(Cached<List<Trip>> value) {
    if (ref.mounted) ref.read(syncTimesProvider.notifier).mark(tripListSyncKey, value.syncedAt);
  }
}

/// 여행 스냅샷 (여행 정보 + 멤버 + 전체 일정). 캐시 먼저, 온라인이면 갱신.
///
/// 수정 작업 뒤에는 무효화해서 다시 받는다. 캐시에서 온 값에는 좌표가 없다.
@riverpod
class TripSnapshotNotifier extends _$TripSnapshotNotifier {
  @override
  Future<TripSnapshot> build(String tripId) async {
    final cached = await ref.watch(tripsRepositoryProvider).cachedSnapshot(tripId);
    if (cached == null) return (await _fetch()).data;
    _mark(cached);
    unawaited(Future(_refreshInBackground));
    return cached.data;
  }

  /// 당겨서 새로고침. 실패하면(오프라인 등) 지금 값을 그대로 둔다.
  Future<void> refresh() async {
    if (!state.hasValue) {
      ref.invalidateSelf();
      await future.then((_) {}, onError: (Object _) {});
      return;
    }
    await _refreshInBackground();
  }

  Future<Cached<TripSnapshot>> _fetch() async {
    final fresh = await ref.read(tripsRepositoryProvider).refreshSnapshot(tripId);
    _mark(fresh);
    return fresh;
  }

  Future<void> _refreshInBackground() async {
    try {
      final fresh = await _fetch();
      if (ref.mounted) state = AsyncData(fresh.data);
    } on ServerException catch (error, stack) {
      _log.info('스냅샷 갱신 실패: ${error.code}');
      // 내보내졌거나 삭제됨: 캐시는 이미 지웠고, 화면도 "접근할 수 없는 여행"으로 바꾼다
      if (error.statusCode == 404 && ref.mounted) state = AsyncError(error, stack);
    } on AppException catch (error) {
      _log.info('스냅샷 갱신 실패: ${error.runtimeType}');
    }
  }

  void _mark(Cached<TripSnapshot> value) {
    if (ref.mounted) ref.read(syncTimesProvider.notifier).mark(tripId, value.syncedAt);
  }
}

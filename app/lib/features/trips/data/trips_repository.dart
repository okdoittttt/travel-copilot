import 'dart:async';

import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/trips/data/trip_cache.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/data/trips_api.dart';

part 'trips_repository.g.dart';

final _log = Logger('TripsRepository');

/// 여행 목록·스냅샷의 "캐시 먼저, 온라인이면 갱신" (features/sync-offline.md 5.3).
///
/// 캐시는 **서버 응답이 성공했을 때만** 그 응답으로 바꾼다. 수정 요청 중에 캐시를 먼저 고치지 않는다.
class TripsRepository {
  new({
    required this._api,
    required this._cache,
    DateTime Function()? clock,
    this.prefetchLimit = 10,
  }) : _clock = clock ?? DateTime.now;

  final TripsApi _api;
  final TripCache _cache;
  final DateTime Function() _clock;

  /// 목록 갱신 뒤 미리 받아 둘 스냅샷 수 (5.6).
  final int prefetchLimit;

  static const _prefetchConcurrency = 2;

  Future<Cached<List<Trip>>?> cachedTrips() => _cache.readTrips();

  /// 서버에서 **모든 페이지**를 받아 캐시를 바꾸고, 끝나지 않은 여행의 스냅샷을 뒤에서 받아 둔다.
  ///
  /// 한 페이지라도 실패하면 예외가 나서 캐시는 그대로 남는다 (T08: 일부만 받고 지우지 않기).
  Future<Cached<List<Trip>>> refreshTrips() async {
    final trips = await _api.fetchAll();
    final now = _clock();
    final removed = await _cache.replaceTrips(trips, now);
    if (removed > 0) _log.info('목록에서 사라진 여행 캐시 삭제: $removed개');
    unawaited(prefetch(trips));
    return (data: trips, syncedAt: now);
  }

  Future<Cached<TripSnapshot>?> cachedSnapshot(String tripId) => _cache.readSnapshot(tripId);

  /// 서버에서 스냅샷을 받아 캐시에 저장한다. 404면 그 여행 캐시를 지우고 예외를 다시 던진다.
  ///
  /// 돌려주는 값은 서버 원본(좌표 포함)이다. 좌표는 메모리에서만 쓴다.
  Future<Cached<TripSnapshot>> refreshSnapshot(String tripId) async {
    try {
      final snapshot = await _api.snapshot(tripId);
      final now = _clock();
      await _cache.saveSnapshot(snapshot, now);
      return (data: snapshot, syncedAt: now);
    } on ServerException catch (error) {
      if (error.statusCode == 404) await forgetTrip(tripId);
      rethrow;
    }
  }

  /// 내보내졌거나 삭제됐거나 내가 나간 여행의 캐시를 지운다.
  Future<void> forgetTrip(String tripId) => _cache.removeTrip(tripId);

  /// 끝나지 않은 여행(`end_date >= 오늘`)의 스냅샷을 시작일이 가까운 순으로 받아 둔다 (5.6).
  ///
  /// 실패해도 화면에 알리지 않는다. 로그에는 결과 코드만 남긴다.
  Future<void> prefetch(List<Trip> trips) async {
    final now = _clock();
    final today = DateTime(now.year, now.month, now.day);
    final targets = [
      for (final trip in trips)
        if (!trip.endDate.isBefore(today)) trip,
    ]..sort((a, b) => a.startDate.compareTo(b.startDate));
    final queue = targets.take(prefetchLimit).toList();
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final trip = queue.removeAt(0);
        try {
          await refreshSnapshot(trip.id);
        } on AppException catch (error) {
          _log.info('스냅샷 미리 받기 실패: ${error is ServerException ? error.code : error.runtimeType}');
        }
      }
    }

    await Future.wait([for (var i = 0; i < _prefetchConcurrency; i++) worker()]);
  }
}

@Riverpod(keepAlive: true)
TripsRepository tripsRepository(Ref ref) =>
    TripsRepository(api: ref.watch(tripsApiProvider), cache: ref.watch(tripCacheProvider));

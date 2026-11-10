import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/api/api_client.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';

part 'trips_api.g.dart';

/// 여행·멤버 서버 API 호출. 실패는 모두 [AppException]으로 바꿔서 던진다.
class TripsApi {
  new(this._dio);

  final Dio _dio;

  static const _pageSize = 50;

  /// 내가 멤버인 여행을 모든 페이지에 걸쳐 받는다 (features/trips.md 5.4).
  Future<List<Trip>> fetchAll() => _call(() async {
    final trips = <Trip>[];
    String? cursor;
    do {
      final response = await _dio.get<Map<String, dynamic>>(
        '/trips',
        queryParameters: {'limit': _pageSize, 'cursor': ?cursor},
      );
      final data = response.data!;
      trips.addAll(
        (data['items'] as List<dynamic>).map((e) => Trip.fromJson(e as Map<String, dynamic>)),
      );
      cursor = data['next_cursor'] as String?;
    } while (cursor != null);
    return trips;
  });

  Future<Trip> create(TripDraft draft) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>('/trips', data: draft.toJson());
    return Trip.fromJson(response.data!);
  });

  Future<TripSnapshot> snapshot(String tripId) => _call(() async {
    final response = await _dio.get<Map<String, dynamic>>('/trips/$tripId');
    return TripSnapshot.fromJson(response.data!);
  });

  /// 바뀐 필드만 보낸다. version이 다르면 `409 version_conflict`.
  Future<Trip> update(String tripId, int version, Map<String, dynamic> changes) => _call(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/trips/$tripId',
      data: {'version': version, ...changes},
    );
    return Trip.fromJson(response.data!);
  });

  Future<void> delete(String tripId, int version) => _call(() async {
    await _dio.delete<void>('/trips/$tripId', queryParameters: {'version': version});
  });

  Future<TripMember> changeRole(String tripId, String userId, TripRole role) => _call(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/trips/$tripId/members/$userId',
      data: {'role': role.name},
    );
    return TripMember.fromJson(response.data!);
  });

  /// owner가 내보내거나, 본인이 나간다.
  Future<void> removeMember(String tripId, String userId) => _call(() async {
    await _dio.delete<void>('/trips/$tripId/members/$userId');
  });

  Future<TripSnapshot> transferOwnership(String tripId, String userId) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/trips/$tripId/transfer-ownership',
      data: {'user_id': userId},
    );
    return TripSnapshot.fromJson(response.data!);
  });

  static Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }
}

@Riverpod(keepAlive: true)
TripsApi tripsApi(Ref ref) => TripsApi(ref.watch(apiClientProvider));

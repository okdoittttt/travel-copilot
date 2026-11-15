import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/api/api_client.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';

part 'itinerary_api.g.dart';

/// 일정 항목 서버 API. 실패는 모두 [AppException]으로 바꿔서 던진다.
class ItineraryApi {
  new(this._dio);

  final Dio _dio;

  Future<ItineraryItem> create(String tripId, ItemDraft draft) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/trips/$tripId/items',
      data: draft.toJson(),
    );
    return ItineraryItem.fromJson(response.data!);
  });

  Future<ItineraryItem> update(
    String tripId,
    String itemId,
    int version,
    Map<String, dynamic> changes,
  ) => _call(() async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/trips/$tripId/items/$itemId',
      data: {'version': version, ...changes},
    );
    return ItineraryItem.fromJson(response.data!);
  });

  Future<void> delete(String tripId, String itemId, int version) => _call(() async {
    await _dio.delete<void>('/trips/$tripId/items/$itemId', queryParameters: {'version': version});
  });

  /// 하루 일정 + 이동 구간. 이동시간은 서버가 요청마다 계산한다 (저장 안 함).
  Future<DayView> day(String tripId, DateTime day) => _call(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/trips/$tripId/days/${formatDateOnly(day)}',
    );
    return DayView.fromJson(response.data!);
  });

  /// 그날의 모든 항목을 새 순서대로 보낸다.
  Future<DayItems> reorder(String tripId, DateTime day, List<ItineraryItem> ordered) =>
      _call(() async {
        final response = await _dio.put<Map<String, dynamic>>(
          '/trips/$tripId/days/${formatDateOnly(day)}/order',
          data: {
            'items': [
              for (final item in ordered) {'id': item.id, 'version': item.version},
            ],
          },
        );
        return DayItems.fromJson(response.data!);
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
ItineraryApi itineraryApi(Ref ref) => ItineraryApi(ref.watch(apiClientProvider));

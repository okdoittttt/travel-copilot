import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/api/api_client.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/places/data/place_models.dart';

part 'places_api.g.dart';

/// 장소 검색 서버 API. Google은 서버가 대신 부른다 (API 키는 앱에 없음, T20).
class PlacesApi {
  new(this._dio);

  final Dio _dio;

  Future<List<PlaceSuggestion>> autocomplete(String query, {String? sessionToken, LatLng? bias}) =>
      _call(() async {
        final response = await _dio.get<Map<String, dynamic>>(
          '/places/autocomplete',
          queryParameters: {
            'q': query,
            'session_token': ?sessionToken,
            if (bias != null) ...{'lat': bias.lat, 'lng': bias.lng},
          },
        );
        return (response.data!['suggestions'] as List<dynamic>)
            .map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  /// 장소 상세. [sessionToken]을 주면 자동완성 과금 세션을 끝낸다.
  Future<PlaceInfo> details(String placeId, {String? sessionToken}) => _call(() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/places/$placeId',
      queryParameters: {'session_token': ?sessionToken},
    );
    return PlaceInfo.fromJson(response.data!);
  });

  static Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }
}

/// Google 과금 세션 토큰. 무작위 128비트를 URL에 안전한 문자로 (서버 규칙: 16~64자).
String newPlacesSessionToken([Random? random]) {
  final rng = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  return base64Url.encode(bytes).replaceAll('=', '');
}

@Riverpod(keepAlive: true)
PlacesApi placesApi(Ref ref) => PlacesApi(ref.watch(apiClientProvider));

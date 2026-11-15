import 'package:freezed_annotation/freezed_annotation.dart';

part 'place_models.freezed.dart';
part 'place_models.g.dart';

/// 좌표. Google 약관상 기기에 저장하지 않고 화면 표시에만 쓴다 (06-api 3.3).
@freezed
abstract class LatLng with _$LatLng {
  const factory({required double lat, required double lng}) = _LatLng;

  factory fromJson(Map<String, dynamic> json) => _$LatLngFromJson(json);
}

/// 자동완성 결과 한 줄.
@freezed
abstract class PlaceSuggestion with _$PlaceSuggestion {
  const factory({required String placeId, required String name, String? secondary}) =
      _PlaceSuggestion;

  factory fromJson(Map<String, dynamic> json) => _$PlaceSuggestionFromJson(json);
}

/// 장소 상세. 장소 이름은 Google 요금 때문에 서버가 주지 않는다 (features/itinerary.md 5.1).
@freezed
abstract class PlaceInfo with _$PlaceInfo {
  const factory({
    required String placeId,
    required LatLng location,
    required String mapsUrl,
    required String attribution,
    String? address,
  }) = _PlaceInfo;

  factory fromJson(Map<String, dynamic> json) => _$PlaceInfoFromJson(json);
}

/// 장소 검색에서 고른 결과. 이름은 자동완성에서 받은 값(제목 힌트용, 저장하지 않음).
@freezed
abstract class PlacePick with _$PlacePick {
  const factory({required String placeId, required String googleName, String? address}) =
      _PlacePick;
}

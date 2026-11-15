import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travelcopilot/features/places/data/place_models.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';

part 'itinerary_models.freezed.dart';
part 'itinerary_models.g.dart';

/// 이전 일정에서 이 일정까지의 이동수단.
enum TravelMode { drive, transit, walk }

/// 일정 항목. 제목·메모는 사용자 콘텐츠, Google에서 온 것은 placeId와 좌표뿐.
@freezed
abstract class ItineraryItem with _$ItineraryItem {
  const factory({
    required String id,
    @DateOnlyConverter() required DateTime day,
    required int position,
    required String title,
    required int version,
    required DateTime updatedAt,
    String? memo,
    String? placeId,
    LatLng? location,
    String? startTime,
    int? stayMinutes,
    TravelMode? travelMode,
  }) = _ItineraryItem;

  factory fromJson(Map<String, dynamic> json) => _$ItineraryItemFromJson(json);
}

/// 하루 일정 (순서 변경 응답).
@freezed
abstract class DayItems with _$DayItems {
  const factory({@DateOnlyConverter() required DateTime date, required List<ItineraryItem> items}) =
      _DayItems;

  factory fromJson(Map<String, dynamic> json) => _$DayItemsFromJson(json);
}

/// 일정 추가·수정 입력값. null은 "비어 있음"이고, 수정 때는 지우기로 보낸다.
@freezed
abstract class ItemDraft with _$ItemDraft {
  const factory({
    @DateOnlyConverter() required DateTime day,
    required String title,
    String? memo,
    String? placeId,
    String? startTime,
    int? stayMinutes,
    TravelMode? travelMode,
  }) = _ItemDraft;

  const new _();

  factory fromJson(Map<String, dynamic> json) => _$ItemDraftFromJson(json);

  factory fromItem(ItineraryItem item) => ItemDraft(
    day: item.day,
    title: item.title,
    memo: item.memo,
    placeId: item.placeId,
    startTime: item.startTime,
    stayMinutes: item.stayMinutes,
    travelMode: item.travelMode,
  );

  /// [base]와 달라진 필드만 (지운 필드는 null로 들어간다).
  Map<String, dynamic> changesFrom(ItemDraft base) {
    final mine = toJson();
    final theirs = base.toJson();
    return {
      for (final entry in mine.entries)
        if (entry.value != theirs[entry.key]) entry.key: entry.value,
    };
  }
}

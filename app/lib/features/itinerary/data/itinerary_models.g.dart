// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ItineraryItem _$ItineraryItemFromJson(Map<String, dynamic> json) => _ItineraryItem(
  id: json['id'] as String,
  day: const DateOnlyConverter().fromJson(json['day'] as String),
  position: (json['position'] as num).toInt(),
  title: json['title'] as String,
  version: (json['version'] as num).toInt(),
  updatedAt: DateTime.parse(json['updated_at'] as String),
  memo: json['memo'] as String?,
  placeId: json['place_id'] as String?,
  location: json['location'] == null
      ? null
      : LatLng.fromJson(json['location'] as Map<String, dynamic>),
  startTime: json['start_time'] as String?,
  stayMinutes: (json['stay_minutes'] as num?)?.toInt(),
  travelMode: $enumDecodeNullable(_$TravelModeEnumMap, json['travel_mode']),
);

Map<String, dynamic> _$ItineraryItemToJson(_ItineraryItem instance) => <String, dynamic>{
  'id': instance.id,
  'day': const DateOnlyConverter().toJson(instance.day),
  'position': instance.position,
  'title': instance.title,
  'version': instance.version,
  'updated_at': instance.updatedAt.toIso8601String(),
  'memo': instance.memo,
  'place_id': instance.placeId,
  'location': instance.location,
  'start_time': instance.startTime,
  'stay_minutes': instance.stayMinutes,
  'travel_mode': _$TravelModeEnumMap[instance.travelMode],
};

const _$TravelModeEnumMap = {
  TravelMode.drive: 'drive',
  TravelMode.transit: 'transit',
  TravelMode.walk: 'walk',
};

_DayItems _$DayItemsFromJson(Map<String, dynamic> json) => _DayItems(
  date: const DateOnlyConverter().fromJson(json['date'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DayItemsToJson(_DayItems instance) => <String, dynamic>{
  'date': const DateOnlyConverter().toJson(instance.date),
  'items': instance.items,
};

_ItemDraft _$ItemDraftFromJson(Map<String, dynamic> json) => _ItemDraft(
  day: const DateOnlyConverter().fromJson(json['day'] as String),
  title: json['title'] as String,
  memo: json['memo'] as String?,
  placeId: json['place_id'] as String?,
  startTime: json['start_time'] as String?,
  stayMinutes: (json['stay_minutes'] as num?)?.toInt(),
  travelMode: $enumDecodeNullable(_$TravelModeEnumMap, json['travel_mode']),
);

Map<String, dynamic> _$ItemDraftToJson(_ItemDraft instance) => <String, dynamic>{
  'day': const DateOnlyConverter().toJson(instance.day),
  'title': instance.title,
  'memo': instance.memo,
  'place_id': instance.placeId,
  'start_time': instance.startTime,
  'stay_minutes': instance.stayMinutes,
  'travel_mode': _$TravelModeEnumMap[instance.travelMode],
};

_RouteLeg _$RouteLegFromJson(Map<String, dynamic> json) => _RouteLeg(
  fromItemId: json['from_item_id'] as String,
  toItemId: json['to_item_id'] as String,
  status: $enumDecode(_$LegStatusEnumMap, json['status']),
  mode: $enumDecodeNullable(_$TravelModeEnumMap, json['mode']),
  durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  distanceMeters: (json['distance_meters'] as num?)?.toInt(),
);

Map<String, dynamic> _$RouteLegToJson(_RouteLeg instance) => <String, dynamic>{
  'from_item_id': instance.fromItemId,
  'to_item_id': instance.toItemId,
  'status': _$LegStatusEnumMap[instance.status]!,
  'mode': _$TravelModeEnumMap[instance.mode],
  'duration_seconds': instance.durationSeconds,
  'distance_meters': instance.distanceMeters,
};

const _$LegStatusEnumMap = {
  LegStatus.ok: 'ok',
  LegStatus.noLocation: 'no_location',
  LegStatus.noMode: 'no_mode',
  LegStatus.unavailable: 'unavailable',
};

_DayView _$DayViewFromJson(Map<String, dynamic> json) => _DayView(
  date: const DateOnlyConverter().fromJson(json['date'] as String),
  items: (json['items'] as List<dynamic>)
      .map((e) => ItineraryItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  legs: (json['legs'] as List<dynamic>)
      .map((e) => RouteLeg.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DayViewToJson(_DayView instance) => <String, dynamic>{
  'date': const DateOnlyConverter().toJson(instance.date),
  'items': instance.items,
  'legs': instance.legs,
};

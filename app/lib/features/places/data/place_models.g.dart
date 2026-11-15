// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'place_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LatLng _$LatLngFromJson(Map<String, dynamic> json) =>
    _LatLng(lat: (json['lat'] as num).toDouble(), lng: (json['lng'] as num).toDouble());

Map<String, dynamic> _$LatLngToJson(_LatLng instance) => <String, dynamic>{
  'lat': instance.lat,
  'lng': instance.lng,
};

_PlaceSuggestion _$PlaceSuggestionFromJson(Map<String, dynamic> json) => _PlaceSuggestion(
  placeId: json['place_id'] as String,
  name: json['name'] as String,
  secondary: json['secondary'] as String?,
);

Map<String, dynamic> _$PlaceSuggestionToJson(_PlaceSuggestion instance) => <String, dynamic>{
  'place_id': instance.placeId,
  'name': instance.name,
  'secondary': instance.secondary,
};

_PlaceInfo _$PlaceInfoFromJson(Map<String, dynamic> json) => _PlaceInfo(
  placeId: json['place_id'] as String,
  location: LatLng.fromJson(json['location'] as Map<String, dynamic>),
  mapsUrl: json['maps_url'] as String,
  attribution: json['attribution'] as String,
  address: json['address'] as String?,
);

Map<String, dynamic> _$PlaceInfoToJson(_PlaceInfo instance) => <String, dynamic>{
  'place_id': instance.placeId,
  'location': instance.location,
  'maps_url': instance.mapsUrl,
  'attribution': instance.attribution,
  'address': instance.address,
};

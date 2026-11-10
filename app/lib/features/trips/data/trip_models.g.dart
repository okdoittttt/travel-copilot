// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Trip _$TripFromJson(Map<String, dynamic> json) => _Trip(
  id: json['id'] as String,
  title: json['title'] as String,
  destination: json['destination'] as String,
  startDate: const DateOnlyConverter().fromJson(json['start_date'] as String),
  endDate: const DateOnlyConverter().fromJson(json['end_date'] as String),
  timezone: json['timezone'] as String,
  version: (json['version'] as num).toInt(),
  myRole: $enumDecode(_$TripRoleEnumMap, json['my_role']),
  memberCount: (json['member_count'] as num).toInt(),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$TripToJson(_Trip instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'destination': instance.destination,
  'start_date': const DateOnlyConverter().toJson(instance.startDate),
  'end_date': const DateOnlyConverter().toJson(instance.endDate),
  'timezone': instance.timezone,
  'version': instance.version,
  'my_role': _$TripRoleEnumMap[instance.myRole]!,
  'member_count': instance.memberCount,
  'updated_at': instance.updatedAt.toIso8601String(),
};

const _$TripRoleEnumMap = {
  TripRole.owner: 'owner',
  TripRole.editor: 'editor',
  TripRole.viewer: 'viewer',
};

_TripMember _$TripMemberFromJson(Map<String, dynamic> json) => _TripMember(
  userId: json['user_id'] as String,
  displayName: json['display_name'] as String,
  role: $enumDecode(_$TripRoleEnumMap, json['role']),
  joinedAt: DateTime.parse(json['joined_at'] as String),
);

Map<String, dynamic> _$TripMemberToJson(_TripMember instance) => <String, dynamic>{
  'user_id': instance.userId,
  'display_name': instance.displayName,
  'role': _$TripRoleEnumMap[instance.role]!,
  'joined_at': instance.joinedAt.toIso8601String(),
};

_TripSnapshot _$TripSnapshotFromJson(Map<String, dynamic> json) => _TripSnapshot(
  trip: Trip.fromJson(json['trip'] as Map<String, dynamic>),
  members: (json['members'] as List<dynamic>)
      .map((e) => TripMember.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TripSnapshotToJson(_TripSnapshot instance) => <String, dynamic>{
  'trip': instance.trip,
  'members': instance.members,
};

_TripDraft _$TripDraftFromJson(Map<String, dynamic> json) => _TripDraft(
  title: json['title'] as String,
  destination: json['destination'] as String,
  startDate: const DateOnlyConverter().fromJson(json['start_date'] as String),
  endDate: const DateOnlyConverter().fromJson(json['end_date'] as String),
  timezone: json['timezone'] as String,
);

Map<String, dynamic> _$TripDraftToJson(_TripDraft instance) => <String, dynamic>{
  'title': instance.title,
  'destination': instance.destination,
  'start_date': const DateOnlyConverter().toJson(instance.startDate),
  'end_date': const DateOnlyConverter().toJson(instance.endDate),
  'timezone': instance.timezone,
};

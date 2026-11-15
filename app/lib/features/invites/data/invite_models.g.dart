// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Invite _$InviteFromJson(Map<String, dynamic> json) => _Invite(
  id: json['id'] as String,
  role: $enumDecode(_$InviteRoleEnumMap, json['role']),
  maxUses: (json['max_uses'] as num).toInt(),
  useCount: (json['use_count'] as num).toInt(),
  expiresAt: DateTime.parse(json['expires_at'] as String),
  createdAt: DateTime.parse(json['created_at'] as String),
  status: $enumDecode(_$InviteStatusEnumMap, json['status']),
  revokedAt: json['revoked_at'] == null ? null : DateTime.parse(json['revoked_at'] as String),
  createdByName: json['created_by_name'] as String?,
);

Map<String, dynamic> _$InviteToJson(_Invite instance) => <String, dynamic>{
  'id': instance.id,
  'role': _$InviteRoleEnumMap[instance.role]!,
  'max_uses': instance.maxUses,
  'use_count': instance.useCount,
  'expires_at': instance.expiresAt.toIso8601String(),
  'created_at': instance.createdAt.toIso8601String(),
  'status': _$InviteStatusEnumMap[instance.status]!,
  'revoked_at': instance.revokedAt?.toIso8601String(),
  'created_by_name': instance.createdByName,
};

const _$InviteRoleEnumMap = {InviteRole.editor: 'editor', InviteRole.viewer: 'viewer'};

const _$InviteStatusEnumMap = {
  InviteStatus.active: 'active',
  InviteStatus.expired: 'expired',
  InviteStatus.revoked: 'revoked',
  InviteStatus.exhausted: 'exhausted',
};

_InvitePreview _$InvitePreviewFromJson(Map<String, dynamic> json) => _InvitePreview(
  tripTitle: json['trip_title'] as String,
  startDate: const DateOnlyConverter().fromJson(json['start_date'] as String),
  endDate: const DateOnlyConverter().fromJson(json['end_date'] as String),
  role: $enumDecode(_$InviteRoleEnumMap, json['role']),
  alreadyMember: json['already_member'] as bool,
  inviterName: json['inviter_name'] as String?,
  tripId: json['trip_id'] as String?,
);

Map<String, dynamic> _$InvitePreviewToJson(_InvitePreview instance) => <String, dynamic>{
  'trip_title': instance.tripTitle,
  'start_date': const DateOnlyConverter().toJson(instance.startDate),
  'end_date': const DateOnlyConverter().toJson(instance.endDate),
  'role': _$InviteRoleEnumMap[instance.role]!,
  'already_member': instance.alreadyMember,
  'inviter_name': instance.inviterName,
  'trip_id': instance.tripId,
};

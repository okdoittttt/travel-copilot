// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppUser _$AppUserFromJson(Map<String, dynamic> json) => _AppUser(
  id: json['id'] as String,
  displayName: json['display_name'] as String,
  email: json['email'] as String?,
);

Map<String, dynamic> _$AppUserToJson(_AppUser instance) => <String, dynamic>{
  'id': instance.id,
  'display_name': instance.displayName,
  'email': instance.email,
};

_AuthTokens _$AuthTokensFromJson(Map<String, dynamic> json) => _AuthTokens(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
);

Map<String, dynamic> _$AuthTokensToJson(_AuthTokens instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
};

_TokenResponse _$TokenResponseFromJson(Map<String, dynamic> json) => _TokenResponse(
  accessToken: json['access_token'] as String,
  refreshToken: json['refresh_token'] as String,
  expiresIn: (json['expires_in'] as num).toInt(),
  user: AppUser.fromJson(json['user'] as Map<String, dynamic>),
  isNewUser: json['is_new_user'] as bool? ?? false,
);

Map<String, dynamic> _$TokenResponseToJson(_TokenResponse instance) => <String, dynamic>{
  'access_token': instance.accessToken,
  'refresh_token': instance.refreshToken,
  'expires_in': instance.expiresIn,
  'user': instance.user,
  'is_new_user': instance.isNewUser,
};

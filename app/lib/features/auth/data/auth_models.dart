import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_models.freezed.dart';
part 'auth_models.g.dart';

/// 로그인한 사용자.
@freezed
abstract class AppUser with _$AppUser {
  const factory({required String id, required String displayName, String? email}) = _AppUser;

  factory fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

/// 서버가 발급한 토큰 한 쌍. 기기 보안 저장소에만 보관한다 (T18).
@freezed
abstract class AuthTokens with _$AuthTokens {
  const factory({required String accessToken, required String refreshToken}) = _AuthTokens;

  factory fromJson(Map<String, dynamic> json) => _$AuthTokensFromJson(json);
}

/// 로그인·토큰 갱신 응답.
@freezed
abstract class TokenResponse with _$TokenResponse {
  const factory({
    required String accessToken,
    required String refreshToken,
    required int expiresIn,
    required AppUser user,
    @Default(false) bool isNewUser,
  }) = _TokenResponse;

  const new _();

  factory fromJson(Map<String, dynamic> json) => _$TokenResponseFromJson(json);

  AuthTokens get tokens => AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
}

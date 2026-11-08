import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';

part 'token_storage.g.dart';

/// 토큰과 마지막 사용자 정보를 기기 보안 저장소(iOS Keychain / Android Keystore)에 보관한다.
///
/// iOS는 `first_unlock_this_device`: 기기 백업이나 다른 기기로 옮겨지지 않는다 (T18·T19).
/// 토큰 값은 절대 로그에 남기지 않는다 (T21).
class TokenStorage {
  new(this._storage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user';

  final FlutterSecureStorage _storage;

  static const options = FlutterSecureStorage(
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );

  Future<AuthTokens?> readTokens() async {
    final access = await _storage.read(key: _accessTokenKey);
    final refresh = await _storage.read(key: _refreshTokenKey);
    if (access == null || refresh == null) return null;
    return AuthTokens(accessToken: access, refreshToken: refresh);
  }

  Future<String?> readAccessToken() => _storage.read(key: _accessTokenKey);

  /// 오프라인에서 앱을 열 때 보여줄 마지막 사용자 정보.
  Future<AppUser?> readUser() async {
    final raw = await _storage.read(key: _userKey);
    if (raw == null) return null;
    return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    await _storage.write(key: _accessTokenKey, value: tokens.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokens.refreshToken);
  }

  Future<void> saveUser(AppUser user) =>
      _storage.write(key: _userKey, value: jsonEncode(user.toJson()));

  Future<void> clear() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userKey);
  }
}

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) => TokenStorage(TokenStorage.options);

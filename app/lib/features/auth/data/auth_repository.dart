import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/api/api_client.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/config/app_config.dart';
import 'package:travelcopilot/core/storage/token_storage.dart';
import 'package:travelcopilot/features/auth/data/auth_api.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';
import 'package:travelcopilot/features/auth/data/google_auth_client.dart';

part 'auth_repository.g.dart';

final _log = Logger('AuthRepository');

/// 로그인·로그아웃·세션 복원을 조합한다.
class AuthRepository {
  new({required this._api, required this._google, required this._storage});

  final AuthApi _api;
  final GoogleAuthClient _google;
  final TokenStorage _storage;

  /// 앱 시작 시 저장된 토큰으로 로그인 상태를 되살린다.
  ///
  /// 오프라인이면 마지막으로 저장한 사용자 정보로 로그인 상태를 유지한다.
  Future<AppUser?> restoreSession() async {
    if (await _storage.readTokens() == null) return null;
    try {
      final user = await _api.me();
      await _storage.saveUser(user);
      return user;
    } on NetworkException {
      return await _storage.readUser();
    } on ServerException catch (error) {
      if (error.statusCode == 401) {
        // 인터셉터가 갱신을 시도했고 실패해서 토큰을 지운 상태
        return null;
      }
      return await _storage.readUser();
    }
  }

  /// Google로 로그인한다. 사용자가 Google 창을 닫으면 null.
  Future<AppUser?> signInWithGoogle() async {
    final nonce = await _api.issueNonce();
    final idToken = await _google.signIn(nonce: nonce);
    if (idToken == null) return null;
    final response = await _api.loginWithGoogle(idToken);
    await _storage.saveTokens(response.tokens);
    await _storage.saveUser(response.user);
    return response.user;
  }

  /// 서버에서 리프레시 토큰을 폐기하고 기기의 로그인 정보를 지운다.
  ///
  /// 오프라인이어도 기기 정보는 반드시 지운다. 서버 폐기에 실패한 리프레시 토큰은
  /// 30일 뒤 만료된다 (features/auth.md 2절).
  Future<void> signOut() async {
    final tokens = await _storage.readTokens();
    if (tokens != null) {
      try {
        await _api.logout(tokens.refreshToken);
      } on AppException catch (error) {
        _log.info('서버 로그아웃 실패: ${error.runtimeType}');
      }
    }
    await _storage.clear();
    try {
      await _google.signOut();
    } on Exception catch (error) {
      _log.info('Google 로그아웃 실패: ${error.runtimeType}');
    }
  }
}

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) => AuthRepository(
  api: AuthApi(ref.watch(apiClientProvider)),
  google: GoogleAuthClient(
    serverClientId: AppConfig.googleServerClientId,
    iosClientId: AppConfig.googleIosClientId,
  ),
  storage: ref.watch(tokenStorageProvider),
);

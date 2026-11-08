import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:travelcopilot/core/storage/token_storage.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';

final _log = Logger('AuthInterceptor');

/// 토큰이 필요 없는 경로. 여기엔 Authorization 헤더를 붙이지 않는다.
const _publicPaths = {'/auth/nonce', '/auth/google/login', '/auth/refresh'};
const _retriedKey = 'auth_retried';

/// 요청에 액세스 토큰을 붙이고, 만료되면 갱신 후 한 번 다시 보낸다.
///
/// 갱신은 **한 번에 하나만** 한다. 동시에 여러 요청이 만료로 실패해도 갱신 요청은
/// 하나만 보내고 나머지는 그 결과를 기다린다. 같은 리프레시 토큰을 두 번 보내면
/// 서버가 탈취로 판단해 로그아웃시키기 때문이다 (features/auth.md 5.4).
class AuthInterceptor extends Interceptor {
  new({
    required this._storage,
    required this._refreshClient,
    required this._retry,
    required this._onSessionExpired,
  });

  final TokenStorage _storage;
  final Dio _refreshClient;
  final Future<Response<dynamic>> Function(RequestOptions) _retry;
  final void Function() _onSessionExpired;
  Future<bool>? _refreshing;

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (!_publicPaths.contains(options.path)) {
      final token = await _storage.readAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final isAuthenticatedRequest = !_publicPaths.contains(options.path);
    if (err.response?.statusCode != 401 || !isAuthenticatedRequest) {
      handler.next(err);
      return;
    }

    final code = _errorCode(err.response);
    if (code == 'token_expired' && options.extra[_retriedKey] != true) {
      if (await _refreshOnce()) {
        final token = await _storage.readAccessToken();
        options
          ..headers['Authorization'] = 'Bearer $token'
          ..extra[_retriedKey] = true;
        try {
          handler.resolve(await _retry(options));
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
        return;
      }
    } else {
      // token_invalid·token_missing: 토큰을 더 쓸 수 없다
      await _expireSession();
    }
    handler.next(err);
  }

  Future<bool> _refreshOnce() => _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final tokens = await _storage.readTokens();
    if (tokens == null) {
      await _expireSession();
      return false;
    }
    try {
      final response = await _refreshClient.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refresh_token': tokens.refreshToken},
      );
      final refreshed = TokenResponse.fromJson(response.data!);
      await _storage.saveTokens(refreshed.tokens);
      await _storage.saveUser(refreshed.user);
      return true;
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _expireSession();
      } else {
        // 오프라인 등 네트워크 문제: 토큰은 그대로 두고 이번 요청만 실패시킨다
        _log.info('토큰 갱신 실패 (네트워크)');
      }
      return false;
    }
  }

  Future<void> _expireSession() async {
    await _storage.clear();
    _onSessionExpired();
  }

  static String? _errorCode(Response<dynamic>? response) {
    final data = response?.data;
    return data is Map<String, dynamic> ? data['code'] as String? : null;
  }
}

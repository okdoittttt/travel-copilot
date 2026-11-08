import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/core/api/auth_interceptor.dart';
import 'package:travelcopilot/core/storage/token_storage.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';

/// 경로별로 정해진 응답을 돌려주는 가짜 서버.
class _FakeServer implements HttpClientAdapter {
  int refreshCalls = 0;
  final List<Map<String, dynamic>> requests = [];
  String validAccessToken = 'new-access';
  int refreshStatus = 200;
  bool refreshNetworkError = false;
  String meErrorCode = 'token_expired';

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add({'path': options.path, 'auth': options.headers['Authorization']});
    switch (options.path) {
      case '/auth/refresh':
        refreshCalls++;
        await Future<void>.delayed(const Duration(milliseconds: 20));
        if (refreshNetworkError) {
          throw DioException.connectionError(requestOptions: options, reason: 'offline');
        }
        if (refreshStatus != 200) {
          return _json(refreshStatus, {'code': 'token_invalid'});
        }
        return _json(200, {
          'access_token': validAccessToken,
          'refresh_token': 'new-refresh',
          'expires_in': 900,
          'user': {'id': 'u1', 'display_name': '홍길동'},
        });
      case '/me':
        if (options.headers['Authorization'] == 'Bearer $validAccessToken') {
          return _json(200, {'id': 'u1', 'display_name': '홍길동'});
        }
        return _json(401, {'code': meErrorCode});
      default:
        return _json(200, <String, dynamic>{});
    }
  }

  static ResponseBody _json(int status, Map<String, dynamic> body) => ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

void main() {
  late _FakeServer server;
  late TokenStorage storage;
  late Dio dio;
  late int expiredCount;

  setUp(() async {
    FlutterSecureStorage.setMockInitialValues({});
    storage = TokenStorage(TokenStorage.options);
    await storage.saveTokens(const AuthTokens(accessToken: 'old-access', refreshToken: 'old'));
    server = _FakeServer();
    expiredCount = 0;
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = server;
    final refreshClient = Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = server;
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        refreshClient: refreshClient,
        retry: dio.fetch,
        onSessionExpired: () => expiredCount++,
      ),
    );
  });

  test('만료된 요청이 동시에 여러 개여도 갱신은 한 번만 하고 모두 재시도한다', () async {
    final responses = await Future.wait([
      dio.get<void>('/me'),
      dio.get<void>('/me'),
      dio.get<void>('/me'),
    ]);

    expect(responses.map((r) => r.statusCode), [200, 200, 200]);
    expect(server.refreshCalls, 1);
    expect(
      await storage.readTokens(),
      const AuthTokens(accessToken: 'new-access', refreshToken: 'new-refresh'),
    );
    expect(expiredCount, 0);
  });

  test('갱신이 401이면 토큰을 지우고 세션 만료를 알린다', () async {
    server.refreshStatus = 401;

    await expectLater(dio.get<void>('/me'), throwsA(isA<DioException>()));

    expect(await storage.readTokens(), isNull);
    expect(expiredCount, 1);
  });

  test('token_invalid면 갱신 없이 바로 세션 만료', () async {
    server.meErrorCode = 'token_invalid';

    await expectLater(dio.get<void>('/me'), throwsA(isA<DioException>()));

    expect(server.refreshCalls, 0);
    expect(await storage.readTokens(), isNull);
    expect(expiredCount, 1);
  });

  test('오프라인이라 갱신하지 못하면 토큰을 지우지 않는다', () async {
    server.refreshNetworkError = true;

    await expectLater(dio.get<void>('/me'), throwsA(isA<DioException>()));

    expect(await storage.readTokens(), isNotNull);
    expect(expiredCount, 0);
  });

  test('로그인·갱신 경로에는 Authorization 헤더를 붙이지 않는다', () async {
    await dio.post<void>('/auth/nonce');
    await dio.post<void>('/auth/google/login');

    expect(server.requests.map((r) => r['auth']), [null, null]);
  });

  test('일반 경로에는 저장된 액세스 토큰을 붙인다', () async {
    server.validAccessToken = 'old-access';

    await dio.get<void>('/me');

    expect(server.requests.single['auth'], 'Bearer old-access');
  });
}

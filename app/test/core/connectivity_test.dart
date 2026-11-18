import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/core/state/connectivity.dart';

/// 온라인·오프라인은 실제 요청 결과로 정한다 (features/sync-offline.md 5.4).
void main() {
  late ProviderContainer container;
  late Dio dio;

  setUp(() {
    container = ProviderContainer();
    dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(
      ConnectivityInterceptor(
        ({required reached}) =>
            container.read(connectivityProvider.notifier).report(reached: reached),
      ),
    );
  });

  tearDown(() {
    dio.close();
    container.dispose();
  });

  void respondWith(int? status) {
    dio.httpClientAdapter = _FakeAdapter(status);
  }

  ConnectionStatus status() => container.read(connectivityProvider);

  test('처음에는 모름', () {
    expect(status(), ConnectionStatus.unknown);
  });

  test('응답을 받으면 온라인', () async {
    respondWith(200);
    await dio.get<dynamic>('/trips');
    expect(status(), ConnectionStatus.online);
  });

  test('에러 응답(404·500)도 서버에 닿았으므로 온라인', () async {
    respondWith(500);
    await expectLater(dio.get<dynamic>('/trips'), throwsA(isA<DioException>()));
    expect(status(), ConnectionStatus.online);
  });

  test('응답이 없으면 오프라인, 다시 닿으면 온라인', () async {
    respondWith(null);
    await expectLater(dio.get<dynamic>('/trips'), throwsA(isA<DioException>()));
    expect(status(), ConnectionStatus.offline);

    respondWith(200);
    await dio.get<dynamic>('/trips');
    expect(status(), ConnectionStatus.online);
  });
}

/// [status]가 null이면 연결 실패를 흉내 낸다.
class _FakeAdapter implements HttpClientAdapter {
  new(this.status);

  final int? status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final code = status;
    if (code == null) {
      throw DioException.connectionError(requestOptions: options, reason: 'offline');
    }
    return ResponseBody.fromString(
      '{}',
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

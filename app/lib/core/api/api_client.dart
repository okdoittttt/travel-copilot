import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/api/auth_interceptor.dart';
import 'package:travelcopilot/core/config/app_config.dart';
import 'package:travelcopilot/core/storage/token_storage.dart';
import 'package:travelcopilot/features/auth/state/auth_controller.dart';

part 'api_client.g.dart';

BaseOptions _baseOptions() => BaseOptions(
  // 분석 시점에는 빌드 값이 비어 있어 기본값('')과 같다고 오판한다. 실제 빌드에서는 주입된다.
  // ignore: avoid_redundant_argument_values
  baseUrl: AppConfig.apiBaseUrl,
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 15),
);

/// 서버 API용 dio. 액세스 토큰 첨부와 자동 갱신을 한다.
@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final dio = Dio(_baseOptions());
  // 갱신 요청은 인터셉터가 없는 별도 클라이언트로 보낸다 (갱신 실패가 다시 갱신을 부르지 않게)
  final refreshClient = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(
      storage: ref.watch(tokenStorageProvider),
      refreshClient: refreshClient,
      retry: dio.fetch,
      // 호출 시점에 읽어서 provider 사이의 순환 참조를 피한다
      onSessionExpired: () => ref.read(authControllerProvider.notifier).onSessionExpired(),
    ),
  );
  ref.onDispose(() {
    dio.close();
    refreshClient.close();
  });
  return dio;
}

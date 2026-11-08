import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/config/app_config.dart';

part 'api_client.g.dart';

/// 서버 API용 dio. 토큰 첨부·자동 갱신 인터셉터는 F1에서 추가한다.
@Riverpod(keepAlive: true)
Dio apiClient(Ref ref) {
  final dio = Dio(
    BaseOptions(
      // 분석 시점에는 빌드 값이 비어 있어 기본값('')과 같다고 오판한다. 실제 빌드에서는 주입된다.
      // ignore: avoid_redundant_argument_values
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
}

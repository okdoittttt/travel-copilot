import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/health/data/health.dart';

final _log = Logger('HealthRepository');

class HealthRepository {
  new(this._dio);

  final Dio _dio;

  /// 서버 상태를 확인한다. 실패하면 [AppException]을 던진다.
  Future<Health> check() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/health');
      return Health.fromJson(response.data!);
    } on DioException catch (error) {
      final exception = AppException.fromDio(error);
      _log.warning('서버 상태 확인 실패: ${exception.runtimeType}');
      throw exception;
    }
  }
}

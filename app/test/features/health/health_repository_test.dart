import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/health/data/health.dart';
import 'package:travelcopilot/features/health/data/health_repository.dart';

class _MockDio extends Mock implements Dio;

void main() {
  late _MockDio dio;
  late HealthRepository repository;

  setUp(() {
    dio = _MockDio();
    repository = HealthRepository(dio);
  });

  test('정상 응답이면 Health를 돌려준다', () async {
    when(() => dio.get<Map<String, dynamic>>('/health')).thenAnswer(
      (_) async => Response(
        data: {'status': 'ok'},
        statusCode: 200,
        requestOptions: RequestOptions(path: '/health'),
      ),
    );

    expect(await repository.check(), const Health(status: 'ok'));
  });

  test('서버에 닿지 못하면 NetworkException', () async {
    when(() => dio.get<Map<String, dynamic>>('/health')).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/health'),
        type: DioExceptionType.connectionTimeout,
      ),
    );

    expect(repository.check, throwsA(isA<NetworkException>()));
  });

  test('에러 응답이면 서버 code를 담은 ServerException', () async {
    final options = RequestOptions(path: '/health');
    when(() => dio.get<Map<String, dynamic>>('/health')).thenThrow(
      DioException(
        requestOptions: options,
        type: DioExceptionType.badResponse,
        response: Response(
          data: {'status': 503, 'code': 'unavailable'},
          statusCode: 503,
          requestOptions: options,
        ),
      ),
    );

    expect(
      repository.check,
      throwsA(
        isA<ServerException>()
            .having((e) => e.statusCode, 'statusCode', 503)
            .having((e) => e.code, 'code', 'unavailable'),
      ),
    );
  });
}

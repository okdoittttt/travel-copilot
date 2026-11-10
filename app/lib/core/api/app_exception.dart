import 'package:dio/dio.dart';

/// 화면이 처리하는 앱 공통 예외. API 에러는 모두 이 타입으로 바꿔서 올린다.
sealed class AppException implements Exception {
  const new();

  /// dio 예외를 앱 예외로 바꾼다.
  factory fromDio(DioException error) {
    final response = error.response;
    if (response == null) {
      return const NetworkException();
    }
    final data = response.data;
    final code = data is Map<String, dynamic> ? data['code'] as String? : null;
    return ServerException(
      statusCode: response.statusCode ?? 0,
      code: code ?? 'unknown',
      body: data is Map<String, dynamic> ? data : const {},
    );
  }
}

/// 서버에 닿지 못함 (오프라인, 시간 초과, 인증서 오류 등).
final class NetworkException extends AppException {
  const new();
}

/// 서버가 에러 응답을 보냄. [code]는 서버의 RFC 9457 응답의 `code` 값.
final class ServerException extends AppException {
  const new({required this.statusCode, required this.code, this.body = const {}});

  final int statusCode;
  final String code;

  /// 응답 본문 전체. `409 version_conflict`의 `current`처럼 추가 필드를 꺼낼 때 쓴다.
  final Map<String, dynamic> body;
}

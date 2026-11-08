import 'package:dio/dio.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';

/// 인증 관련 서버 API 호출. 실패는 모두 [AppException]으로 바꿔서 던진다.
class AuthApi {
  new(this._dio);

  final Dio _dio;

  Future<String> issueNonce() => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>('/auth/nonce');
    return response.data!['nonce'] as String;
  });

  Future<TokenResponse> loginWithGoogle(String idToken) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/google/login',
      data: {'id_token': idToken},
    );
    return TokenResponse.fromJson(response.data!);
  });

  Future<void> logout(String refreshToken) => _call(() async {
    await _dio.post<void>('/auth/logout', data: {'refresh_token': refreshToken});
  });

  Future<AppUser> me() => _call(() async {
    final response = await _dio.get<Map<String, dynamic>>('/me');
    return AppUser.fromJson(response.data!);
  });

  static Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }
}

/// 빌드 시점에 `--dart-define-from-file=env/<환경>.json`으로 넣는 설정.
///
/// 앱에는 비밀값을 넣지 않는다. 여기에는 서버 주소, Google 클라이언트 ID처럼
/// 공개돼도 되는 값만 둔다.
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Google 웹 클라이언트 ID. ID 토큰의 aud가 되는 서버용 ID (features/auth.md 5.1).
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Google iOS 클라이언트 ID. iOS에서 로그인 창을 띄울 때 필요. Android는 쓰지 않는다.
  static const googleIosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

  /// 필수 설정이 빠졌거나 HTTPS가 아니면 앱 시작 시 바로 실패시킨다.
  static void validate() {
    final uri = Uri.tryParse(apiBaseUrl);
    if (apiBaseUrl.isEmpty || uri == null || uri.scheme != 'https') {
      throw StateError(
        'API_BASE_URL이 없거나 HTTPS가 아닙니다. '
        '--dart-define-from-file=env/local.json 으로 실행하세요.',
      );
    }
    if (googleServerClientId.isEmpty) {
      throw StateError('GOOGLE_SERVER_CLIENT_ID가 없습니다. env/*.json을 확인하세요.');
    }
  }
}

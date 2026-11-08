import 'package:flutter/foundation.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';

/// Google 로그인 창을 띄우고 ID 토큰을 받는다.
///
/// 앱용 `GoogleSignIn.instance`는 nonce를 `initialize()`에서만 받고, 그 함수는 앱 실행 중
/// 한 번만 호출해야 한다. 우리는 로그인마다 서버가 발급한 새 nonce가 필요하므로, 그 아래
/// 플랫폼 계층을 직접 써서 로그인 직전마다 `init(nonce)`를 다시 호출한다.
/// 플랫폼 계층의 `init()`은 설정을 저장만 해서 여러 번 불러도 안전하다
/// (google_sign_in_ios 6.4.0, google_sign_in_android 7.2.18에서 확인).
///
/// 패키지 내부 동작에 기대므로 pubspec에서 버전을 고정했다. 업데이트할 때 이 클래스와
/// iOS 시뮬레이터 로그인을 다시 확인한다.
class GoogleAuthClient {
  new({required this._serverClientId, String? iosClientId, this._platform, this._targetPlatform})
    : _iosClientId = (iosClientId == null || iosClientId.isEmpty) ? null : iosClientId;

  final String _serverClientId;
  final String? _iosClientId;
  final GoogleSignInPlatform? _platform;
  final TargetPlatform? _targetPlatform;

  GoogleSignInPlatform get _api => _platform ?? GoogleSignInPlatform.instance;

  /// Google 로그인 후 ID 토큰을 돌려준다. 사용자가 취소하면 null.
  ///
  /// [nonce]는 서버가 발급한 값이고, Google이 ID 토큰 안에 그대로 넣는다.
  Future<String?> signIn({required String nonce}) async {
    // iOS Google SDK는 클라이언트 ID가 없으면 예외 대신 앱을 강제 종료시킨다.
    // SDK를 부르기 전에 막아서 일반 로그인 실패로 처리되게 한다.
    if ((_targetPlatform ?? defaultTargetPlatform) == TargetPlatform.iOS && _iosClientId == null) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'GOOGLE_IOS_CLIENT_ID가 설정되지 않았습니다 (env/*.json)',
      );
    }
    await _api.init(
      InitParameters(
        // Android는 clientId를 쓰지 않는다 (패키지 이름 + SHA-1로 앱을 확인)
        clientId: _iosClientId,
        // ID 토큰의 aud가 웹 클라이언트 ID가 되게 한다
        serverClientId: _serverClientId,
        nonce: nonce,
      ),
    );
    try {
      final result = await _api.authenticate(const AuthenticateParameters());
      return result.authenticationTokens.idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }
  }

  /// 기기의 Google 로그인 상태를 지운다. 다음 로그인 때 계정을 다시 고르게 된다.
  Future<void> signOut() => _api.signOut(const SignOutParams());
}

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:travelcopilot/features/auth/data/google_auth_client.dart';

class _MockPlatform extends Mock with MockPlatformInterfaceMixin implements GoogleSignInPlatform;

const _results = AuthenticationResults(
  user: GoogleSignInUserData(email: 'a@b.c', id: 'google-id'),
  authenticationTokens: AuthenticationTokenData(idToken: 'id-token'),
);

void main() {
  late _MockPlatform platform;
  late GoogleAuthClient client;

  setUpAll(() {
    registerFallbackValue(const InitParameters());
    registerFallbackValue(const AuthenticateParameters());
  });

  setUp(() {
    platform = _MockPlatform();
    client = GoogleAuthClient(
      serverClientId: 'web-id',
      iosClientId: 'ios-id',
      platform: platform,
      targetPlatform: TargetPlatform.iOS,
    );
    when(() => platform.init(any())).thenAnswer((_) async {});
  });

  test('로그인마다 새 nonce와 서버 클라이언트 ID로 초기화한다', () async {
    when(() => platform.authenticate(any())).thenAnswer((_) async => _results);

    await client.signIn(nonce: 'nonce-1');
    await client.signIn(nonce: 'nonce-2');

    final inits = verify(() => platform.init(captureAny())).captured.cast<InitParameters>();
    expect(inits.map((p) => p.nonce), ['nonce-1', 'nonce-2']);
    expect(inits.every((p) => p.serverClientId == 'web-id' && p.clientId == 'ios-id'), isTrue);
  });

  test('ID 토큰을 돌려준다', () async {
    when(() => platform.authenticate(any())).thenAnswer((_) async => _results);

    expect(await client.signIn(nonce: 'n'), 'id-token');
  });

  test('사용자가 취소하면 null', () async {
    when(() => platform.authenticate(any()))
        .thenThrow(const GoogleSignInException(code: GoogleSignInExceptionCode.canceled));

    expect(await client.signIn(nonce: 'n'), isNull);
  });

  test('취소 외의 실패는 예외로 올린다', () async {
    when(() => platform.authenticate(any())).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.clientConfigurationError),
    );

    expect(() => client.signIn(nonce: 'n'), throwsA(isA<GoogleSignInException>()));
  });

  test('iOS에서 iOS 클라이언트 ID가 없으면 SDK를 부르지 않고 설정 오류 (SDK 강제 종료 방지)', () async {
    final iosClient = GoogleAuthClient(
      serverClientId: 'web-id',
      iosClientId: '',
      platform: platform,
      targetPlatform: TargetPlatform.iOS,
    );

    await expectLater(
      iosClient.signIn(nonce: 'n'),
      throwsA(
        isA<GoogleSignInException>().having(
          (e) => e.code,
          'code',
          GoogleSignInExceptionCode.clientConfigurationError,
        ),
      ),
    );
    verifyNever(() => platform.init(any()));
    verifyNever(() => platform.authenticate(any()));
  });

  test('Android에서는 iOS 클라이언트 ID가 비어 있어도 되고, 넘기지 않는다', () async {
    when(() => platform.authenticate(any())).thenAnswer((_) async => _results);
    final androidClient = GoogleAuthClient(
      serverClientId: 'web-id',
      iosClientId: '',
      platform: platform,
      targetPlatform: TargetPlatform.android,
    );

    await androidClient.signIn(nonce: 'n');

    final init = verify(() => platform.init(captureAny())).captured.single as InitParameters;
    expect(init.clientId, isNull);
  });
}

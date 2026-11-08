import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/core/storage/token_storage.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';

void main() {
  late TokenStorage storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = TokenStorage(TokenStorage.options);
  });

  test('iOS는 이 기기 전용 키체인 항목으로 저장한다 (백업·이전 안 됨)', () {
    expect(
      TokenStorage.options.iOptions.accessibility,
      KeychainAccessibility.first_unlock_this_device,
    );
  });

  test('토큰을 저장하고 다시 읽는다', () async {
    const tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');

    await storage.saveTokens(tokens);

    expect(await storage.readTokens(), tokens);
    expect(await storage.readAccessToken(), 'a');
  });

  test('사용자 정보를 저장하고 다시 읽는다', () async {
    const user = AppUser(id: 'u1', displayName: '홍길동');

    await storage.saveUser(user);

    expect(await storage.readUser(), user);
  });

  test('clear는 토큰과 사용자 정보를 모두 지운다', () async {
    await storage.saveTokens(const AuthTokens(accessToken: 'a', refreshToken: 'r'));
    await storage.saveUser(const AppUser(id: 'u1', displayName: '홍길동'));

    await storage.clear();

    expect(await storage.readTokens(), isNull);
    expect(await storage.readUser(), isNull);
  });
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/storage/token_storage.dart';
import 'package:travelcopilot/features/auth/data/auth_api.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';
import 'package:travelcopilot/features/auth/data/auth_repository.dart';
import 'package:travelcopilot/features/auth/data/google_auth_client.dart';

class _MockApi extends Mock implements AuthApi;

class _MockGoogle extends Mock implements GoogleAuthClient;

const _user = AppUser(id: 'u1', displayName: '홍길동');
const _login = TokenResponse(
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresIn: 900,
  user: _user,
  isNewUser: true,
);

void main() {
  late _MockApi api;
  late _MockGoogle google;
  late TokenStorage storage;
  late AuthRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    api = _MockApi();
    google = _MockGoogle();
    storage = TokenStorage(TokenStorage.options);
    repository = AuthRepository(api: api, google: google, storage: storage);
  });

  group('signInWithGoogle', () {
    test('서버 nonce로 Google 로그인 후 받은 토큰과 사용자를 저장한다', () async {
      when(api.issueNonce).thenAnswer((_) async => 'nonce');
      when(() => google.signIn(nonce: 'nonce')).thenAnswer((_) async => 'id-token');
      when(() => api.loginWithGoogle('id-token')).thenAnswer((_) async => _login);

      final user = await repository.signInWithGoogle();

      expect(user, _user);
      expect(await storage.readTokens(), _login.tokens);
      expect(await storage.readUser(), _user);
    });

    test('사용자가 Google 창을 닫으면 서버에 로그인하지 않고 null', () async {
      when(api.issueNonce).thenAnswer((_) async => 'nonce');
      when(() => google.signIn(nonce: 'nonce')).thenAnswer((_) async => null);

      expect(await repository.signInWithGoogle(), isNull);
      verifyNever(() => api.loginWithGoogle(any()));
      expect(await storage.readTokens(), isNull);
    });
  });

  group('restoreSession', () {
    test('저장된 토큰이 없으면 null', () async {
      expect(await repository.restoreSession(), isNull);
      verifyNever(api.me);
    });

    test('서버가 확인해주면 최신 사용자 정보', () async {
      await storage.saveTokens(_login.tokens);
      when(api.me).thenAnswer((_) async => _user);

      expect(await repository.restoreSession(), _user);
    });

    test('오프라인이면 마지막 사용자 정보로 유지', () async {
      await storage.saveTokens(_login.tokens);
      await storage.saveUser(_user);
      when(api.me).thenThrow(const NetworkException());

      expect(await repository.restoreSession(), _user);
    });

    test('401이면 로그인 안 됨', () async {
      await storage.saveTokens(_login.tokens);
      await storage.saveUser(_user);
      when(api.me).thenThrow(const ServerException(statusCode: 401, code: 'token_invalid'));

      expect(await repository.restoreSession(), isNull);
    });
  });

  group('signOut', () {
    test('서버에 리프레시 토큰 폐기를 요청하고 기기 정보를 지운다', () async {
      await storage.saveTokens(_login.tokens);
      when(() => api.logout('refresh')).thenAnswer((_) async {});
      when(google.signOut).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => api.logout('refresh')).called(1);
      expect(await storage.readTokens(), isNull);
    });

    test('서버 요청이 실패해도(오프라인) 기기 정보는 지운다', () async {
      await storage.saveTokens(_login.tokens);
      await storage.saveUser(_user);
      when(() => api.logout(any())).thenThrow(const NetworkException());
      when(google.signOut).thenAnswer((_) async {});

      await repository.signOut();

      expect(await storage.readTokens(), isNull);
      expect(await storage.readUser(), isNull);
    });
  });
}

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/storage/token_storage.dart';
import 'package:travelcopilot/features/auth/data/auth_api.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';
import 'package:travelcopilot/features/auth/data/auth_repository.dart';
import 'package:travelcopilot/features/auth/data/google_auth_client.dart';
import 'package:travelcopilot/features/trips/data/trip_cache.dart';

import '../trips/trip_fixtures.dart';

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
  late TripCache cache;
  late AuthRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    api = _MockApi();
    google = _MockGoogle();
    storage = TokenStorage(TokenStorage.options);
    cache = TripCache.memory();
    repository = AuthRepository(api: api, google: google, storage: storage, cache: cache);
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

    test('오프라인 로그아웃에서도 여행 캐시를 지운다 (T34)', () async {
      await storage.saveTokens(_login.tokens);
      await cache.replaceTrips([makeTrip()], DateTime(2026, 11, 15));
      when(() => api.logout(any())).thenThrow(const NetworkException());
      when(google.signOut).thenAnswer((_) async {});

      await repository.signOut();

      expect(await cache.readTrips(), isNull);
    });
  });

  group('캐시 주인 확인 (features/sync-offline.md 5.7, T34)', () {
    void stubLogin(AppUser user) {
      when(api.issueNonce).thenAnswer((_) async => 'nonce');
      when(() => google.signIn(nonce: 'nonce')).thenAnswer((_) async => 'id-token');
      when(() => api.loginWithGoogle('id-token')).thenAnswer(
        (_) async => TokenResponse(
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresIn: 900,
          user: user,
        ),
      );
    }

    test('다른 계정으로 로그인하면 이전 계정의 캐시를 지운다', () async {
      await cache.claim('previous-user');
      await cache.replaceTrips([makeTrip()], DateTime(2026, 11, 15));
      stubLogin(_user);

      await repository.signInWithGoogle();

      expect(await cache.readTrips(), isNull);
    });

    test('같은 계정으로 다시 로그인하면 캐시를 이어서 쓴다', () async {
      await cache.claim(_user.id);
      await cache.replaceTrips([makeTrip()], DateTime(2026, 11, 15));
      stubLogin(_user);

      await repository.signInWithGoogle();

      expect((await cache.readTrips())!.data, hasLength(1));
    });

    test('앱 시작 때 저장된 사용자와 캐시 주인이 다르면 지운다', () async {
      await cache.claim('previous-user');
      await cache.replaceTrips([makeTrip()], DateTime(2026, 11, 15));
      await storage.saveTokens(_login.tokens);
      await storage.saveUser(_user);
      when(api.me).thenThrow(const NetworkException());

      expect(await repository.restoreSession(), _user);
      expect(await cache.readTrips(), isNull);
    });
  });
}

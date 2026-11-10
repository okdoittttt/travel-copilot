import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/core/router/app_router.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';

void main() {
  const user = AppUser(id: 'u1', displayName: '홍길동');

  test('로그인 상태 확인 중에는 시작 화면', () {
    const loading = AsyncLoading<AppUser?>();

    expect(redirectFor(loading, Routes.trips), Routes.splash);
    expect(redirectFor(loading, Routes.splash), isNull);
  });

  test('로그인 안 됨이면 로그인 화면', () {
    const signedOut = AsyncData<AppUser?>(null);

    expect(redirectFor(signedOut, Routes.splash), Routes.login);
    expect(redirectFor(signedOut, Routes.trips), Routes.login);
    expect(redirectFor(signedOut, Routes.login), isNull);
  });

  test('로그인됨이면 시작·로그인 화면에서 여행 목록으로', () {
    const signedIn = AsyncData<AppUser?>(user);

    expect(redirectFor(signedIn, Routes.splash), Routes.trips);
    expect(redirectFor(signedIn, Routes.login), Routes.trips);
    expect(redirectFor(signedIn, Routes.trips), isNull);
  });
}

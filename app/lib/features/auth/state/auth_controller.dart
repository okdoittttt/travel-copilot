import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';
import 'package:travelcopilot/features/auth/data/auth_repository.dart';

part 'auth_controller.g.dart';

/// 앱 전체의 로그인 상태. 값이 null이면 로그인 안 됨. 라우터가 이 상태로 화면을 바꾼다.
@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<AppUser?> build() => ref.read(authRepositoryProvider).restoreSession();

  /// Google로 로그인한다. 실패하면 예외를 그대로 던져서 화면이 메시지를 보여준다.
  ///
  /// 진행 중에 상태를 로딩으로 바꾸지 않는다 (라우터가 시작 화면으로 돌아가지 않게).
  Future<void> signInWithGoogle() async {
    final user = await ref.read(authRepositoryProvider).signInWithGoogle();
    if (user != null) state = AsyncData(user);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  /// 토큰을 더 쓸 수 없을 때 (갱신 실패 등) API 클라이언트가 호출한다.
  void onSessionExpired() {
    state = const AsyncData(null);
  }
}

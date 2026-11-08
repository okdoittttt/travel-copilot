// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱 전체의 로그인 상태. 값이 null이면 로그인 안 됨. 라우터가 이 상태로 화면을 바꾼다.

@ProviderFor(AuthController)
final authControllerProvider = AuthControllerProvider._();

/// 앱 전체의 로그인 상태. 값이 null이면 로그인 안 됨. 라우터가 이 상태로 화면을 바꾼다.
final class AuthControllerProvider extends $AsyncNotifierProvider<AuthController, AppUser?> {
  /// 앱 전체의 로그인 상태. 값이 null이면 로그인 안 됨. 라우터가 이 상태로 화면을 바꾼다.
  AuthControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'authControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$authControllerHash();

  @$internal
  @override
  AuthController create() => AuthController();
}

String _$authControllerHash() => r'4eb58203f35376ea164dbc627317ea76e8bb5b39';

/// 앱 전체의 로그인 상태. 값이 null이면 로그인 안 됨. 라우터가 이 상태로 화면을 바꾼다.

abstract class _$AuthController extends $AsyncNotifier<AppUser?> {
  FutureOr<AppUser?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AppUser?>, AppUser?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AppUser?>, AppUser?>,
              AsyncValue<AppUser?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

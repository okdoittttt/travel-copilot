// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_links.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Universal Link / App Link로 들어온 주소 (features/invites.md 5.7).
///
/// Flutter 기본 딥링크 처리는 꺼 두었다 (iOS `FlutterDeepLinkingEnabled`, Android
/// `flutter_deeplinking_enabled`). 기본 처리는 URL을 라우터 경로로 넘겨서 토큰이 라우터
/// 상태·로그에 들어갈 수 있기 때문이다. 테스트에서 바꿔 끼우려고 provider로 둔다.

@ProviderFor(incomingLinks)
final incomingLinksProvider = IncomingLinksProvider._();

/// Universal Link / App Link로 들어온 주소 (features/invites.md 5.7).
///
/// Flutter 기본 딥링크 처리는 꺼 두었다 (iOS `FlutterDeepLinkingEnabled`, Android
/// `flutter_deeplinking_enabled`). 기본 처리는 URL을 라우터 경로로 넘겨서 토큰이 라우터
/// 상태·로그에 들어갈 수 있기 때문이다. 테스트에서 바꿔 끼우려고 provider로 둔다.

final class IncomingLinksProvider extends $FunctionalProvider<AsyncValue<Uri>, Uri, Stream<Uri>>
    with $FutureModifier<Uri>, $StreamProvider<Uri> {
  /// Universal Link / App Link로 들어온 주소 (features/invites.md 5.7).
  ///
  /// Flutter 기본 딥링크 처리는 꺼 두었다 (iOS `FlutterDeepLinkingEnabled`, Android
  /// `flutter_deeplinking_enabled`). 기본 처리는 URL을 라우터 경로로 넘겨서 토큰이 라우터
  /// 상태·로그에 들어갈 수 있기 때문이다. 테스트에서 바꿔 끼우려고 provider로 둔다.
  IncomingLinksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'incomingLinksProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$incomingLinksHash();

  @$internal
  @override
  $StreamProviderElement<Uri> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<Uri> create(Ref ref) {
    return incomingLinks(ref);
  }
}

String _$incomingLinksHash() => r'd9c4f72d209beb8c9af9253cf60de9194c41bf84';

/// 앱이 떠 있는 동안 링크를 듣는다. 앱 루트에서 한 번 watch한다.

@ProviderFor(inviteLinkListener)
final inviteLinkListenerProvider = InviteLinkListenerProvider._();

/// 앱이 떠 있는 동안 링크를 듣는다. 앱 루트에서 한 번 watch한다.

final class InviteLinkListenerProvider extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// 앱이 떠 있는 동안 링크를 듣는다. 앱 루트에서 한 번 watch한다.
  InviteLinkListenerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inviteLinkListenerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inviteLinkListenerHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return inviteLinkListener(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$inviteLinkListenerHash() => r'fb4c368eb053cbded2d3a2dceeb80dc26bdca6be';

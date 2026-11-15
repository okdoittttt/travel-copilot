// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 여행의 초대 링크 목록 (S15). 화면이 열려 있는 동안만 유지.

@ProviderFor(invites)
final invitesProvider = InvitesFamily._();

/// 여행의 초대 링크 목록 (S15). 화면이 열려 있는 동안만 유지.

final class InvitesProvider
    extends $FunctionalProvider<AsyncValue<List<Invite>>, List<Invite>, FutureOr<List<Invite>>>
    with $FutureModifier<List<Invite>>, $FutureProvider<List<Invite>> {
  /// 여행의 초대 링크 목록 (S15). 화면이 열려 있는 동안만 유지.
  InvitesProvider._({required InvitesFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'invitesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invitesHash();

  @override
  String toString() {
    return r'invitesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Invite>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Invite>> create(Ref ref) {
    final argument = this.argument as String;
    return invites(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InvitesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$invitesHash() => r'83c468c27433fa629527dd51834b8ceef552c490';

/// 여행의 초대 링크 목록 (S15). 화면이 열려 있는 동안만 유지.

final class InvitesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Invite>>, String> {
  InvitesFamily._()
    : super(
        retry: null,
        name: r'invitesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 여행의 초대 링크 목록 (S15). 화면이 열려 있는 동안만 유지.

  InvitesProvider call(String tripId) => InvitesProvider._(argument: tripId, from: this);

  @override
  String toString() => r'invitesProvider';
}

/// 처리 중인 초대 토큰. **메모리에만** 둔다 (features/invites.md 5.7).
///
/// 라우터 경로·디스크·로그에 넣지 않는다. 참여·취소·실패하면 [clear]로 바로 버린다.

@ProviderFor(PendingInvite)
final pendingInviteProvider = PendingInviteProvider._();

/// 처리 중인 초대 토큰. **메모리에만** 둔다 (features/invites.md 5.7).
///
/// 라우터 경로·디스크·로그에 넣지 않는다. 참여·취소·실패하면 [clear]로 바로 버린다.
final class PendingInviteProvider extends $NotifierProvider<PendingInvite, String?> {
  /// 처리 중인 초대 토큰. **메모리에만** 둔다 (features/invites.md 5.7).
  ///
  /// 라우터 경로·디스크·로그에 넣지 않는다. 참여·취소·실패하면 [clear]로 바로 버린다.
  PendingInviteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pendingInviteProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pendingInviteHash();

  @$internal
  @override
  PendingInvite create() => PendingInvite();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String?>(value));
  }
}

String _$pendingInviteHash() => r'ee3df006d2f03aa7b9e842fb26db7d67d6dda08b';

/// 처리 중인 초대 토큰. **메모리에만** 둔다 (features/invites.md 5.7).
///
/// 라우터 경로·디스크·로그에 넣지 않는다. 참여·취소·실패하면 [clear]로 바로 버린다.

abstract class _$PendingInvite extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<AnyNotifier<String?, String?>, String?, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(shareText)
final shareTextProvider = ShareTextProvider._();

final class ShareTextProvider extends $FunctionalProvider<ShareText, ShareText, ShareText>
    with $Provider<ShareText> {
  ShareTextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'shareTextProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$shareTextHash();

  @$internal
  @override
  $ProviderElement<ShareText> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  ShareText create(Ref ref) {
    return shareText(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ShareText value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<ShareText>(value));
  }
}

String _$shareTextHash() => r'3a7b03dbd5b9f8b805225cea8b835b8153be9c74';

/// 초대 링크 기본 주소. 테스트에서 바꿔 끼우려고 provider로 둔다.

@ProviderFor(inviteBaseUrl)
final inviteBaseUrlProvider = InviteBaseUrlProvider._();

/// 초대 링크 기본 주소. 테스트에서 바꿔 끼우려고 provider로 둔다.

final class InviteBaseUrlProvider extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// 초대 링크 기본 주소. 테스트에서 바꿔 끼우려고 provider로 둔다.
  InviteBaseUrlProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'inviteBaseUrlProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$inviteBaseUrlHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return inviteBaseUrl(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<String>(value));
  }
}

String _$inviteBaseUrlHash() => r'9d7ca6cc716afe365e5dfa71b079442d17b5184f';

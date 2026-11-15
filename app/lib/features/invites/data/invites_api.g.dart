// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invites_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(invitesApi)
final invitesApiProvider = InvitesApiProvider._();

final class InvitesApiProvider extends $FunctionalProvider<InvitesApi, InvitesApi, InvitesApi>
    with $Provider<InvitesApi> {
  InvitesApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'invitesApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$invitesApiHash();

  @$internal
  @override
  $ProviderElement<InvitesApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  InvitesApi create(Ref ref) {
    return invitesApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(InvitesApi value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<InvitesApi>(value));
  }
}

String _$invitesApiHash() => r'19c955e169bf77a8bdbfda2c52136e3d9a512576';

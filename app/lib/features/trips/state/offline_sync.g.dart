// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_sync.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱이 다시 앞으로 왔을 때, 오프라인이었다면 다시 확인한다 (features/sync-offline.md 5.4).
///
/// 몰래 주기적으로 재시도하지 않는다. 온라인이면 아무것도 하지 않는다.

@ProviderFor(offlineResumeSync)
final offlineResumeSyncProvider = OfflineResumeSyncProvider._();

/// 앱이 다시 앞으로 왔을 때, 오프라인이었다면 다시 확인한다 (features/sync-offline.md 5.4).
///
/// 몰래 주기적으로 재시도하지 않는다. 온라인이면 아무것도 하지 않는다.

final class OfflineResumeSyncProvider extends $FunctionalProvider<void, void, void>
    with $Provider<void> {
  /// 앱이 다시 앞으로 왔을 때, 오프라인이었다면 다시 확인한다 (features/sync-offline.md 5.4).
  ///
  /// 몰래 주기적으로 재시도하지 않는다. 온라인이면 아무것도 하지 않는다.
  OfflineResumeSyncProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'offlineResumeSyncProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$offlineResumeSyncHash();

  @$internal
  @override
  $ProviderElement<void> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  void create(Ref ref) {
    return offlineResumeSync(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<void>(value));
  }
}

String _$offlineResumeSyncHash() => r'af494a485e87baf82b308cf9df185b387cefd945';

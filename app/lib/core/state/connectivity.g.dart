// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connectivity.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 서버에 닿는지. "네트워크 연결됨"이 아니라 **실제 요청 결과**로 정한다 (features/sync-offline.md 5.4).
///
/// 기내 Wi-Fi처럼 연결은 됐는데 서버에 못 닿는 경우가 많아서 OS의 연결 상태는 믿지 않는다.

@ProviderFor(Connectivity)
final connectivityProvider = ConnectivityProvider._();

/// 서버에 닿는지. "네트워크 연결됨"이 아니라 **실제 요청 결과**로 정한다 (features/sync-offline.md 5.4).
///
/// 기내 Wi-Fi처럼 연결은 됐는데 서버에 못 닿는 경우가 많아서 OS의 연결 상태는 믿지 않는다.
final class ConnectivityProvider extends $NotifierProvider<Connectivity, ConnectionStatus> {
  /// 서버에 닿는지. "네트워크 연결됨"이 아니라 **실제 요청 결과**로 정한다 (features/sync-offline.md 5.4).
  ///
  /// 기내 Wi-Fi처럼 연결은 됐는데 서버에 못 닿는 경우가 많아서 OS의 연결 상태는 믿지 않는다.
  ConnectivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectivityProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectivityHash();

  @$internal
  @override
  Connectivity create() => Connectivity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectionStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectionStatus>(value),
    );
  }
}

String _$connectivityHash() => r'a79ae8fcec75cb73b9d0a080ce5b42640a48ac0b';

/// 서버에 닿는지. "네트워크 연결됨"이 아니라 **실제 요청 결과**로 정한다 (features/sync-offline.md 5.4).
///
/// 기내 Wi-Fi처럼 연결은 됐는데 서버에 못 닿는 경우가 많아서 OS의 연결 상태는 믿지 않는다.

abstract class _$Connectivity extends $Notifier<ConnectionStatus> {
  ConnectionStatus build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ConnectionStatus, ConnectionStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConnectionStatus, ConnectionStatus>,
              ConnectionStatus,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

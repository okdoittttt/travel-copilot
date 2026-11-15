// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maps_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 앱에 지도 키가 설정됐는지 (iOS AppDelegate가 알려준다).
///
/// 키 없이 지도를 만들면 Google Maps SDK가 앱을 종료시키므로, false면 지도 화면을 막는다.
/// Android는 아직 지도 설정 전이라 false (features/routes-map.md 4절).

@ProviderFor(mapsConfigured)
final mapsConfiguredProvider = MapsConfiguredProvider._();

/// 앱에 지도 키가 설정됐는지 (iOS AppDelegate가 알려준다).
///
/// 키 없이 지도를 만들면 Google Maps SDK가 앱을 종료시키므로, false면 지도 화면을 막는다.
/// Android는 아직 지도 설정 전이라 false (features/routes-map.md 4절).

final class MapsConfiguredProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// 앱에 지도 키가 설정됐는지 (iOS AppDelegate가 알려준다).
  ///
  /// 키 없이 지도를 만들면 Google Maps SDK가 앱을 종료시키므로, false면 지도 화면을 막는다.
  /// Android는 아직 지도 설정 전이라 false (features/routes-map.md 4절).
  MapsConfiguredProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapsConfiguredProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapsConfiguredHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return mapsConfigured(ref);
  }
}

String _$mapsConfiguredHash() => r'27201949c500aeac6051812c422d3ee2c3b11b02';

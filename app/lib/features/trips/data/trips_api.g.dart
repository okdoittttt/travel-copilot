// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trips_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tripsApi)
final tripsApiProvider = TripsApiProvider._();

final class TripsApiProvider extends $FunctionalProvider<TripsApi, TripsApi, TripsApi>
    with $Provider<TripsApi> {
  TripsApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripsApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripsApiHash();

  @$internal
  @override
  $ProviderElement<TripsApi> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  TripsApi create(Ref ref) {
    return tripsApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripsApi value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TripsApi>(value));
  }
}

String _$tripsApiHash() => r'9be010307ee69df2148eec2a39e2857128ed1175';

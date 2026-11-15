// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'places_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(placesApi)
final placesApiProvider = PlacesApiProvider._();

final class PlacesApiProvider extends $FunctionalProvider<PlacesApi, PlacesApi, PlacesApi>
    with $Provider<PlacesApi> {
  PlacesApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'placesApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$placesApiHash();

  @$internal
  @override
  $ProviderElement<PlacesApi> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  PlacesApi create(Ref ref) {
    return placesApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlacesApi value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<PlacesApi>(value));
  }
}

String _$placesApiHash() => r'5797c584814cc723d4b197bf877751f84e6011aa';

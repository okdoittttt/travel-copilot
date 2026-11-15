// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itinerary_api.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(itineraryApi)
final itineraryApiProvider = ItineraryApiProvider._();

final class ItineraryApiProvider
    extends $FunctionalProvider<ItineraryApi, ItineraryApi, ItineraryApi>
    with $Provider<ItineraryApi> {
  ItineraryApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'itineraryApiProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$itineraryApiHash();

  @$internal
  @override
  $ProviderElement<ItineraryApi> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ItineraryApi create(Ref ref) {
    return itineraryApi(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ItineraryApi value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ItineraryApi>(value),
    );
  }
}

String _$itineraryApiHash() => r'12635d556fd337fc00c3b777eb3b8aef8658b539';

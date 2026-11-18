// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_cache.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(tripCache)
final tripCacheProvider = TripCacheProvider._();

final class TripCacheProvider extends $FunctionalProvider<TripCache, TripCache, TripCache>
    with $Provider<TripCache> {
  TripCacheProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripCacheProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripCacheHash();

  @$internal
  @override
  $ProviderElement<TripCache> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  TripCache create(Ref ref) {
    return tripCache(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripCache value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<TripCache>(value));
  }
}

String _$tripCacheHash() => r'753feab510764a39b8c1aa7c0bc7178f846a0943';

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(healthRepository)
final healthRepositoryProvider = HealthRepositoryProvider._();

final class HealthRepositoryProvider
    extends $FunctionalProvider<HealthRepository, HealthRepository, HealthRepository>
    with $Provider<HealthRepository> {
  HealthRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthRepositoryHash();

  @$internal
  @override
  $ProviderElement<HealthRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  HealthRepository create(Ref ref) {
    return healthRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthRepository>(value),
    );
  }
}

String _$healthRepositoryHash() => r'810a2fac0b590c8c3397e6d0ac47abe8d88db963';

@ProviderFor(health)
final healthProvider = HealthProvider._();

final class HealthProvider extends $FunctionalProvider<AsyncValue<Health>, Health, FutureOr<Health>>
    with $FutureModifier<Health>, $FutureProvider<Health> {
  HealthProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'healthProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthHash();

  @$internal
  @override
  $FutureProviderElement<Health> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Health> create(Ref ref) {
    return health(ref);
  }
}

String _$healthHash() => r'9d7ebf39c21cb6f5deaf53530f423b15f38cf7cc';

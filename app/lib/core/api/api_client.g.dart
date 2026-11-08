// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 서버 API용 dio. 액세스 토큰 첨부와 자동 갱신을 한다.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// 서버 API용 dio. 액세스 토큰 첨부와 자동 갱신을 한다.

final class ApiClientProvider extends $FunctionalProvider<Dio, Dio, Dio> with $Provider<Dio> {
  /// 서버 API용 dio. 액세스 토큰 첨부와 자동 갱신을 한다.
  ApiClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiClientHash();

  @$internal
  @override
  $ProviderElement<Dio> $createElement($ProviderPointer pointer) => $ProviderElement(pointer);

  @override
  Dio create(Ref ref) {
    return apiClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Dio value) {
    return $ProviderOverride(origin: this, providerOverride: $SyncValueProvider<Dio>(value));
  }
}

String _$apiClientHash() => r'932356fc898a53bbe81b1ef6124f10e98c4df2d6';

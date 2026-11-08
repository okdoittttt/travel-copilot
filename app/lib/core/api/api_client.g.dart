// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_client.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 서버 API용 dio. 토큰 첨부·자동 갱신 인터셉터는 F1에서 추가한다.

@ProviderFor(apiClient)
final apiClientProvider = ApiClientProvider._();

/// 서버 API용 dio. 토큰 첨부·자동 갱신 인터셉터는 F1에서 추가한다.

final class ApiClientProvider extends $FunctionalProvider<Dio, Dio, Dio> with $Provider<Dio> {
  /// 서버 API용 dio. 토큰 첨부·자동 갱신 인터셉터는 F1에서 추가한다.
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

String _$apiClientHash() => r'f86269ef11f043e83b56f0280a6ef5abcf81e9c7';

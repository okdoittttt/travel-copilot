// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trips_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 내 여행 목록. 여행을 만들거나 지우거나 나가면 무효화해서 다시 받는다.

@ProviderFor(tripList)
final tripListProvider = TripListProvider._();

/// 내 여행 목록. 여행을 만들거나 지우거나 나가면 무효화해서 다시 받는다.

final class TripListProvider
    extends $FunctionalProvider<AsyncValue<List<Trip>>, List<Trip>, FutureOr<List<Trip>>>
    with $FutureModifier<List<Trip>>, $FutureProvider<List<Trip>> {
  /// 내 여행 목록. 여행을 만들거나 지우거나 나가면 무효화해서 다시 받는다.
  TripListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripListHash();

  @$internal
  @override
  $FutureProviderElement<List<Trip>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Trip>> create(Ref ref) {
    return tripList(ref);
  }
}

String _$tripListHash() => r'a5c3d2ce28650972e9974e1c2c40c8d7875f9b86';

/// 여행 스냅샷 (여행 정보 + 멤버). 수정 작업 뒤에는 무효화해서 다시 받는다.

@ProviderFor(tripSnapshot)
final tripSnapshotProvider = TripSnapshotFamily._();

/// 여행 스냅샷 (여행 정보 + 멤버). 수정 작업 뒤에는 무효화해서 다시 받는다.

final class TripSnapshotProvider
    extends $FunctionalProvider<AsyncValue<TripSnapshot>, TripSnapshot, FutureOr<TripSnapshot>>
    with $FutureModifier<TripSnapshot>, $FutureProvider<TripSnapshot> {
  /// 여행 스냅샷 (여행 정보 + 멤버). 수정 작업 뒤에는 무효화해서 다시 받는다.
  TripSnapshotProvider._({required TripSnapshotFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'tripSnapshotProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripSnapshotHash();

  @override
  String toString() {
    return r'tripSnapshotProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TripSnapshot> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TripSnapshot> create(Ref ref) {
    final argument = this.argument as String;
    return tripSnapshot(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TripSnapshotProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripSnapshotHash() => r'017d826642449ed7a66b7d63fd70c73c8a8eb40c';

/// 여행 스냅샷 (여행 정보 + 멤버). 수정 작업 뒤에는 무효화해서 다시 받는다.

final class TripSnapshotFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TripSnapshot>, String> {
  TripSnapshotFamily._()
    : super(
        retry: null,
        name: r'tripSnapshotProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 여행 스냅샷 (여행 정보 + 멤버). 수정 작업 뒤에는 무효화해서 다시 받는다.

  TripSnapshotProvider call(String tripId) => TripSnapshotProvider._(argument: tripId, from: this);

  @override
  String toString() => r'tripSnapshotProvider';
}

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trips_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 오프라인 배너가 보여줄 "마지막 동기화" 시각. 키는 [tripListSyncKey] 또는 여행 ID.

@ProviderFor(SyncTimes)
final syncTimesProvider = SyncTimesProvider._();

/// 오프라인 배너가 보여줄 "마지막 동기화" 시각. 키는 [tripListSyncKey] 또는 여행 ID.
final class SyncTimesProvider extends $NotifierProvider<SyncTimes, Map<String, DateTime>> {
  /// 오프라인 배너가 보여줄 "마지막 동기화" 시각. 키는 [tripListSyncKey] 또는 여행 ID.
  SyncTimesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'syncTimesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$syncTimesHash();

  @$internal
  @override
  SyncTimes create() => SyncTimes();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, DateTime> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, DateTime>>(value),
    );
  }
}

String _$syncTimesHash() => r'3dcd5865f88d5ec72295e8ea4c38fe83e94cdb3d';

/// 오프라인 배너가 보여줄 "마지막 동기화" 시각. 키는 [tripListSyncKey] 또는 여행 ID.

abstract class _$SyncTimes extends $Notifier<Map<String, DateTime>> {
  Map<String, DateTime> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<Map<String, DateTime>, Map<String, DateTime>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, DateTime>, Map<String, DateTime>>,
              Map<String, DateTime>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 내 여행 목록. 캐시가 있으면 먼저 내보내고 뒤에서 서버 값으로 바꾼다 (features/sync-offline.md 5.3).
///
/// 여행을 만들거나 지우거나 나가면 무효화해서 다시 받는다.

@ProviderFor(TripList)
final tripListProvider = TripListProvider._();

/// 내 여행 목록. 캐시가 있으면 먼저 내보내고 뒤에서 서버 값으로 바꾼다 (features/sync-offline.md 5.3).
///
/// 여행을 만들거나 지우거나 나가면 무효화해서 다시 받는다.
final class TripListProvider extends $AsyncNotifierProvider<TripList, List<Trip>> {
  /// 내 여행 목록. 캐시가 있으면 먼저 내보내고 뒤에서 서버 값으로 바꾼다 (features/sync-offline.md 5.3).
  ///
  /// 여행을 만들거나 지우거나 나가면 무효화해서 다시 받는다.
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
  TripList create() => TripList();
}

String _$tripListHash() => r'6d81fc494d945ce6c4d2d45e571ba06901db55aa';

/// 내 여행 목록. 캐시가 있으면 먼저 내보내고 뒤에서 서버 값으로 바꾼다 (features/sync-offline.md 5.3).
///
/// 여행을 만들거나 지우거나 나가면 무효화해서 다시 받는다.

abstract class _$TripList extends $AsyncNotifier<List<Trip>> {
  FutureOr<List<Trip>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<Trip>>, List<Trip>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Trip>>, List<Trip>>,
              AsyncValue<List<Trip>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// 여행 스냅샷 (여행 정보 + 멤버 + 전체 일정). 캐시 먼저, 온라인이면 갱신.
///
/// 수정 작업 뒤에는 무효화해서 다시 받는다. 캐시에서 온 값에는 좌표가 없다.

@ProviderFor(TripSnapshotNotifier)
final tripSnapshotProvider = TripSnapshotNotifierFamily._();

/// 여행 스냅샷 (여행 정보 + 멤버 + 전체 일정). 캐시 먼저, 온라인이면 갱신.
///
/// 수정 작업 뒤에는 무효화해서 다시 받는다. 캐시에서 온 값에는 좌표가 없다.
final class TripSnapshotNotifierProvider
    extends $AsyncNotifierProvider<TripSnapshotNotifier, TripSnapshot> {
  /// 여행 스냅샷 (여행 정보 + 멤버 + 전체 일정). 캐시 먼저, 온라인이면 갱신.
  ///
  /// 수정 작업 뒤에는 무효화해서 다시 받는다. 캐시에서 온 값에는 좌표가 없다.
  TripSnapshotNotifierProvider._({
    required TripSnapshotNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'tripSnapshotProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripSnapshotNotifierHash();

  @override
  String toString() {
    return r'tripSnapshotProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  TripSnapshotNotifier create() => TripSnapshotNotifier();

  @override
  bool operator ==(Object other) {
    return other is TripSnapshotNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripSnapshotNotifierHash() => r'1dc9bc67d33af394b269d57192f1d1eca5148000';

/// 여행 스냅샷 (여행 정보 + 멤버 + 전체 일정). 캐시 먼저, 온라인이면 갱신.
///
/// 수정 작업 뒤에는 무효화해서 다시 받는다. 캐시에서 온 값에는 좌표가 없다.

final class TripSnapshotNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          TripSnapshotNotifier,
          AsyncValue<TripSnapshot>,
          TripSnapshot,
          FutureOr<TripSnapshot>,
          String
        > {
  TripSnapshotNotifierFamily._()
    : super(
        retry: null,
        name: r'tripSnapshotProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 여행 스냅샷 (여행 정보 + 멤버 + 전체 일정). 캐시 먼저, 온라인이면 갱신.
  ///
  /// 수정 작업 뒤에는 무효화해서 다시 받는다. 캐시에서 온 값에는 좌표가 없다.

  TripSnapshotNotifierProvider call(String tripId) =>
      TripSnapshotNotifierProvider._(argument: tripId, from: this);

  @override
  String toString() => r'tripSnapshotProvider';
}

/// 여행 스냅샷 (여행 정보 + 멤버 + 전체 일정). 캐시 먼저, 온라인이면 갱신.
///
/// 수정 작업 뒤에는 무효화해서 다시 받는다. 캐시에서 온 값에는 좌표가 없다.

abstract class _$TripSnapshotNotifier extends $AsyncNotifier<TripSnapshot> {
  late final _$args = ref.$arg as String;
  String get tripId => _$args;

  FutureOr<TripSnapshot> build(String tripId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<TripSnapshot>, TripSnapshot>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<TripSnapshot>, TripSnapshot>,
              AsyncValue<TripSnapshot>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}

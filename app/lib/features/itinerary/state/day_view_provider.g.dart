// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_view_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 하루 일정 + 이동 구간. 화면이 열려 있는 동안만 메모리에 둔다 (autoDispose).
///
/// 이동시간은 Google 약관상 저장할 수 없어서 기기 DB에 넣지 않는다 (features/routes-map.md 5.2).

@ProviderFor(dayView)
final dayViewProvider = DayViewFamily._();

/// 하루 일정 + 이동 구간. 화면이 열려 있는 동안만 메모리에 둔다 (autoDispose).
///
/// 이동시간은 Google 약관상 저장할 수 없어서 기기 DB에 넣지 않는다 (features/routes-map.md 5.2).

final class DayViewProvider
    extends $FunctionalProvider<AsyncValue<DayView>, DayView, FutureOr<DayView>>
    with $FutureModifier<DayView>, $FutureProvider<DayView> {
  /// 하루 일정 + 이동 구간. 화면이 열려 있는 동안만 메모리에 둔다 (autoDispose).
  ///
  /// 이동시간은 Google 약관상 저장할 수 없어서 기기 DB에 넣지 않는다 (features/routes-map.md 5.2).
  DayViewProvider._({required DayViewFamily super.from, required (String, DateTime) super.argument})
    : super(
        retry: null,
        name: r'dayViewProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dayViewHash();

  @override
  String toString() {
    return r'dayViewProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<DayView> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<DayView> create(Ref ref) {
    final argument = this.argument as (String, DateTime);
    return dayView(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is DayViewProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dayViewHash() => r'11076f51917eddc5f9b9abd23f1b02b74acb373a';

/// 하루 일정 + 이동 구간. 화면이 열려 있는 동안만 메모리에 둔다 (autoDispose).
///
/// 이동시간은 Google 약관상 저장할 수 없어서 기기 DB에 넣지 않는다 (features/routes-map.md 5.2).

final class DayViewFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DayView>, (String, DateTime)> {
  DayViewFamily._()
    : super(
        retry: null,
        name: r'dayViewProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 하루 일정 + 이동 구간. 화면이 열려 있는 동안만 메모리에 둔다 (autoDispose).
  ///
  /// 이동시간은 Google 약관상 저장할 수 없어서 기기 DB에 넣지 않는다 (features/routes-map.md 5.2).

  DayViewProvider call(String tripId, DateTime day) =>
      DayViewProvider._(argument: (tripId, day), from: this);

  @override
  String toString() => r'dayViewProvider';
}

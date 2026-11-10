import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip_models.freezed.dart';
part 'trip_models.g.dart';

/// 여행 안에서의 역할. 권한표는 docs/05-data-model.md 5절.
///
/// 화면은 이 값으로 버튼을 숨길 뿐이고, 실제로 막는 것은 서버다 (07-screens 1절).
enum TripRole {
  owner,
  editor,
  viewer;

  bool get canEditTrip => this != viewer;
  bool get isOwner => this == owner;
}

/// 서버의 현지 날짜(`YYYY-MM-DD`)를 시각 정보 없는 [DateTime]으로 주고받는다.
class DateOnlyConverter implements JsonConverter<DateTime, String> {
  const new();

  @override
  DateTime fromJson(String json) {
    final date = DateTime.parse(json);
    return DateTime(date.year, date.month, date.day);
  }

  @override
  String toJson(DateTime date) => formatDateOnly(date);
}

String formatDateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// 여행 정보와 내 기준 정보(역할, 멤버 수).
@freezed
abstract class Trip with _$Trip {
  const factory({
    required String id,
    required String title,
    required String destination,
    @DateOnlyConverter() required DateTime startDate,
    @DateOnlyConverter() required DateTime endDate,
    required String timezone,
    required int version,
    required TripRole myRole,
    required int memberCount,
    required DateTime updatedAt,
  }) = _Trip;

  const new _();

  factory fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  /// 양 끝을 포함한 일수.
  int get days => endDate.difference(startDate).inDays + 1;
}

/// 여행 멤버. 서버는 다른 멤버의 이메일을 보내지 않는다.
@freezed
abstract class TripMember with _$TripMember {
  const factory({
    required String userId,
    required String displayName,
    required TripRole role,
    required DateTime joinedAt,
  }) = _TripMember;

  factory fromJson(Map<String, dynamic> json) => _$TripMemberFromJson(json);
}

/// 여행 스냅샷. F3에서 일정, F7에서 바우처가 추가된다.
@freezed
abstract class TripSnapshot with _$TripSnapshot {
  const factory({required Trip trip, required List<TripMember> members}) = _TripSnapshot;

  factory fromJson(Map<String, dynamic> json) => _$TripSnapshotFromJson(json);
}

/// 여행 만들기·수정 입력값.
@freezed
abstract class TripDraft with _$TripDraft {
  const factory({
    required String title,
    required String destination,
    @DateOnlyConverter() required DateTime startDate,
    @DateOnlyConverter() required DateTime endDate,
    required String timezone,
  }) = _TripDraft;

  const new _();

  factory fromJson(Map<String, dynamic> json) => _$TripDraftFromJson(json);

  factory fromTrip(Trip trip) => TripDraft(
    title: trip.title,
    destination: trip.destination,
    startDate: trip.startDate,
    endDate: trip.endDate,
    timezone: trip.timezone,
  );

  /// [base]와 달라진 필드만 담는다 (PATCH 본문).
  Map<String, dynamic> changesFrom(TripDraft base) {
    final mine = toJson();
    final theirs = base.toJson();
    return {
      for (final entry in mine.entries)
        if (entry.value != theirs[entry.key]) entry.key: entry.value,
    };
  }
}

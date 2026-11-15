import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';

/// 서버와 같은 일정 입력 규칙 (features/itinerary.md 6.1). 최종 검증은 서버가 한다.
abstract final class ItineraryRules {
  static const maxTitleLength = 100;
  static const maxMemoLength = 1000;
  static const maxItemsPerDay = 50;

  static final _titleControl = RegExp(r'[\x00-\x1f\x7f]');
  // 메모는 줄바꿈만 허용
  static final _memoControl = RegExp(r'[\x00-\x09\x0b-\x1f\x7f]');

  static bool titleHasInvalidChars(String value) => _titleControl.hasMatch(value);
  static bool memoHasInvalidChars(String value) => _memoControl.hasMatch(value);

  /// 머무는 시간 선택지 (분).
  static const stayOptions = [30, 60, 90, 120, 180, 240, 360];
}

/// 여행 기간의 모든 날짜.
List<DateTime> tripDays(Trip trip) => [
  for (var i = 0; i < trip.days; i++)
    DateTime(trip.startDate.year, trip.startDate.month, trip.startDate.day + i),
];

/// 처음 보여줄 날: 오늘이 여행 기간 안이면 오늘, 아니면 첫날.
DateTime initialDay(Trip trip, DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  return day.isBefore(trip.startDate) || day.isAfter(trip.endDate) ? trip.startDate : day;
}

/// 하루 항목을 순서대로.
List<ItineraryItem> itemsOfDay(List<ItineraryItem> items, DateTime day) =>
    items.where((i) => i.day == day).toList()..sort((a, b) => a.position.compareTo(b.position));

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// "12/24 (목)".
String formatDayChip(DateTime day) => '${day.month}/${day.day} (${_weekdays[day.weekday - 1]})';

/// "1시간 30분", "45분".
String formatStay(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest분';
  return rest == 0 ? '$hours시간' : '$hours시간 $rest분';
}

/// TimeOfDay 대신 서버 형식 "HH:MM" 문자열로 다룬다.
String formatHhMm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

int _minutesOf(String hhmm) {
  final parts = hhmm.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

/// 계획 시각으로는 몇 분 늦는지 (features/routes-map.md 5.6). 늦지 않거나 계산할 수 없으면 null.
///
/// 앞 시작 + 앞 머무는 시간 + 이동시간 > 다음 시작이면 그 차이. 자정을 넘기는 일정은 경고하지 않는다.
int? lateMinutes(ItineraryItem from, ItineraryItem to, RouteLeg leg) {
  final fromTime = from.startTime;
  final toTime = to.startTime;
  final duration = leg.durationSeconds;
  if (leg.status != LegStatus.ok || fromTime == null || toTime == null || duration == null) {
    return null;
  }
  final start = _minutesOf(fromTime);
  final next = _minutesOf(toTime);
  if (next < start) return null;
  final arrival = start + (from.stayMinutes ?? 0) + (duration / 60).ceil();
  final late = arrival - next;
  return late > 0 ? late : null;
}

/// 이동시간 표시: "21분", "1시간 5분". 초는 올려서 분으로.
String formatDuration(int seconds) => formatStay((seconds / 60).ceil());

/// 거리 표시: "850m", "3.9km".
String formatDistance(int meters) =>
    meters < 1000 ? '${meters}m' : '${(meters / 1000).toStringAsFixed(1)}km';

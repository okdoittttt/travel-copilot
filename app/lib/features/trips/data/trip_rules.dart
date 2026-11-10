import 'package:travelcopilot/features/trips/data/trip_models.dart';

/// 서버와 같은 입력 규칙 (features/trips.md 5.5). 최종 검증은 서버가 한다.
abstract final class TripRules {
  static const maxTitleLength = 100;
  static const maxTripDays = 60;

  static final _controlChars = RegExp(r'[\x00-\x1f\x7f]');

  /// 제목·목적지 검사. 문제가 없으면 null, 있으면 문제 종류.
  static TextProblem? checkText(String value) {
    final text = value.trim();
    if (text.isEmpty) return TextProblem.empty;
    if (text.length > maxTitleLength) return TextProblem.tooLong;
    if (_controlChars.hasMatch(text)) return TextProblem.invalidChars;
    return null;
  }

  /// 시작 ≤ 종료, 양 끝 포함 60일 이하.
  static bool periodIsValid(DateTime start, DateTime end) =>
      !end.isBefore(start) && end.difference(start).inDays + 1 <= maxTripDays;
}

enum TextProblem { empty, tooLong, invalidChars }

/// 여행 목록을 "다가오는 여행"과 "지난 여행"으로 나눈다.
///
/// 다가오는 여행(종료일 ≥ 오늘)은 가까운 순, 지난 여행은 최근 순.
({List<Trip> upcoming, List<Trip> past}) splitTrips(List<Trip> trips, DateTime today) {
  final day = DateTime(today.year, today.month, today.day);
  final upcoming = trips.where((t) => !t.endDate.isBefore(day)).toList()
    ..sort((a, b) => a.startDate.compareTo(b.startDate));
  final past = trips.where((t) => t.endDate.isBefore(day)).toList()
    ..sort((a, b) => b.endDate.compareTo(a.endDate));
  return (upcoming: upcoming, past: past);
}

/// 기간 표시: "12월 20일 ~ 27일 · 8일". 올해가 아니면 연도를 붙이고, 달이 바뀌면 달도 쓴다.
String formatPeriod(DateTime start, DateTime end, DateTime today) {
  String full(DateTime d) =>
      d.year == today.year ? '${d.month}월 ${d.day}일' : '${d.year}년 ${d.month}월 ${d.day}일';
  final days = end.difference(start).inDays + 1;
  final String endText;
  if (start.year != end.year) {
    endText = '${end.year}년 ${end.month}월 ${end.day}일';
  } else if (start.month != end.month) {
    endText = '${end.month}월 ${end.day}일';
  } else {
    endText = '${end.day}일';
  }
  return start == end ? '${full(start)} · 1일' : '${full(start)} ~ $endText · $days일';
}

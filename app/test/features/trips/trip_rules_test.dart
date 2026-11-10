import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/features/trips/data/trip_rules.dart';

import 'trip_fixtures.dart';

void main() {
  group('입력 검사', () {
    test('제목', () {
      expect(TripRules.checkText('  파리  '), isNull);
      expect(TripRules.checkText('   '), TextProblem.empty);
      expect(TripRules.checkText('가' * 101), TextProblem.tooLong);
      expect(TripRules.checkText('줄\n바꿈'), TextProblem.invalidChars);
    });

    test('기간은 양 끝 포함 60일까지', () {
      expect(TripRules.periodIsValid(DateTime(2026), DateTime(2026, 3)), isTrue);
      expect(TripRules.periodIsValid(DateTime(2026), DateTime(2026, 3, 2)), isFalse);
      expect(TripRules.periodIsValid(DateTime(2026, 1, 2), DateTime(2026)), isFalse);
    });
  });

  test('다가오는 여행은 가까운 순, 지난 여행은 최근 순', () {
    final today = DateTime(2026, 11, 8, 15);
    final trips = [
      makeTrip(id: 'far', start: DateTime(2027, 2), end: DateTime(2027, 2, 5)),
      makeTrip(id: 'old', start: DateTime(2025, 8), end: DateTime(2025, 8, 3)),
      makeTrip(id: 'now', start: DateTime(2026, 11, 5), end: DateTime(2026, 11, 8)),
      makeTrip(id: 'recent', start: DateTime(2026, 10), end: DateTime(2026, 10, 3)),
      makeTrip(id: 'soon', start: DateTime(2026, 12), end: DateTime(2026, 12, 3)),
    ];

    final (:upcoming, :past) = splitTrips(trips, today);

    expect(upcoming.map((t) => t.id), ['now', 'soon', 'far']);
    expect(past.map((t) => t.id), ['recent', 'old']);
  });

  test('기간 표시', () {
    final today = DateTime(2026, 11, 8);

    expect(
      formatPeriod(DateTime(2026, 12, 20), DateTime(2026, 12, 27), today),
      '12월 20일 ~ 27일 · 8일',
    );
    expect(
      formatPeriod(DateTime(2026, 12, 30), DateTime(2027, 1, 2), today),
      '12월 30일 ~ 2027년 1월 2일 · 4일',
    );
    expect(
      formatPeriod(DateTime(2026, 11, 28), DateTime(2026, 12, 2), today),
      '11월 28일 ~ 12월 2일 · 5일',
    );
    expect(formatPeriod(DateTime(2025, 8), DateTime(2025, 8), today), '2025년 8월 1일 · 1일');
  });
}

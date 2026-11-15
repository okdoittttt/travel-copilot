import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_rules.dart';
import 'package:travelcopilot/features/places/data/places_api.dart';

import '../trips/trip_fixtures.dart';
import 'itinerary_fixtures.dart';

void main() {
  test('서버 항목 JSON을 읽는다', () {
    final item = ItineraryItem.fromJson({
      'id': 'i1',
      'day': '2026-12-21',
      'position': 0,
      'title': '오르세',
      'memo': null,
      'place_id': 'ChIJ_abc',
      'location': {'lat': 48.86, 'lng': 2.3266},
      'start_time': '10:00',
      'stay_minutes': 180,
      'travel_mode': 'transit',
      'version': 2,
      'updated_at': '2026-11-10T03:00:00Z',
    });

    expect(item.day, DateTime(2026, 12, 21));
    expect(item.location?.lat, 48.86);
    expect(item.travelMode, TravelMode.transit);
  });

  test('수정 본문에는 바뀐 필드만, 지운 필드는 null로 담는다', () {
    final base = ItemDraft.fromItem(makeItem(memo: '메모', stayMinutes: 60));
    final edited = base.copyWith(title: '새 제목', memo: null);

    expect(edited.changesFrom(base), {'title': '새 제목', 'memo': null});
  });

  test('여행 날짜 목록과 처음 보여줄 날', () {
    final trip = makeTrip(start: DateTime(2026, 12, 30), end: DateTime(2027, 1, 2));

    expect(tripDays(trip), [
      DateTime(2026, 12, 30),
      DateTime(2026, 12, 31),
      DateTime(2027),
      DateTime(2027, 1, 2),
    ]);
    expect(initialDay(trip, DateTime(2026, 12, 31, 15)), DateTime(2026, 12, 31));
    expect(initialDay(trip, DateTime(2026, 11, 10)), DateTime(2026, 12, 30));
  });

  test('하루 항목은 순서대로', () {
    final items = [
      makeItem(id: 'b', position: 1),
      makeItem(id: 'x', day: DateTime(2026, 12, 22)),
      makeItem(id: 'a'),
    ];

    expect(itemsOfDay(items, DateTime(2026, 12, 21)).map((i) => i.id), ['a', 'b']);
  });

  test('표시 형식', () {
    expect(formatDayChip(DateTime(2026, 12, 24)), '12/24 (목)');
    expect(formatStay(45), '45분');
    expect(formatStay(60), '1시간');
    expect(formatStay(90), '1시간 30분');
    expect(formatHhMm(9, 5), '09:05');
  });

  test('세션 토큰은 서버 규칙에 맞는 무작위 값', () {
    final pattern = RegExp(r'^[A-Za-z0-9_-]{16,64}$');
    final a = newPlacesSessionToken();
    final b = newPlacesSessionToken();

    expect(pattern.hasMatch(a), isTrue);
    expect(a, isNot(b));
    expect(newPlacesSessionToken(Random(1)), newPlacesSessionToken(Random(1)));
  });
}

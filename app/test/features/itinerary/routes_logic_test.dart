import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_rules.dart';

import 'itinerary_fixtures.dart';

RouteLeg _leg({LegStatus status = LegStatus.ok, int seconds = 1200}) => RouteLeg(
  fromItemId: 'a',
  toItemId: 'b',
  status: status,
  mode: TravelMode.transit,
  durationSeconds: status == LegStatus.ok ? seconds : null,
  distanceMeters: status == LegStatus.ok ? 3900 : null,
);

void main() {
  test('서버 구간 JSON을 읽는다 (snake_case 상태값)', () {
    final leg = RouteLeg.fromJson({
      'from_item_id': 'a',
      'to_item_id': 'b',
      'mode': null,
      'status': 'no_location',
      'duration_seconds': null,
      'distance_meters': null,
    });

    expect(leg.status, LegStatus.noLocation);
    expect(leg.mode, isNull);
  });

  group('시각 불일치 (features/routes-map.md 5.6)', () {
    final from = makeItem(id: 'a', startTime: '10:00', stayMinutes: 60);

    test('딱 맞으면 경고 없음', () {
      // 10:00 + 60분 + 20분 = 11:20
      expect(lateMinutes(from, makeItem(id: 'b', startTime: '11:20'), _leg()), isNull);
    });

    test('1분 늦으면 1', () {
      expect(lateMinutes(from, makeItem(id: 'b', startTime: '11:19'), _leg()), 1);
    });

    test('이동시간 초는 올려서 계산', () {
      expect(lateMinutes(from, makeItem(id: 'b', startTime: '11:20'), _leg(seconds: 1201)), 1);
    });

    test('머무는 시간이 없으면 0으로', () {
      final noStay = makeItem(id: 'a', startTime: '10:00');
      expect(lateMinutes(noStay, makeItem(id: 'b', startTime: '10:10'), _leg()), 10);
    });

    test('시각이 없거나 구간이 ok가 아니면 계산하지 않음', () {
      expect(lateMinutes(makeItem(id: 'a'), makeItem(id: 'b', startTime: '11:00'), _leg()), isNull);
      expect(lateMinutes(from, makeItem(id: 'b'), _leg()), isNull);
      expect(
        lateMinutes(
          from,
          makeItem(id: 'b', startTime: '10:30'),
          _leg(status: LegStatus.unavailable),
        ),
        isNull,
      );
    });

    test('자정을 넘기는 일정은 경고하지 않음', () {
      final late = makeItem(id: 'a', startTime: '23:30', stayMinutes: 30);
      expect(lateMinutes(late, makeItem(id: 'b', startTime: '00:10'), _leg()), isNull);
    });
  });

  test('표시 형식', () {
    expect(formatDuration(1260), '21분');
    expect(formatDuration(3900), '1시간 5분');
    expect(formatDistance(850), '850m');
    expect(formatDistance(3900), '3.9km');
  });
}

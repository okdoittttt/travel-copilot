import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';

import 'trip_fixtures.dart';

void main() {
  test('서버 스냅샷 JSON을 읽는다', () {
    final snapshot = TripSnapshot.fromJson({
      'trip': {
        'id': 't1',
        'title': '파리',
        'destination': '프랑스',
        'start_date': '2026-12-20',
        'end_date': '2026-12-27',
        'timezone': 'Europe/Paris',
        'version': 3,
        'my_role': 'editor',
        'member_count': 2,
        'updated_at': '2026-11-08T03:00:00Z',
      },
      'members': [
        {
          'user_id': 'u1',
          'display_name': '주인',
          'role': 'owner',
          'joined_at': '2026-11-08T03:00:00Z',
        },
      ],
    });

    expect(snapshot.trip.startDate, DateTime(2026, 12, 20));
    expect(snapshot.trip.myRole, TripRole.editor);
    expect(snapshot.trip.days, 8);
    expect(snapshot.members.single.role, TripRole.owner);
  });

  test('입력값은 날짜만 snake_case로 보낸다', () {
    final draft = TripDraft.fromTrip(makeTrip());

    expect(draft.toJson(), {
      'title': '파리 가족여행',
      'destination': '프랑스 파리',
      'start_date': '2026-12-20',
      'end_date': '2026-12-27',
      'timezone': 'Europe/Paris',
    });
  });

  test('수정 본문에는 바뀐 필드만 담는다', () {
    final base = TripDraft.fromTrip(makeTrip());
    final edited = base.copyWith(title: '새 제목', endDate: DateTime(2026, 12, 30));

    expect(edited.changesFrom(base), {'title': '새 제목', 'end_date': '2026-12-30'});
    expect(base.changesFrom(base), isEmpty);
  });

  test('역할별 권한 표시', () {
    expect(TripRole.owner.canEditTrip, isTrue);
    expect(TripRole.editor.canEditTrip, isTrue);
    expect(TripRole.viewer.canEditTrip, isFalse);
    expect(TripRole.editor.isOwner, isFalse);
  });
}

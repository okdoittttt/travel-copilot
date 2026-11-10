import 'package:travelcopilot/features/trips/data/trip_models.dart';

Trip makeTrip({
  String id = 't1',
  String title = '파리 가족여행',
  DateTime? start,
  DateTime? end,
  TripRole role = TripRole.owner,
  int version = 1,
}) => Trip(
  id: id,
  title: title,
  destination: '프랑스 파리',
  startDate: start ?? DateTime(2026, 12, 20),
  endDate: end ?? DateTime(2026, 12, 27),
  timezone: 'Europe/Paris',
  version: version,
  myRole: role,
  memberCount: 2,
  updatedAt: DateTime.utc(2026, 11, 8),
);

TripMember makeMember(String userId, String name, TripRole role) =>
    TripMember(userId: userId, displayName: name, role: role, joinedAt: DateTime.utc(2026, 11, 8));

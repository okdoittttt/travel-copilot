import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';

ItineraryItem makeItem({
  String id = 'i1',
  String title = '일정',
  DateTime? day,
  int position = 0,
  int version = 1,
  String? memo,
  String? placeId,
  int? stayMinutes,
}) => ItineraryItem(
  id: id,
  day: day ?? DateTime(2026, 12, 21),
  position: position,
  title: title,
  version: version,
  updatedAt: DateTime.utc(2026, 11, 10),
  memo: memo,
  placeId: placeId,
  stayMinutes: stayMinutes,
);

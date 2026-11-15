import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_api.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';

part 'day_view_provider.g.dart';

/// 하루 일정 + 이동 구간. 화면이 열려 있는 동안만 메모리에 둔다 (autoDispose).
///
/// 이동시간은 Google 약관상 저장할 수 없어서 기기 DB에 넣지 않는다 (features/routes-map.md 5.2).
@riverpod
Future<DayView> dayView(Ref ref, String tripId, DateTime day) =>
    ref.watch(itineraryApiProvider).day(tripId, day);

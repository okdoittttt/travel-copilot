import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/data/trips_api.dart';

part 'trips_providers.g.dart';

/// 내 여행 목록. 여행을 만들거나 지우거나 나가면 무효화해서 다시 받는다.
@riverpod
Future<List<Trip>> tripList(Ref ref) => ref.watch(tripsApiProvider).fetchAll();

/// 여행 스냅샷 (여행 정보 + 멤버). 수정 작업 뒤에는 무효화해서 다시 받는다.
@riverpod
Future<TripSnapshot> tripSnapshot(Ref ref, String tripId) =>
    ref.watch(tripsApiProvider).snapshot(tripId);

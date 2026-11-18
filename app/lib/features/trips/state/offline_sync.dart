import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/state/connectivity.dart';
import 'package:travelcopilot/features/itinerary/state/day_view_provider.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';

part 'offline_sync.g.dart';

/// 지금 보고 있는 여행 데이터를 다시 받는다 ([다시 시도], 앱 복귀).
///
/// 목록·스냅샷은 캐시를 먼저 보여준 채 뒤에서 갱신하므로 화면이 비지 않는다.
void refreshTripData(void Function(ProviderOrFamily provider) invalidate) {
  invalidate(tripListProvider);
  invalidate(tripSnapshotProvider);
  invalidate(dayViewProvider);
}

/// 앱이 다시 앞으로 왔을 때, 오프라인이었다면 다시 확인한다 (features/sync-offline.md 5.4).
///
/// 몰래 주기적으로 재시도하지 않는다. 온라인이면 아무것도 하지 않는다.
@Riverpod(keepAlive: true)
void offlineResumeSync(Ref ref) {
  final listener = AppLifecycleListener(
    onResume: () {
      if (ref.read(connectivityProvider) == ConnectionStatus.offline) {
        refreshTripData(ref.invalidate);
      }
    },
  );
  ref.onDispose(listener.dispose);
}

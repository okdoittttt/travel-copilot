import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travelcopilot/core/state/connectivity.dart';
import 'package:travelcopilot/features/trips/state/offline_sync.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

/// 서버에 닿지 못하는 상태인지.
bool watchOffline(WidgetRef ref) => ref.watch(connectivityProvider) == ConnectionStatus.offline;

/// 오프라인이면 "연결 후 수정할 수 있습니다"를 보여주고 false (features/sync-offline.md 5.5).
///
/// 수정 동작의 맨 앞에서 부른다. 요청을 보내 보기 전에는 상태를 모르므로(unknown) 막지 않는다.
bool ensureOnline(BuildContext context, WidgetRef ref) {
  if (ref.read(connectivityProvider) != ConnectionStatus.offline) return true;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).offlineEditBlocked)));
  return false;
}

/// 상단 오프라인 배너: "오프라인 · 마지막 동기화: 3시간 전" + [다시 시도].
class OfflineBanner extends ConsumerWidget {
  /// [syncKey]: 목록이면 [tripListSyncKey], 여행 상세면 여행 ID.
  const new({required this.syncKey, super.key, this.now});

  final String syncKey;

  /// 테스트에서 "지금"을 고정할 때 쓴다.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!watchOffline(ref)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final syncedAt = ref.watch(syncTimesProvider.select((times) => times[syncKey]));
    final text = syncedAt == null
        ? l10n.offlineBanner
        : l10n.offlineBannerSynced(formatAgo(l10n, syncedAt, now ?? DateTime.now()));
    final colors = Theme.of(context).colorScheme;
    return Material(
      key: const Key('offline-banner'),
      color: colors.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 18, color: colors.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: TextStyle(color: colors.onSecondaryContainer)),
            ),
            TextButton(onPressed: () => refreshTripData(ref.invalidate), child: Text(l10n.retry)),
          ],
        ),
      ),
    );
  }
}

/// "방금", "5분 전", "3시간 전", "2일 전".
String formatAgo(AppLocalizations l10n, DateTime then, DateTime now) {
  final diff = now.difference(then);
  if (diff.inMinutes < 1) return l10n.agoJustNow;
  if (diff.inHours < 1) return l10n.agoMinutes(diff.inMinutes);
  if (diff.inDays < 1) return l10n.agoHours(diff.inHours);
  return l10n.agoDays(diff.inDays);
}

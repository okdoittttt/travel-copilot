import 'package:flutter/material.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_rules.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

/// 일정 사이 이동 구간 한 줄. [leg]가 null이면 아직 불러오는 중.
class LegRow extends StatelessWidget {
  const new({required this.leg, super.key, this.lateMinutes});

  final RouteLeg? leg;

  /// 계획 시각으로 늦는 분 수. 있으면 주황색 경고.
  final int? lateMinutes;

  static IconData iconFor(TravelMode? mode) => switch (mode) {
    TravelMode.drive => Icons.directions_car_outlined,
    TravelMode.transit => Icons.directions_transit_outlined,
    TravelMode.walk => Icons.directions_walk,
    null => Icons.more_vert,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final leg = this.leg;
    final late = lateMinutes;
    final warning = late != null;
    final color = warning ? Colors.orange.shade800 : theme.colorScheme.onSurfaceVariant;

    final String text;
    if (leg == null) {
      text = '…';
    } else {
      text = switch (leg.status) {
        LegStatus.ok =>
          '${formatDuration(leg.durationSeconds!)} · ${formatDistance(leg.distanceMeters!)}',
        LegStatus.noMode => l10n.legNoMode,
        LegStatus.noLocation => '— ${l10n.legNoLocation}',
        LegStatus.unavailable => l10n.legUnavailable,
      };
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(72, 2, 16, 2),
      child: Row(
        children: [
          Icon(iconFor(leg?.mode), size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              late != null ? '$text  ⚠ ${l10n.legLate(late)}' : text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: warning ? FontWeight.w600 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

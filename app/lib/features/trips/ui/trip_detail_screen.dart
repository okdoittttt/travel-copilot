import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/router/app_router.dart';
import 'package:travelcopilot/features/auth/state/auth_controller.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/data/trip_rules.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';
import 'package:travelcopilot/features/trips/ui/members_tab.dart';
import 'package:travelcopilot/features/trips/ui/trip_actions.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

enum _MenuAction { edit, delete, leave }

/// S05 여행 상세. 탭: 일정(F3) / 바우처(F7) / 멤버.
class TripDetailScreen extends ConsumerWidget {
  const new({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapshot = ref.watch(tripSnapshotProvider(tripId));
    final myUserId = ref.watch(authControllerProvider).value?.id ?? '';

    return snapshot.when(
      data: (value) => _TripDetailView(snapshot: value, myUserId: myUserId),
      error: (error, _) {
        // 내보내졌거나 삭제된 여행이면 목록도 다시 받는다 (목록에서 사라지게)
        final gone = error is ServerException && error.statusCode == 404;
        return Scaffold(
          appBar: AppBar(),
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(gone ? l10n.errorTripGone : l10n.tripsLoadFailed),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () {
                    if (gone) {
                      ref.invalidate(tripListProvider);
                      context.go(Routes.trips);
                    } else {
                      ref.invalidate(tripSnapshotProvider(tripId));
                    }
                  },
                  child: Text(gone ? l10n.tripsTitle : l10n.retry),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _TripDetailView extends ConsumerWidget {
  const new({required this.snapshot, required this.myUserId});

  final TripSnapshot snapshot;
  final String myUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trip = snapshot.trip;
    final role = trip.myRole;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(trip.title),
          actions: [
            PopupMenuButton<_MenuAction>(
              key: const Key('trip-menu'),
              onSelected: (action) => switch (action) {
                _MenuAction.edit => context.push(Routes.editTrip(trip.id)),
                _MenuAction.delete => deleteTrip(context, ref, trip),
                _MenuAction.leave => leaveTrip(context, ref, trip, myUserId),
              },
              itemBuilder: (context) => [
                if (role.canEditTrip)
                  PopupMenuItem(value: _MenuAction.edit, child: Text(l10n.tripEdit)),
                if (role.isOwner)
                  PopupMenuItem(value: _MenuAction.delete, child: Text(l10n.tripDelete)),
                if (!role.isOwner)
                  PopupMenuItem(value: _MenuAction.leave, child: Text(l10n.tripLeave)),
              ],
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.tabItinerary),
              Tab(text: l10n.tabVouchers),
              Tab(text: l10n.tabMembers),
            ],
          ),
        ),
        body: Column(
          children: [
            ListTile(
              title: Text(formatPeriod(trip.startDate, trip.endDate, DateTime.now())),
              subtitle: Text('${trip.destination} · ${trip.timezone.replaceAll('_', ' ')}'),
              trailing: Chip(label: Text(role.label(l10n))),
            ),
            const Divider(height: 1),
            Expanded(
              child: TabBarView(
                children: [
                  Center(child: Text(l10n.itineraryComingSoon)),
                  Center(child: Text(l10n.vouchersComingSoon)),
                  MembersTab(snapshot: snapshot, myUserId: myUserId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

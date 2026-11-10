import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travelcopilot/core/router/app_router.dart';
import 'package:travelcopilot/features/auth/state/auth_controller.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/data/trip_rules.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';
import 'package:travelcopilot/features/trips/ui/trip_actions.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

/// S03 여행 목록 (로그인 후 첫 화면).
class TripListScreen extends ConsumerWidget {
  const new({super.key, this.today});

  /// 테스트에서 "오늘"을 고정할 때 쓴다.
  final DateTime? today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(tripListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tripsTitle),
        actions: [
          // 설정 화면(S17)은 F9. 그 전까지 로그아웃은 여기에 둔다
          TextButton(
            onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
            child: Text(l10n.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.newTrip),
        icon: const Icon(Icons.add),
        label: Text(l10n.tripCreate),
      ),
      body: trips.when(
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(tripListProvider.future),
          child: _TripListView(trips: items, today: today ?? DateTime.now()),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.tripsLoadFailed),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(tripListProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _TripListView extends StatelessWidget {
  const new({required this.trips, required this.today});

  final List<Trip> trips;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (trips.isEmpty) {
      // 빈 상태에서도 당겨서 새로고침이 되도록 스크롤 가능한 목록으로 둔다
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 160),
          Text(l10n.tripsEmpty, textAlign: TextAlign.center),
        ],
      );
    }
    final (:upcoming, :past) = splitTrips(trips, today);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (upcoming.isNotEmpty) ...[
          _SectionHeader(l10n.tripsUpcoming),
          for (final trip in upcoming) _TripCard(trip: trip, today: today),
        ],
        if (past.isNotEmpty) ...[
          _SectionHeader(l10n.tripsPast),
          for (final trip in past) _TripCard(trip: trip, today: today),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
    child: Text(text, style: Theme.of(context).textTheme.titleSmall),
  );
}

class _TripCard extends StatelessWidget {
  const new({required this.trip, required this.today});

  final Trip trip;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(trip.title),
        subtitle: Text('${trip.destination}\n${formatPeriod(trip.startDate, trip.endDate, today)}'),
        isThreeLine: true,
        trailing: Chip(label: Text(trip.myRole.label(l10n))),
        onTap: () => context.push(Routes.trip(trip.id)),
      ),
    );
  }
}

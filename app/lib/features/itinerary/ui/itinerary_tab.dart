import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/router/app_router.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_api.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_rules.dart';
import 'package:travelcopilot/features/itinerary/state/day_view_provider.dart';
import 'package:travelcopilot/features/itinerary/ui/day_map_view.dart';
import 'package:travelcopilot/features/itinerary/ui/leg_row.dart';
import 'package:travelcopilot/features/places/ui/place_sheet.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';
import 'package:travelcopilot/features/trips/ui/offline_banner.dart';
import 'package:travelcopilot/features/trips/ui/trip_actions.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

/// S06 일정 (여행 상세의 일정 탭). 위: 날짜 목록, 아래: 그날 항목.
///
/// owner·editor는 추가, 길게 눌러 순서 변경, 밀어서 삭제. viewer는 보기만.
/// 항목 사이에는 이동 구간(서버가 Google Routes로 계산, 저장 안 함)과 시각 불일치 경고를 보여준다.
/// 위의 [목록 | 지도]로 S07 지도와 전환한다.
class ItineraryTab extends ConsumerStatefulWidget {
  const new({required this.snapshot, super.key, this.today});

  final TripSnapshot snapshot;

  /// 테스트에서 "오늘"을 고정할 때 쓴다.
  final DateTime? today;

  @override
  ConsumerState<ItineraryTab> createState() => _ItineraryTabState();
}

class _ItineraryTabState extends ConsumerState<ItineraryTab> {
  late DateTime _day = initialDay(widget.snapshot.trip, widget.today ?? DateTime.now());

  /// 순서 변경을 서버에 보내는 동안 화면에 먼저 보여줄 순서.
  List<ItineraryItem>? _pendingOrder;
  bool _showMap = false;

  Trip get _trip => widget.snapshot.trip;

  @override
  void didUpdateWidget(ItineraryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 여행 기간이 바뀌어 고른 날이 밖으로 나가면 첫날로
    if (_day.isBefore(_trip.startDate) || _day.isAfter(_trip.endDate)) _day = _trip.startDate;
    if (oldWidget.snapshot != widget.snapshot) _pendingOrder = null;
  }

  Future<void> _reorder(List<ItineraryItem> current, int oldIndex, int newIndex) async {
    if (!ensureOnline(context, ref)) return;
    final ordered = [...current];
    final moved = ordered.removeAt(oldIndex);
    // onReorderItem은 빠진 자리를 이미 반영한 newIndex를 준다
    ordered.insert(newIndex, moved);
    setState(() => _pendingOrder = ordered);
    try {
      await ref.read(itineraryApiProvider).reorder(_trip.id, _day, ordered);
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _pendingOrder = null);
      handleTripError(context, ref, error, tripId: _trip.id);
    }
    _refresh();
  }

  void _refresh() {
    ref
      ..invalidate(tripSnapshotProvider(_trip.id))
      ..invalidate(dayViewProvider);
  }

  Future<bool> _delete(ItineraryItem item) async {
    if (!ensureOnline(context, ref)) return false;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.itemDeleteTitle),
        content: Text(l10n.itemDeleteBody(item.title)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return false;
    try {
      await ref.read(itineraryApiProvider).delete(_trip.id, item.id, item.version);
      _refresh();
      return true;
    } on AppException catch (error) {
      if (mounted) handleTripError(context, ref, error, tripId: _trip.id);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = _trip.myRole.canEditTrip;
    final items = _pendingOrder ?? itemsOfDay(widget.snapshot.items, _day);
    final dayView = ref.watch(dayViewProvider(_trip.id, _day));
    // 이동 구간·지도는 온라인 전용 (좌표·이동시간은 기기에 저장하지 않는다)
    final offline = watchOffline(ref) || dayView.error is NetworkException;
    // 화면의 순서와 맞는 구간만 쓴다 (순서 변경 직후 서버 응답이 오기 전 등)
    final legsByPair = {
      for (final leg in dayView.value?.legs ?? const <RouteLeg>[])
        (leg.fromItemId, leg.toItemId): leg,
    };
    Widget tile(int index) {
      final item = items[index];
      if (index == 0) return _ItemTile(trip: _trip, item: item);
      final previous = items[index - 1];
      final leg = legsByPair[(previous.id, item.id)];
      final failed = dayView.hasError && !dayView.isLoading;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!failed)
            LegRow(leg: leg, lateMinutes: leg == null ? null : lateMinutes(previous, item, leg)),
          _ItemTile(trip: _trip, item: item),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 56,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              for (final day in tripDays(_trip))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(formatDayChip(day)),
                    selected: day == _day,
                    onSelected: (_) => setState(() {
                      _day = day;
                      _pendingOrder = null;
                    }),
                  ),
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l10n.viewList), icon: const Icon(Icons.list)),
              ButtonSegment(
                value: true,
                label: Text(l10n.viewMap),
                icon: const Icon(Icons.map_outlined),
              ),
            ],
            selected: {_showMap},
            onSelectionChanged: (value) => setState(() => _showMap = value.first),
          ),
        ),
        const Divider(height: 1),
        if (dayView.hasError && !dayView.isLoading && items.length > 1)
          MaterialBanner(
            content: Text(offline ? l10n.legsOffline : l10n.legsLoadFailed),
            actions: [
              TextButton(
                onPressed: () => ref.invalidate(dayViewProvider(_trip.id, _day)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        if (_showMap)
          Expanded(
            child: offline
                ? Center(child: Text(l10n.mapOffline, key: const Key('map-offline')))
                : DayMapView(items: dayView.value?.items ?? const []),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: () {
                ref.invalidate(dayViewProvider(_trip.id, _day));
                return ref.read(tripSnapshotProvider(_trip.id).notifier).refresh();
              },
              child: items.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Text(l10n.itineraryEmpty, textAlign: TextAlign.center),
                      ],
                    )
                  : canEdit
                  ? ReorderableListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 96),
                      onReorderItem: (from, to) => _reorder(items, from, to),
                      children: [
                        for (final (index, item) in items.indexed)
                          Dismissible(
                            key: ValueKey(item.id),
                            direction: DismissDirection.endToStart,
                            background: ColoredBox(
                              color: Theme.of(context).colorScheme.errorContainer,
                              child: const Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: EdgeInsets.only(right: 24),
                                  child: Icon(Icons.delete_outline),
                                ),
                              ),
                            ),
                            confirmDismiss: (_) => _delete(item),
                            child: tile(index),
                          ),
                      ],
                    )
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [for (var i = 0; i < items.length; i++) tile(i)],
                    ),
            ),
          ),
        if (canEdit && !_showMap && items.length < ItineraryRules.maxItemsPerDay)
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.add),
              label: Text(l10n.itineraryAdd),
              onPressed: () {
                if (ensureOnline(context, ref)) {
                  unawaited(context.push(Routes.newItem(_trip.id, _day)));
                }
              },
            ),
          ),
      ],
    );
  }
}

class _ItemTile extends StatelessWidget {
  const new({required this.trip, required this.item});

  final Trip trip;
  final ItineraryItem item;

  @override
  Widget build(BuildContext context) {
    final details = [
      if (item.stayMinutes != null) formatStay(item.stayMinutes!),
      if (item.memo != null && item.memo!.isNotEmpty) item.memo!.split('\n').first,
    ];
    return ListTile(
      leading: SizedBox(
        width: 48,
        child: Text(item.startTime ?? '—', style: Theme.of(context).textTheme.labelLarge),
      ),
      title: Text(item.title),
      subtitle: details.isEmpty ? null : Text(details.join(' · '), maxLines: 1),
      trailing: item.placeId == null
          ? null
          : IconButton(
              key: Key('place-info-${item.id}'),
              icon: const Icon(Icons.place_outlined),
              onPressed: () => showPlaceSheet(context, title: item.title, placeId: item.placeId!),
            ),
      onTap: () => context.push(Routes.item(trip.id, item.id)),
    );
  }
}

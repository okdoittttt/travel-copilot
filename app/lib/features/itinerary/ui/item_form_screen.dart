import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_api.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_rules.dart';
import 'package:travelcopilot/features/itinerary/state/day_view_provider.dart';
import 'package:travelcopilot/features/places/data/place_models.dart';
import 'package:travelcopilot/features/places/ui/place_search_screen.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';
import 'package:travelcopilot/features/trips/ui/offline_banner.dart';
import 'package:travelcopilot/features/trips/ui/trip_actions.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

/// S09 진입점. 스냅샷에서 여행과 항목을 찾아 폼을 채운다.
class ItemFormRoute extends ConsumerWidget {
  const new({required this.tripId, super.key, this.itemId, this.day});

  final String tripId;
  final String? itemId;
  final DateTime? day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final snapshot = ref.watch(tripSnapshotProvider(tripId));
    return snapshot.when(
      data: (value) {
        final item = itemId == null ? null : value.items.where((i) => i.id == itemId).firstOrNull;
        if (itemId != null && item == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(l10n.itineraryChanged)),
          );
        }
        return ItemFormScreen(snapshot: value, initial: item, day: day);
      },
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.errorTripGone)),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

/// S09 일정 추가·수정. [initial]이 있으면 수정, viewer면 읽기 전용.
class ItemFormScreen extends ConsumerStatefulWidget {
  const new({required this.snapshot, super.key, this.initial, this.day});

  final TripSnapshot snapshot;
  final ItineraryItem? initial;
  final DateTime? day;

  @override
  ConsumerState<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends ConsumerState<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _memo = TextEditingController(text: widget.initial?.memo);
  late DateTime _day = widget.initial?.day ?? widget.day ?? _trip.startDate;
  late String? _placeId = widget.initial?.placeId;
  late String? _startTime = widget.initial?.startTime;
  late int? _stayMinutes = widget.initial?.stayMinutes;
  late TravelMode? _travelMode = widget.initial?.travelMode;

  /// 방금 고른 장소의 Google 이름·주소. 화면 힌트로만 쓰고 저장하지 않는다 (05-data-model 9절).
  PlacePick? _pick;
  bool _saving = false;

  Trip get _trip => widget.snapshot.trip;
  bool get _readOnly => !_trip.myRole.canEditTrip;

  @override
  void dispose() {
    _title.dispose();
    _memo.dispose();
    super.dispose();
  }

  String? _titleError(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = (value ?? '').trim();
    if (text.isEmpty) return l10n.errorRequired;
    if (text.length > ItineraryRules.maxTitleLength) return l10n.errorTooLong;
    if (ItineraryRules.titleHasInvalidChars(text)) return l10n.errorInvalidChars;
    return null;
  }

  String? _memoError(String? value) {
    final l10n = AppLocalizations.of(context);
    final text = value ?? '';
    if (text.length > ItineraryRules.maxMemoLength) return l10n.errorMemoTooLong;
    if (ItineraryRules.memoHasInvalidChars(text)) return l10n.errorInvalidChars;
    return null;
  }

  /// 그날 일정 중 좌표가 있는 첫 장소 근처로 검색 결과를 치우친다.
  LatLng? get _bias => itemsOfDay(
    widget.snapshot.items,
    _day,
  ).map((i) => i.location).whereType<LatLng>().firstOrNull;

  Future<void> _pickPlace() async {
    final pick = await Navigator.of(context)
        .push<PlacePick>(MaterialPageRoute(builder: (_) => PlaceSearchScreen(bias: _bias)));
    if (pick != null) {
      setState(() {
        _pick = pick;
        _placeId = pick.placeId;
      });
    }
  }

  Future<void> _pickTime() async {
    final parts = _startTime?.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: parts == null
          ? const TimeOfDay(hour: 9, minute: 0)
          : TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
    );
    if (picked != null) setState(() => _startTime = formatHhMm(picked.hour, picked.minute));
  }

  ItemDraft _draft() {
    final memo = _memo.text.trim();
    return ItemDraft(
      day: _day,
      title: _title.text.trim(),
      memo: memo.isEmpty ? null : memo,
      placeId: _placeId,
      startTime: _startTime,
      stayMinutes: _stayMinutes,
      travelMode: _travelMode,
    );
  }

  Future<void> _save() async {
    if (!ensureOnline(context, ref)) return;
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final initial = widget.initial;
      if (initial == null) {
        await ref.read(itineraryApiProvider).create(_trip.id, _draft());
        _done();
      } else {
        await _update(initial, _draft().changesFrom(ItemDraft.fromItem(initial)));
      }
    } on AppException catch (error) {
      if (mounted) handleTripError(context, ref, error, tripId: _trip.id);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 바뀐 필드만 보낸다. 다른 멤버가 먼저 고쳤으면(409) 최신 제목을 보여주고 다시 적용할지 묻는다.
  Future<void> _update(ItineraryItem base, Map<String, dynamic> changes) async {
    if (changes.isEmpty) {
      context.pop();
      return;
    }
    try {
      await ref.read(itineraryApiProvider).update(_trip.id, base.id, base.version, changes);
      _done();
    } on ServerException catch (error) {
      final current = error.body['current'];
      if (error.code != 'version_conflict' || current is! Map<String, dynamic>) rethrow;
      final latest = ItineraryItem.fromJson(current);
      setState(() => _saving = false);
      if (await _askReapply(latest)) {
        if (mounted) setState(() => _saving = true);
        await _update(latest, changes);
      } else {
        _done();
      }
    }
  }

  Future<bool> _askReapply(ItineraryItem latest) async {
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.conflictTitle),
        content: Text(l10n.conflictBody('${l10n.fieldItemTitle}: ${latest.title}')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.conflictReapply),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _done() {
    ref
      ..invalidate(tripSnapshotProvider(_trip.id))
      ..invalidate(dayViewProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = _readOnly
        ? l10n.itemView
        : widget.initial == null
        ? l10n.itemNew
        : l10n.itemEdit;
    final stayOptions = {...ItineraryRules.stayOptions, ?_stayMinutes}.toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      // 폼이 길어서 저장 버튼은 화면 아래에 고정한다
      bottomNavigationBar: _readOnly
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.save),
                ),
              ),
            ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: AbsorbPointer(
            absorbing: _readOnly,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextFormField(
                  controller: _title,
                  readOnly: _readOnly,
                  decoration: InputDecoration(labelText: l10n.fieldItemTitle),
                  maxLength: ItineraryRules.maxTitleLength,
                  validator: _titleError,
                ),
                if (_pick != null && _title.text.trim() != _pick!.googleName)
                  Row(
                    children: [
                      Expanded(child: Text(l10n.googleNameHint(_pick!.googleName))),
                      TextButton(
                        onPressed: () => setState(() => _title.text = _pick!.googleName),
                        child: Text(l10n.useThisName),
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                ListTile(
                  key: const Key('place-field'),
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.place_outlined),
                  title: Text(
                    _placeId == null
                        ? l10n.fieldPlaceHint
                        : _pick?.address ?? _pick?.googleName ?? l10n.fieldPlace,
                  ),
                  trailing: _placeId == null || _readOnly
                      ? null
                      : IconButton(
                          tooltip: l10n.placeRemove,
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                            _placeId = null;
                            _pick = null;
                          }),
                        ),
                  onTap: _pickPlace,
                ),
                DropdownButtonFormField<DateTime>(
                  initialValue: _day,
                  decoration: InputDecoration(labelText: l10n.fieldDay),
                  items: [
                    for (final day in tripDays(_trip))
                      DropdownMenuItem(value: day, child: Text(formatDayChip(day))),
                  ],
                  onChanged: (value) => setState(() => _day = value ?? _day),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(l10n.fieldStartTime),
                  trailing: Text(_startTime ?? l10n.none),
                  onTap: _pickTime,
                  onLongPress: () => setState(() => _startTime = null),
                ),
                DropdownButtonFormField<int?>(
                  initialValue: _stayMinutes,
                  decoration: InputDecoration(labelText: l10n.fieldStay),
                  items: [
                    DropdownMenuItem(child: Text(l10n.none)),
                    for (final minutes in stayOptions)
                      DropdownMenuItem(value: minutes, child: Text(formatStay(minutes))),
                  ],
                  onChanged: (value) => setState(() => _stayMinutes = value),
                ),
                const SizedBox(height: 16),
                Text(l10n.fieldTravelMode, style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                SegmentedButton<TravelMode>(
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: TravelMode.drive, label: Text(l10n.travelDrive)),
                    ButtonSegment(value: TravelMode.transit, label: Text(l10n.travelTransit)),
                    ButtonSegment(value: TravelMode.walk, label: Text(l10n.travelWalk)),
                  ],
                  selected: {?_travelMode},
                  onSelectionChanged: (value) =>
                      setState(() => _travelMode = value.isEmpty ? null : value.first),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _memo,
                  readOnly: _readOnly,
                  decoration: InputDecoration(labelText: l10n.fieldMemo),
                  maxLength: ItineraryRules.maxMemoLength,
                  maxLines: 4,
                  minLines: 2,
                  validator: _memoError,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

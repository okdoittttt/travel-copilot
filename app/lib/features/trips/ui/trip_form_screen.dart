import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/router/app_router.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/data/trip_rules.dart';
import 'package:travelcopilot/features/trips/data/trips_api.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';
import 'package:travelcopilot/features/trips/ui/timezone_picker.dart';
import 'package:travelcopilot/features/trips/ui/trip_actions.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

/// S04 수정 화면의 진입점. 스냅샷을 받아서 폼을 채운다.
class TripEditScreen extends ConsumerWidget {
  const new({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(tripSnapshotProvider(tripId));
    return snapshot.when(
      data: (value) => TripFormScreen(initial: value.trip),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(AppLocalizations.of(context).errorTripGone)),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

/// S04 여행 만들기·수정. [initial]이 있으면 수정.
class TripFormScreen extends ConsumerStatefulWidget {
  const new({super.key, this.initial, this.timezoneOptions});

  final Trip? initial;

  /// 테스트에서 시간대 목록을 바꿔 넣을 때 쓴다.
  final List<String>? timezoneOptions;

  @override
  ConsumerState<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends ConsumerState<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title);
  late final _destination = TextEditingController(text: widget.initial?.destination);
  late DateTimeRange? _period = widget.initial == null
      ? null
      : DateTimeRange(start: widget.initial!.startDate, end: widget.initial!.endDate);
  // 해외여행은 기기 시간대가 틀린 경우가 대부분이라 기본값을 비워 둔다 (07-screens S04)
  late String? _timezone = widget.initial?.timezone;
  String? _periodError;
  String? _timezoneError;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _destination.dispose();
    super.dispose();
  }

  String? _textError(String? value) {
    final l10n = AppLocalizations.of(context);
    return switch (TripRules.checkText(value ?? '')) {
      TextProblem.empty => l10n.errorRequired,
      TextProblem.tooLong => l10n.errorTooLong,
      TextProblem.invalidChars => l10n.errorInvalidChars,
      null => null,
    };
  }

  Future<void> _pickPeriod() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: _period,
    );
    if (picked != null) setState(() => _period = picked);
  }

  Future<void> _pickTimezone() async {
    final picked = await pickTimezone(context, options: widget.timezoneOptions);
    if (picked != null) setState(() => _timezone = picked);
  }

  bool _validate() {
    final l10n = AppLocalizations.of(context);
    final period = _period;
    setState(() {
      _periodError = switch (period) {
        null => l10n.errorPeriodRequired,
        _ when !TripRules.periodIsValid(period.start, period.end) => l10n.errorPeriodTooLong,
        _ => null,
      };
      _timezoneError = _timezone == null ? l10n.errorTimezoneRequired : null;
    });
    final fieldsOk = _formKey.currentState!.validate();
    return fieldsOk && _periodError == null && _timezoneError == null;
  }

  TripDraft _draft() => TripDraft(
    title: _title.text.trim(),
    destination: _destination.text.trim(),
    startDate: _period!.start,
    endDate: _period!.end,
    timezone: _timezone!,
  );

  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      final initial = widget.initial;
      if (initial == null) {
        await _create();
      } else {
        await _update(initial, _draft().changesFrom(TripDraft.fromTrip(initial)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _create() async {
    try {
      final trip = await ref.read(tripsApiProvider).create(_draft());
      ref.invalidate(tripListProvider);
      if (mounted) context.go(Routes.trip(trip.id));
    } on AppException catch (error) {
      if (mounted) handleTripError(context, ref, error);
    }
  }

  /// 바뀐 필드만 보낸다. 다른 멤버가 먼저 고쳤으면(409) 최신 내용을 보여주고,
  /// 내 수정을 다시 적용할지 묻는다. 자동으로 덮어쓰지 않는다 (07-screens 5절).
  Future<void> _update(Trip base, Map<String, dynamic> changes) async {
    if (changes.isEmpty) {
      context.pop();
      return;
    }
    try {
      await ref.read(tripsApiProvider).update(base.id, base.version, changes);
      _refresh(base.id);
      if (mounted) context.pop();
    } on ServerException catch (error) {
      if (!mounted) return;
      final current = error.body['current'];
      if (error.code == 'version_conflict' && current is Map<String, dynamic>) {
        final latest = Trip.fromJson(current);
        // 사용자가 고르는 동안에는 저장 중 표시를 멈춘다
        setState(() => _saving = false);
        if (await _askReapply(latest)) {
          if (mounted) setState(() => _saving = true);
          await _update(latest, changes);
        } else {
          _refresh(base.id);
          if (mounted) context.pop();
        }
      } else {
        handleTripError(context, ref, error, tripId: base.id);
      }
    } on AppException catch (error) {
      if (mounted) handleTripError(context, ref, error, tripId: base.id);
    }
  }

  void _refresh(String tripId) {
    ref
      ..invalidate(tripSnapshotProvider(tripId))
      ..invalidate(tripListProvider);
  }

  Future<bool> _askReapply(Trip latest) async {
    final l10n = AppLocalizations.of(context);
    final summary = [
      '${l10n.fieldTitle}: ${latest.title}',
      '${l10n.fieldDestination}: ${latest.destination}',
      '${l10n.fieldPeriod}: ${formatPeriod(latest.startDate, latest.endDate, DateTime.now())}',
      '${l10n.fieldTimezone}: ${latest.timezone}',
    ].join('\n');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.conflictTitle),
        content: Text(l10n.conflictBody(summary)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final period = _period;
    return Scaffold(
      appBar: AppBar(title: Text(widget.initial == null ? l10n.tripCreate : l10n.tripEdit)),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _title,
                decoration: InputDecoration(labelText: l10n.fieldTitle),
                maxLength: TripRules.maxTitleLength,
                textInputAction: TextInputAction.next,
                validator: _textError,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _destination,
                decoration: InputDecoration(labelText: l10n.fieldDestination),
                maxLength: TripRules.maxTitleLength,
                validator: _textError,
              ),
              const SizedBox(height: 8),
              _PickerField(
                key: const Key('period-field'),
                label: l10n.fieldPeriod,
                value: period == null
                    ? null
                    : formatPeriod(period.start, period.end, DateTime.now()),
                hint: l10n.fieldPeriodHint,
                error: _periodError,
                icon: Icons.date_range,
                onTap: _pickPeriod,
              ),
              const SizedBox(height: 16),
              _PickerField(
                key: const Key('timezone-field'),
                label: l10n.fieldTimezone,
                value: _timezone?.replaceAll('_', ' '),
                hint: l10n.fieldTimezoneHint,
                error: _timezoneError,
                icon: Icons.public,
                onTap: _pickTimezone,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.initial == null ? l10n.tripCreate : l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 누르면 선택 화면을 여는 입력칸.
class _PickerField extends StatelessWidget {
  const new({
    required this.label,
    required this.value,
    required this.hint,
    required this.error,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final String? value;
  final String hint;
  final String? error;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        suffixIcon: Icon(icon),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      isEmpty: value == null,
      child: value == null ? null : Text(value!),
    ),
  );
}

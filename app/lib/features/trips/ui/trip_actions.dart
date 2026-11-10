import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/router/app_router.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/data/trips_api.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

final _log = Logger('TripActions');

extension TripRoleLabel on TripRole {
  String label(AppLocalizations l10n) => switch (this) {
    TripRole.owner => l10n.roleOwner,
    TripRole.editor => l10n.roleEditor,
    TripRole.viewer => l10n.roleViewer,
  };
}

void showMessage(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// 여행 작업 실패를 07-screens.md 5절대로 처리한다.
///
/// - 403: 역할이 바뀌었을 수 있으니 스냅샷을 다시 받는다
/// - 404: 내보내졌거나 삭제된 여행. 목록을 다시 받고 목록 화면으로 간다
/// - 네트워크 오류: 저장되지 않았음을 분명히 알린다 (몰래 재시도하지 않음)
void handleTripError(BuildContext context, WidgetRef ref, Object error, {String? tripId}) {
  final l10n = AppLocalizations.of(context);
  _log.info('여행 작업 실패: ${error is ServerException ? error.code : error.runtimeType}');
  switch (error) {
    case ServerException(statusCode: 403):
      showMessage(context, l10n.errorForbidden);
      if (tripId != null) ref.invalidate(tripSnapshotProvider(tripId));
    case ServerException(statusCode: 404):
      showMessage(context, l10n.errorTripGone);
      ref.invalidate(tripListProvider);
      context.go(Routes.trips);
    case NetworkException():
      showMessage(context, l10n.errorNotSaved);
    default:
      showMessage(context, l10n.errorGeneric);
  }
}

Future<bool> _confirm(
  BuildContext context, {
  required String title,
  required String body,
  required String action,
  bool destructive = false,
}) async {
  final l10n = AppLocalizations.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive
              ? TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error)
              : null,
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// 여행 삭제. 실수를 막으려고 여행 제목을 다시 입력해야 한다 (07-screens S05).
Future<void> deleteTrip(BuildContext context, WidgetRef ref, Trip trip) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => _DeleteTripDialog(title: trip.title),
  );
  if (confirmed != true || !context.mounted) return;
  try {
    await ref.read(tripsApiProvider).delete(trip.id, trip.version);
    ref.invalidate(tripListProvider);
    if (context.mounted) context.go(Routes.trips);
  } on ServerException catch (error) {
    if (!context.mounted) return;
    if (error.code == 'version_conflict') {
      showMessage(context, AppLocalizations.of(context).conflictTitle);
      ref.invalidate(tripSnapshotProvider(trip.id));
    } else {
      handleTripError(context, ref, error, tripId: trip.id);
    }
  } on AppException catch (error) {
    if (context.mounted) handleTripError(context, ref, error, tripId: trip.id);
  }
}

class _DeleteTripDialog extends StatefulWidget {
  const new({required this.title});

  final String title;

  @override
  State<_DeleteTripDialog> createState() => _DeleteTripDialogState();
}

class _DeleteTripDialogState extends State<_DeleteTripDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final matches = _controller.text.trim() == widget.title;
    return AlertDialog(
      title: Text(l10n.deleteTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.deleteBody(widget.title)),
          const SizedBox(height: 12),
          TextField(
            key: const Key('delete-confirm-field'),
            controller: _controller,
            autofocus: true,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
        TextButton(
          onPressed: matches ? () => Navigator.pop(context, true) : null,
          style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          child: Text(l10n.tripDelete),
        ),
      ],
    );
  }
}

/// 여행 나가기 (editor·viewer).
Future<void> leaveTrip(BuildContext context, WidgetRef ref, Trip trip, String myUserId) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await _confirm(
    context,
    title: l10n.leaveTitle,
    body: l10n.leaveBody,
    action: l10n.tripLeave,
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;
  try {
    await ref.read(tripsApiProvider).removeMember(trip.id, myUserId);
    ref.invalidate(tripListProvider);
    if (context.mounted) context.go(Routes.trips);
  } on AppException catch (error) {
    if (context.mounted) handleTripError(context, ref, error, tripId: trip.id);
  }
}

/// 역할 변경 (owner). editor ↔ viewer.
Future<void> changeMemberRole(
  BuildContext context,
  WidgetRef ref,
  Trip trip,
  TripMember member,
  TripRole role,
) => _memberAction(context, ref, trip, () async {
  await ref.read(tripsApiProvider).changeRole(trip.id, member.userId, role);
});

/// 멤버 내보내기 (owner).
Future<void> removeMember(BuildContext context, WidgetRef ref, Trip trip, TripMember member) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await _confirm(
    context,
    title: l10n.removeTitle(member.displayName),
    body: l10n.removeBody,
    action: l10n.memberRemove,
    destructive: true,
  );
  if (!confirmed || !context.mounted) return;
  await _memberAction(context, ref, trip, () async {
    await ref.read(tripsApiProvider).removeMember(trip.id, member.userId);
  });
}

/// 소유권 넘기기 (owner). 넘기면 나는 editor가 된다.
Future<void> transferOwnership(
  BuildContext context,
  WidgetRef ref,
  Trip trip,
  TripMember member,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await _confirm(
    context,
    title: l10n.transferTitle(member.displayName),
    body: l10n.transferBody(member.displayName),
    action: l10n.memberTransfer,
  );
  if (!confirmed || !context.mounted) return;
  await _memberAction(context, ref, trip, () async {
    await ref.read(tripsApiProvider).transferOwnership(trip.id, member.userId);
  });
}

Future<void> _memberAction(
  BuildContext context,
  WidgetRef ref,
  Trip trip,
  Future<void> Function() action,
) async {
  try {
    await action();
    ref
      ..invalidate(tripSnapshotProvider(trip.id))
      ..invalidate(tripListProvider);
  } on AppException catch (error) {
    if (context.mounted) handleTripError(context, ref, error, tripId: trip.id);
  }
}

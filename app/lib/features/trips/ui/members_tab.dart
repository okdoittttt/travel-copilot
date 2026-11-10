import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';
import 'package:travelcopilot/features/trips/ui/trip_actions.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

enum _MemberAction { makeEditor, makeViewer, transfer, remove }

/// S14 멤버 (여행 상세의 멤버 탭). 관리 메뉴는 owner에게만 보인다.
class MembersTab extends ConsumerWidget {
  const new({required this.snapshot, required this.myUserId, super.key});

  final TripSnapshot snapshot;
  final String myUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trip = snapshot.trip;
    final isOwner = trip.myRole.isOwner;

    return RefreshIndicator(
      onRefresh: () => ref.refresh(tripSnapshotProvider(trip.id).future),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (isOwner)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(l10n.ownerMemberNotice, style: Theme.of(context).textTheme.bodySmall),
            ),
          for (final member in snapshot.members)
            _MemberTile(
              trip: trip,
              member: member,
              isMe: member.userId == myUserId,
              canManage: isOwner && member.userId != myUserId,
            ),
          if (!isOwner)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => leaveTrip(context, ref, trip, myUserId),
                child: Text(l10n.tripLeave),
              ),
            ),
        ],
      ),
    );
  }
}

class _MemberTile extends ConsumerWidget {
  const new({
    required this.trip,
    required this.member,
    required this.isMe,
    required this.canManage,
  });

  final Trip trip;
  final TripMember member;
  final bool isMe;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final joined = member.joinedAt.toLocal();
    final joinedText = '${joined.year}. ${joined.month}. ${joined.day}.';

    return ListTile(
      title: Text(isMe ? '${member.displayName} (${l10n.me})' : member.displayName),
      subtitle: Text('${member.role.label(l10n)} · ${l10n.joinedAt(joinedText)}'),
      trailing: canManage
          ? PopupMenuButton<_MemberAction>(
              key: Key('member-menu-${member.userId}'),
              onSelected: (action) => switch (action) {
                _MemberAction.makeEditor => changeMemberRole(
                  context,
                  ref,
                  trip,
                  member,
                  TripRole.editor,
                ),
                _MemberAction.makeViewer => changeMemberRole(
                  context,
                  ref,
                  trip,
                  member,
                  TripRole.viewer,
                ),
                _MemberAction.transfer => transferOwnership(context, ref, trip, member),
                _MemberAction.remove => removeMember(context, ref, trip, member),
              },
              itemBuilder: (context) => [
                if (member.role == TripRole.viewer)
                  PopupMenuItem(
                    value: _MemberAction.makeEditor,
                    child: Text(l10n.memberMakeEditor),
                  ),
                if (member.role == TripRole.editor)
                  PopupMenuItem(
                    value: _MemberAction.makeViewer,
                    child: Text(l10n.memberMakeViewer),
                  ),
                PopupMenuItem(value: _MemberAction.transfer, child: Text(l10n.memberTransfer)),
                PopupMenuItem(value: _MemberAction.remove, child: Text(l10n.memberRemove)),
              ],
            )
          : null,
    );
  }
}

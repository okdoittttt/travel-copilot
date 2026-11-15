import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/invites/data/invite_models.dart';
import 'package:travelcopilot/features/invites/data/invites_api.dart';
import 'package:travelcopilot/features/invites/state/invite_providers.dart';
import 'package:travelcopilot/features/trips/ui/trip_actions.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

extension InviteRoleLabel on InviteRole {
  String label(AppLocalizations l10n) => tripRole.label(l10n);
}

extension InviteStatusLabel on InviteStatus {
  String label(AppLocalizations l10n) => switch (this) {
    InviteStatus.active => l10n.inviteStatusActive,
    InviteStatus.expired => l10n.inviteStatusExpired,
    InviteStatus.revoked => l10n.inviteStatusRevoked,
    InviteStatus.exhausted => l10n.inviteStatusExhausted,
  };
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.month}/${local.day} ${local.hour}:$minute';
}

/// S15 초대 링크 관리 (owner).
///
/// 토큰이 담긴 링크는 만든 직후 공유 시트로만 내보낸다. 화면에는 보여주지 않고,
/// 다시 볼 수도 없다 (서버가 원문을 저장하지 않음, features/invites.md 5.1).
class InvitesScreen extends ConsumerWidget {
  const new({required this.tripId, super.key});

  final String tripId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final invites = ref.watch(invitesProvider(tripId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.invitesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context, ref),
        icon: const Icon(Icons.add_link),
        label: Text(l10n.inviteNew),
      ),
      body: invites.when(
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(invitesProvider(tripId).future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(l10n.inviteShareNotice, style: Theme.of(context).textTheme.bodySmall),
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Text(l10n.invitesEmpty, textAlign: TextAlign.center),
                ),
              for (final invite in items) _InviteTile(tripId: tripId, invite: invite),
            ],
          ),
        ),
        error: (_, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.inviteLoadFailed),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.invalidate(invitesProvider(tripId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Future<void> _create(BuildContext context, WidgetRef ref) async {
    final draft = await showModalBottomSheet<InviteDraft>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CreateInviteSheet(),
    );
    if (draft == null || !context.mounted) return;
    final l10n = AppLocalizations.of(context);
    try {
      final created = await ref.read(invitesApiProvider).create(tripId, draft);
      ref.invalidate(invitesProvider(tripId));
      if (!context.mounted) return;
      showMessage(context, l10n.inviteShared);
      // 링크(토큰)는 공유 시트로만 내보내고 변수도 여기서 끝난다
      await ref.read(shareTextProvider)(l10n.inviteShareText(created.url));
    } on AppException catch (error) {
      if (context.mounted) handleTripError(context, ref, error, tripId: tripId);
    }
  }
}

class _InviteTile extends ConsumerWidget {
  const new({required this.tripId, required this.invite});

  final String tripId;
  final Invite invite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final active = invite.status == InviteStatus.active;
    return ListTile(
      key: Key('invite-${invite.id}'),
      title: Text(
        '${invite.role.label(l10n)} · ${l10n.inviteUsage(invite.useCount, invite.maxUses)}',
      ),
      subtitle: Text(
        active
            ? l10n.inviteExpiresAt(_formatDateTime(invite.expiresAt))
            : invite.status.label(l10n),
      ),
      enabled: active,
      trailing: active
          ? TextButton(
              onPressed: () => _revoke(context, ref),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: Text(l10n.inviteRevoke),
            )
          : null,
    );
  }

  Future<void> _revoke(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inviteRevokeTitle),
        content: Text(l10n.inviteRevokeBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.inviteRevoke),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ref.read(invitesApiProvider).revoke(tripId, invite.id);
      ref.invalidate(invitesProvider(tripId));
    } on AppException catch (error) {
      if (context.mounted) handleTripError(context, ref, error, tripId: tripId);
    }
  }
}

/// 링크 만들기: 역할(기본 보기 전용), 사용 횟수(기본 10), 유효 기간(기본 3일).
class _CreateInviteSheet extends StatefulWidget {
  const new();

  @override
  State<_CreateInviteSheet> createState() => _CreateInviteSheetState();
}

class _CreateInviteSheetState extends State<_CreateInviteSheet> {
  static const _useOptions = [1, 2, 3, 5, 10, 20];
  static const _dayOptions = [1, 2, 3, 5, 7];

  InviteRole _role = InviteRole.viewer;
  int _maxUses = 10;
  int _days = 3;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.inviteNew, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Text(l10n.inviteRole, style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            SegmentedButton<InviteRole>(
              segments: [
                ButtonSegment(value: InviteRole.viewer, label: Text(l10n.roleViewer)),
                ButtonSegment(value: InviteRole.editor, label: Text(l10n.roleEditor)),
              ],
              selected: {_role},
              onSelectionChanged: (value) => setState(() => _role = value.single),
            ),
            if (_role == InviteRole.editor)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, size: 18, color: theme.colorScheme.error),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        l10n.inviteEditorWarning,
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const Key('invite-max-uses'),
                    initialValue: _maxUses,
                    decoration: InputDecoration(labelText: l10n.inviteMaxUses),
                    items: [
                      for (final n in _useOptions)
                        DropdownMenuItem(value: n, child: Text(l10n.inviteUsesValue(n))),
                    ],
                    onChanged: (value) => setState(() => _maxUses = value ?? _maxUses),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    key: const Key('invite-days'),
                    initialValue: _days,
                    decoration: InputDecoration(labelText: l10n.inviteExpires),
                    items: [
                      for (final n in _dayOptions)
                        DropdownMenuItem(value: n, child: Text(l10n.inviteDaysValue(n))),
                    ],
                    onChanged: (value) => setState(() => _days = value ?? _days),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => Navigator.pop(
                context,
                InviteDraft(role: _role, maxUses: _maxUses, expiresInDays: _days),
              ),
              child: Text(l10n.inviteCreate),
            ),
          ],
        ),
      ),
    );
  }
}

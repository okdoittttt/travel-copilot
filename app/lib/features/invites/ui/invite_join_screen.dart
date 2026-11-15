import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:logging/logging.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/router/app_router.dart';
import 'package:travelcopilot/features/invites/data/invite_link.dart';
import 'package:travelcopilot/features/invites/data/invite_models.dart';
import 'package:travelcopilot/features/invites/data/invites_api.dart';
import 'package:travelcopilot/features/invites/state/invite_providers.dart';
import 'package:travelcopilot/features/invites/ui/invites_screen.dart';
import 'package:travelcopilot/features/trips/data/trip_rules.dart';
import 'package:travelcopilot/features/trips/state/trips_providers.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

final _log = Logger('InviteJoin');

/// S16 초대 참여. 토큰은 [pendingInviteProvider](메모리)에서 읽고, 화면에 표시하지 않는다.
class InviteJoinScreen extends ConsumerStatefulWidget {
  const new({super.key, this.today});

  /// 테스트에서 "오늘"을 고정할 때 쓴다 (기간 표시).
  final DateTime? today;

  @override
  ConsumerState<InviteJoinScreen> createState() => _InviteJoinScreenState();
}

class _InviteJoinScreenState extends ConsumerState<InviteJoinScreen> {
  String? _token;
  InvitePreview? _preview;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _token = ref.read(pendingInviteProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final token = _token;
    final l10n = AppLocalizations.of(context);
    if (token == null) {
      setState(() {
        _busy = false;
        _error = l10n.inviteNotFound;
      });
      return;
    }
    // 다시 시도할 때 이전 오류 문구가 남지 않게 지운다
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final preview = await ref.read(invitesApiProvider).preview(token);
      if (!mounted) return;
      if (preview.alreadyMember && preview.tripId != null) {
        // 이미 멤버면 확인 없이 바로 여행으로
        _finish();
        context.go(Routes.trip(preview.tripId!));
        return;
      }
      setState(() {
        _preview = preview;
        _busy = false;
      });
    } on AppException catch (error) {
      _fail(error);
    }
  }

  Future<void> _join() async {
    final token = _token;
    if (token == null) return;
    setState(() => _busy = true);
    try {
      final tripId = await ref.read(invitesApiProvider).accept(token);
      if (!mounted) return;
      _finish();
      ref.invalidate(tripListProvider);
      context.go(Routes.trip(tripId));
    } on ServerException catch (error) {
      if (error.code == 'already_member') {
        _finish();
        ref.invalidate(tripListProvider);
        if (mounted) context.go(Routes.trips);
        return;
      }
      _fail(error);
    } on AppException catch (error) {
      _fail(error);
    }
  }

  void _fail(AppException error) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    // 토큰·URL은 남기지 않고 결과 코드만
    _log.info('초대 처리 실패: ${error is ServerException ? error.code : error.runtimeType}');
    final message = switch (error) {
      ServerException(statusCode: 410) => l10n.inviteGone,
      ServerException(statusCode: 404) => l10n.inviteNotFound,
      ServerException(code: 'trip_member_limit') => l10n.inviteMemberLimit,
      ServerException(statusCode: 429) => l10n.rateLimited,
      NetworkException() => l10n.errorNetwork,
      _ => l10n.errorGeneric,
    };
    // 다시 쓸 수 없는 링크면 토큰을 바로 버린다. 네트워크·제한은 다시 시도할 수 있게 둔다
    if (error is ServerException && error.statusCode != 429) _finish();
    setState(() {
      _busy = false;
      _error = message;
    });
  }

  /// 토큰을 메모리에서 버린다.
  void _finish() {
    _token = null;
    ref.read(pendingInviteProvider.notifier).clear();
  }

  void _cancel() {
    _finish();
    context.go(Routes.trips);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = _preview;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inviteJoinTitle),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: _cancel),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _busy && preview == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_error != null) ...[
                    Text(_error!, key: const Key('invite-error')),
                    const SizedBox(height: 16),
                    if (_token != null)
                      OutlinedButton(onPressed: _load, child: Text(l10n.retry))
                    else
                      OutlinedButton(onPressed: _cancel, child: Text(l10n.tripsTitle)),
                  ] else if (preview != null) ...[
                    Text(
                      _message(l10n, preview),
                      key: const Key('invite-message'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 32),
                    FilledButton(onPressed: _busy ? null : _join, child: Text(l10n.inviteJoin)),
                    const SizedBox(height: 8),
                    TextButton(onPressed: _busy ? null : _cancel, child: Text(l10n.cancel)),
                  ],
                ],
              ),
      ),
    );
  }

  String _message(AppLocalizations l10n, InvitePreview preview) {
    final period = formatPeriod(preview.startDate, preview.endDate, widget.today ?? DateTime.now());
    final role = preview.role.label(l10n);
    final inviter = preview.inviterName;
    return inviter == null
        ? l10n.inviteJoinBodyNoInviter(preview.tripTitle, period, role)
        : l10n.inviteJoinBody(inviter, preview.tripTitle, period, role);
  }
}

/// 여행 목록의 [초대 링크로 참여]: 붙여넣은 링크에서 토큰을 꺼내 S16으로 보낸다.
///
/// 링크로 앱이 바로 열리지 않는 환경(도메인 준비 전 등)에서도 참여할 수 있게 하는 경로다.
Future<void> joinByPastedLink(BuildContext context, WidgetRef ref) async {
  final baseUrl = ref.read(inviteBaseUrlProvider);
  final token = await showDialog<String>(
    context: context,
    builder: (_) => _PasteLinkDialog(baseUrl: baseUrl),
  );
  if (token == null || !context.mounted) return;
  ref.read(pendingInviteProvider.notifier).set(token);
  context.go(Routes.invite);
}

class _PasteLinkDialog extends StatefulWidget {
  const new({required this.baseUrl});

  final String baseUrl;

  @override
  State<_PasteLinkDialog> createState() => _PasteLinkDialogState();
}

class _PasteLinkDialogState extends State<_PasteLinkDialog> {
  final _controller = TextEditingController();
  bool _invalid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final token = parseInviteToken(_controller.text, baseUrl: widget.baseUrl);
    if (token == null) {
      setState(() => _invalid = true);
      return;
    }
    Navigator.pop(context, token);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.inviteJoinByLink),
      content: TextField(
        key: const Key('invite-link-field'),
        controller: _controller,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        keyboardType: TextInputType.url,
        decoration: InputDecoration(
          hintText: l10n.invitePasteHint,
          errorText: _invalid ? l10n.inviteLinkInvalid : null,
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(onPressed: _submit, child: Text(l10n.inviteNext)),
      ],
    );
  }
}

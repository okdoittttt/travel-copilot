import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/state/provider_retry.dart';
import 'package:travelcopilot/features/invites/data/invite_models.dart';
import 'package:travelcopilot/features/invites/data/invites_api.dart';
import 'package:travelcopilot/features/invites/state/invite_providers.dart';
import 'package:travelcopilot/features/invites/ui/invite_join_screen.dart';
import 'package:travelcopilot/features/invites/ui/invites_screen.dart';
import 'package:travelcopilot/features/trips/data/trips_api.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

class _MockInvitesApi extends Mock implements InvitesApi;

class _MockTripsApi extends Mock implements TripsApi;

const _base = 'https://travel.example.com';
final String _token = 'T' * 43;

Invite _invite({
  String id = 'i1',
  InviteRole role = InviteRole.viewer,
  InviteStatus status = InviteStatus.active,
  int used = 0,
}) => Invite(
  id: id,
  role: role,
  maxUses: 10,
  useCount: used,
  expiresAt: DateTime.utc(2030),
  createdAt: DateTime.utc(2026, 11, 15),
  status: status,
);

InvitePreview _preview({bool member = false, String? inviter = '홍길동'}) => InvitePreview(
  tripTitle: '파리 여행',
  startDate: DateTime(2026, 12, 22),
  endDate: DateTime(2026, 12, 29),
  inviterName: inviter,
  role: InviteRole.viewer,
  alreadyMember: member,
  tripId: member ? 't1' : null,
);

void main() {
  late _MockInvitesApi api;
  late ProviderContainer container;
  late List<String> shared;

  setUpAll(() => registerFallbackValue(const InviteDraft()));

  setUp(() {
    api = _MockInvitesApi();
    shared = [];
    final trips = _MockTripsApi();
    when(trips.fetchAll).thenAnswer((_) async => []);
    container = ProviderContainer(
      retry: disableAutoRetry,
      overrides: [
        invitesApiProvider.overrideWithValue(api),
        tripsApiProvider.overrideWithValue(trips),
        inviteBaseUrlProvider.overrideWithValue(_base),
        shareTextProvider.overrideWithValue((text) async => shared.add(text)),
      ],
    );
  });

  tearDown(() => container.dispose());

  Future<void> pump(WidgetTester tester, String initial, Widget screen) async {
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: '/screen', builder: (_, _) => screen),
        GoRoute(path: '/invite', builder: (_, _) => const InviteJoinScreen()),
        GoRoute(
          path: '/trips',
          builder: (_, _) => Scaffold(
            body: Consumer(
              builder: (context, ref, _) => Column(
                children: [
                  const Text('목록 화면'),
                  TextButton(
                    onPressed: () => joinByPastedLink(context, ref),
                    child: const Text('붙여넣기'),
                  ),
                ],
              ),
            ),
          ),
        ),
        GoRoute(path: '/trips/:id', builder: (_, s) => Text('상세 ${s.pathParameters['id']}')),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('S15 초대 링크 관리', () {
    testWidgets('목록에 역할·사용 횟수·상태, 끝난 링크는 폐기 버튼 없음', (tester) async {
      when(() => api.list('t1')).thenAnswer(
        (_) async => [
          _invite(role: InviteRole.editor, used: 3),
          _invite(id: 'i2', status: InviteStatus.revoked),
        ],
      );
      await pump(tester, '/screen', const InvitesScreen(tripId: 't1'));

      expect(find.text('편집자 · 3/10회 사용'), findsOneWidget);
      expect(find.text('폐기됨'), findsOneWidget);
      expect(find.widgetWithText(TextButton, '폐기'), findsOneWidget);
    });

    testWidgets('기본값은 보기 전용, 편집자를 고르면 경고', (tester) async {
      when(() => api.list('t1')).thenAnswer((_) async => []);
      await pump(tester, '/screen', const InvitesScreen(tripId: 't1'));

      await tester.tap(find.text('새 링크'));
      await tester.pumpAndSettle();
      final segmented = tester.widget<SegmentedButton<InviteRole>>(
        find.byType(SegmentedButton<InviteRole>),
      );
      expect(segmented.selected, {InviteRole.viewer});
      expect(find.text('링크를 받은 누구나 일정을 수정할 수 있습니다.'), findsNothing);

      await tester.tap(find.text('편집자').last);
      await tester.pumpAndSettle();
      expect(find.text('링크를 받은 누구나 일정을 수정할 수 있습니다.'), findsOneWidget);
    });

    testWidgets('만들면 링크를 공유 시트로만 내보내고 화면에는 보여주지 않는다', (tester) async {
      final url = '$_base/invite#$_token';
      when(() => api.list('t1')).thenAnswer((_) async => []);
      when(() => api.create('t1', any()))
          .thenAnswer((_) async => CreatedInvite(invite: _invite(), url: url));
      await pump(tester, '/screen', const InvitesScreen(tripId: 't1'));

      await tester.tap(find.text('새 링크'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('만들기'));
      await tester.pumpAndSettle();

      final draft = verify(() => api.create('t1', captureAny())).captured.single as InviteDraft;
      expect(draft.toJson(), {'role': 'viewer', 'max_uses': 10, 'expires_in_days': 3});
      expect(shared, ['Travel Copilot 여행에 초대합니다.\n$url']);
      expect(find.textContaining(_token), findsNothing);
    });

    testWidgets('폐기는 확인 후 요청하고 목록을 다시 받는다', (tester) async {
      when(() => api.list('t1')).thenAnswer((_) async => [_invite()]);
      when(() => api.revoke('t1', 'i1')).thenAnswer((_) async {});
      await pump(tester, '/screen', const InvitesScreen(tripId: 't1'));

      await tester.tap(find.widgetWithText(TextButton, '폐기'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '폐기').last);
      await tester.pumpAndSettle();

      verify(() => api.revoke('t1', 'i1')).called(1);
      verify(() => api.list('t1')).called(2);
    });

    testWidgets('열린 링크 5개면 서버 안내 문구', (tester) async {
      when(() => api.list('t1')).thenAnswer((_) async => []);
      when(() => api.create('t1', any())).thenThrow(
        const ServerException(
          statusCode: 409,
          code: 'invite_limit',
          body: {'detail': '열린 초대 링크는 최대 5개입니다. 쓰지 않는 링크를 폐기해주세요.'},
        ),
      );
      await pump(tester, '/screen', const InvitesScreen(tripId: 't1'));

      await tester.tap(find.text('새 링크'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('만들기'));
      await tester.pumpAndSettle();

      expect(find.textContaining('최대 5개'), findsOneWidget);
      expect(shared, isEmpty);
    });
  });

  group('S16 초대 참여', () {
    testWidgets('미리보기 문구를 보여주고, 참여하면 여행으로 가며 토큰을 버린다', (tester) async {
      container.read(pendingInviteProvider.notifier).set(_token);
      when(() => api.preview(_token)).thenAnswer((_) async => _preview());
      when(() => api.accept(_token)).thenAnswer((_) async => 't9');
      await pump(tester, '/invite', const SizedBox());

      expect(find.textContaining("홍길동님이 '파리 여행'"), findsOneWidget);
      expect(find.textContaining('보기 전용 멤버로 초대했습니다'), findsOneWidget);
      expect(find.textContaining(_token), findsNothing);

      await tester.tap(find.text('참여'));
      await tester.pumpAndSettle();

      expect(find.text('상세 t9'), findsOneWidget);
      expect(container.read(pendingInviteProvider), isNull);
    });

    testWidgets('초대한 사람이 없으면(탈퇴) 이름 없는 문구', (tester) async {
      container.read(pendingInviteProvider.notifier).set(_token);
      when(() => api.preview(_token)).thenAnswer((_) async => _preview(inviter: null));
      await pump(tester, '/invite', const SizedBox());

      expect(find.textContaining("'파리 여행'"), findsOneWidget);
      expect(find.textContaining('초대받았습니다'), findsOneWidget);
    });

    testWidgets('이미 멤버면 확인 없이 바로 여행으로', (tester) async {
      container.read(pendingInviteProvider.notifier).set(_token);
      when(() => api.preview(_token)).thenAnswer((_) async => _preview(member: true));
      await pump(tester, '/invite', const SizedBox());

      expect(find.text('상세 t1'), findsOneWidget);
      verifyNever(() => api.accept(any()));
      expect(container.read(pendingInviteProvider), isNull);
    });

    testWidgets('끝난 링크(410)면 안내하고 토큰을 버린다', (tester) async {
      container.read(pendingInviteProvider.notifier).set(_token);
      when(() => api.preview(_token))
          .thenThrow(const ServerException(statusCode: 410, code: 'invite_revoked'));
      await pump(tester, '/invite', const SizedBox());

      expect(find.text('더 이상 쓸 수 없는 초대 링크입니다. 초대한 사람에게 새 링크를 요청하세요.'), findsOneWidget);
      expect(container.read(pendingInviteProvider), isNull);
    });

    testWidgets('참여 중 소진되면(410) 안내', (tester) async {
      container.read(pendingInviteProvider.notifier).set(_token);
      when(() => api.preview(_token)).thenAnswer((_) async => _preview());
      when(() => api.accept(_token))
          .thenThrow(const ServerException(statusCode: 410, code: 'invite_exhausted'));
      await pump(tester, '/invite', const SizedBox());

      await tester.tap(find.text('참여'));
      await tester.pumpAndSettle();

      expect(find.textContaining('더 이상 쓸 수 없는 초대 링크'), findsOneWidget);
    });

    testWidgets('네트워크 오류면 토큰을 남겨 다시 시도할 수 있다', (tester) async {
      container.read(pendingInviteProvider.notifier).set(_token);
      var calls = 0;
      when(() => api.preview(_token)).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw const NetworkException();
        return _preview();
      });
      await pump(tester, '/invite', const SizedBox());

      expect(find.text('연결을 확인하고 다시 시도해주세요.'), findsOneWidget);
      expect(container.read(pendingInviteProvider), _token);
      await tester.tap(find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('참여'), findsOneWidget);
    });

    testWidgets('취소하면 토큰을 버리고 목록으로', (tester) async {
      container.read(pendingInviteProvider.notifier).set(_token);
      when(() => api.preview(_token)).thenAnswer((_) async => _preview());
      await pump(tester, '/invite', const SizedBox());

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.text('목록 화면'), findsOneWidget);
      expect(container.read(pendingInviteProvider), isNull);
      verifyNever(() => api.accept(any()));
    });
  });

  group('초대 링크 붙여넣기', () {
    testWidgets('다른 사이트 링크는 거절, 맞는 링크면 참여 화면으로', (tester) async {
      when(() => api.preview(_token)).thenAnswer((_) async => _preview());
      await pump(tester, '/trips', const SizedBox());

      await tester.tap(find.text('붙여넣기'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('invite-link-field')),
        'https://evil.example.com/invite#$_token',
      );
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();
      expect(find.text('초대 링크 형식이 아닙니다.'), findsOneWidget);
      expect(container.read(pendingInviteProvider), isNull);

      await tester.enterText(find.byKey(const Key('invite-link-field')), '$_base/invite#$_token');
      await tester.tap(find.text('다음'));
      await tester.pumpAndSettle();

      expect(find.textContaining("'파리 여행'"), findsOneWidget);
      verify(() => api.preview(_token)).called(1);
    });
  });

  test('pendingInvite는 처음에 비어 있다', () {
    expect(container.read(pendingInviteProvider), isNull);
  });
}

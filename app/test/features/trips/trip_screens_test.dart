import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/state/connectivity.dart';
import 'package:travelcopilot/core/state/provider_retry.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';
import 'package:travelcopilot/features/auth/data/auth_repository.dart';
import 'package:travelcopilot/features/auth/state/auth_controller.dart';
import 'package:travelcopilot/features/invites/data/invite_models.dart';
import 'package:travelcopilot/features/invites/data/invites_api.dart';
import 'package:travelcopilot/features/trips/data/trip_cache.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/data/trips_api.dart';
import 'package:travelcopilot/features/trips/ui/trip_detail_screen.dart';
import 'package:travelcopilot/features/trips/ui/trip_form_screen.dart';
import 'package:travelcopilot/features/trips/ui/trip_list_screen.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

import 'trip_fixtures.dart';

class _MockTripsApi extends Mock implements TripsApi;

class _MockAuthRepository extends Mock implements AuthRepository;

class _MockInvitesApi extends Mock implements InvitesApi;

const _me = AppUser(id: 'me', displayName: '나여행');

void main() {
  late _MockTripsApi api;
  late _MockInvitesApi invitesApi;
  late ProviderContainer container;
  late GoRouter router;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(TripDraft.fromTrip(makeTrip()));
  });

  setUp(() {
    api = _MockTripsApi();
    invitesApi = _MockInvitesApi();
    when(() => invitesApi.list(any())).thenAnswer((_) async => []);
    // 목록 갱신 뒤 스냅샷 미리 받기 (features/sync-offline.md 5.6). 테스트마다 필요하면 덮어쓴다
    when(() => api.snapshot(any())).thenThrow(const NetworkException());
    final auth = _MockAuthRepository();
    when(auth.restoreSession).thenAnswer((_) async => _me);
    container = ProviderContainer(
      retry: disableAutoRetry,
      overrides: [
        tripsApiProvider.overrideWithValue(api),
        // 기기 DB 대신 메모리 DB (테스트마다 새로)
        tripCacheProvider.overrideWith((ref) => TripCache.memory()),
        invitesApiProvider.overrideWithValue(invitesApi),
        authRepositoryProvider.overrideWithValue(auth),
      ],
    );
  });

  tearDown(() => container.dispose());

  /// 테스트용 라우터. [screen]을 '/'에서 push한 상태로 시작한다 (pop을 확인하려고).
  Future<void> pump(WidgetTester tester, Widget screen) async {
    router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('바닥 화면')),
        ),
        GoRoute(path: '/screen', builder: (_, _) => screen),
        GoRoute(
          path: '/trips',
          builder: (_, _) => const Scaffold(body: Text('목록 화면')),
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
    // 로그인 상태를 먼저 채운다 (상세 화면이 내 ID를 쓴다)
    await container.read(authControllerProvider.future);
    unawaited(router.push('/screen'));
    await tester.pumpAndSettle();
  }

  group('S03 여행 목록', () {
    testWidgets('다가오는 여행과 지난 여행을 나눠 보여준다', (tester) async {
      when(api.fetchAll).thenAnswer(
        (_) async => [
          makeTrip(id: 'a', title: '다음 여행', start: DateTime(2026, 12), end: DateTime(2026, 12, 3)),
          makeTrip(
            id: 'b',
            title: '작년 여행',
            start: DateTime(2025, 8),
            end: DateTime(2025, 8, 3),
            role: TripRole.viewer,
          ),
        ],
      );

      await pump(tester, TripListScreen(today: DateTime(2026, 11, 8)));

      expect(find.text('다가오는 여행'), findsOneWidget);
      expect(find.text('지난 여행'), findsOneWidget);
      expect(find.text('다음 여행'), findsOneWidget);
      expect(find.text('보기 전용'), findsOneWidget);
      final upcomingY = tester.getTopLeft(find.text('다음 여행')).dy;
      final pastY = tester.getTopLeft(find.text('작년 여행')).dy;
      expect(upcomingY, lessThan(pastY));
    });

    testWidgets('여행이 없으면 안내 문구', (tester) async {
      when(api.fetchAll).thenAnswer((_) async => []);

      await pump(tester, const TripListScreen());

      expect(find.textContaining('첫 여행을 만들어보세요'), findsOneWidget);
      expect(find.text('여행 만들기'), findsOneWidget);
    });
  });

  group('S05 여행 상세 — 역할별 메뉴', () {
    Future<List<String>> menuItems(WidgetTester tester, TripRole role) async {
      when(() => api.snapshot('t1')).thenAnswer(
        (_) async => TripSnapshot(
          trip: makeTrip(role: role),
          members: [
            makeMember('owner', '주인', TripRole.owner),
            makeMember('me', '나여행', role == TripRole.owner ? TripRole.editor : role),
          ],
        ),
      );
      await pump(tester, const TripDetailScreen(tripId: 't1'));
      await tester.tap(find.byKey(const Key('trip-menu')));
      await tester.pumpAndSettle();
      return tester
          .widgetList<PopupMenuItem<Object>>(find.byWidgetPredicate((w) => w is PopupMenuItem))
          .map((item) => (item.child! as Text).data!)
          .toList();
    }

    testWidgets('owner: 수정·삭제', (tester) async {
      expect(await menuItems(tester, TripRole.owner), ['여행 수정', '여행 삭제']);
    });

    testWidgets('editor: 수정·나가기', (tester) async {
      expect(await menuItems(tester, TripRole.editor), ['여행 수정', '여행 나가기']);
    });

    testWidgets('viewer: 나가기만', (tester) async {
      expect(await menuItems(tester, TripRole.viewer), ['여행 나가기']);
    });
  });

  group('S14 멤버 탭', () {
    Future<void> openMembers(WidgetTester tester, TripRole myRole) async {
      when(() => api.snapshot('t1')).thenAnswer(
        (_) async => TripSnapshot(
          trip: makeTrip(role: myRole),
          members: [
            makeMember(myRole == TripRole.owner ? 'me' : 'owner', '주인', TripRole.owner),
            makeMember(myRole == TripRole.owner ? 'friend' : 'me', '친구', TripRole.editor),
          ],
        ),
      );
      await pump(tester, const TripDetailScreen(tripId: 't1'));
      await tester.tap(find.text('멤버'));
      await tester.pumpAndSettle();
    }

    testWidgets('owner는 다른 멤버 관리 메뉴가 있고, 자기 자신에게는 없다', (tester) async {
      await openMembers(tester, TripRole.owner);

      expect(find.byKey(const Key('member-menu-friend')), findsOneWidget);
      expect(find.byKey(const Key('member-menu-me')), findsNothing);
      expect(find.text('주인 (나)'), findsOneWidget);
    });

    testWidgets('editor에게는 관리 메뉴가 없고 나가기 버튼이 있다', (tester) async {
      await openMembers(tester, TripRole.editor);

      expect(
        find.byWidgetPredicate((w) => w is PopupMenuButton && w.key != const Key('trip-menu')),
        findsNothing,
      );
      expect(find.widgetWithText(OutlinedButton, '여행 나가기'), findsOneWidget);
    });

    testWidgets('내보내기는 확인 후 서버에 요청하고 스냅샷을 다시 받는다', (tester) async {
      when(() => api.removeMember('t1', 'friend')).thenAnswer((_) async {});
      await openMembers(tester, TripRole.owner);

      await tester.tap(find.byKey(const Key('member-menu-friend')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('내보내기'));
      await tester.pumpAndSettle();
      expect(find.text('이 멤버가 올린 바우처도 함께 삭제됩니다.'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '내보내기'));
      await tester.pumpAndSettle();

      verify(() => api.removeMember('t1', 'friend')).called(1);
      verify(() => api.snapshot('t1')).called(2);
      // 열린 링크가 없으면 체크박스도, 전체 폐기 요청도 없다
      verifyNever(() => invitesApi.revokeAll(any()));
    });

    Invite openInvite() => Invite(
      id: 'i1',
      role: InviteRole.viewer,
      maxUses: 10,
      useCount: 1,
      expiresAt: DateTime.utc(2030),
      createdAt: DateTime.utc(2026, 11, 15),
      status: InviteStatus.active,
    );

    Future<void> openRemoveDialog(WidgetTester tester) async {
      when(() => api.removeMember('t1', 'friend')).thenAnswer((_) async {});
      when(() => invitesApi.list('t1')).thenAnswer((_) async => [openInvite()]);
      when(() => invitesApi.revokeAll('t1')).thenAnswer((_) async => 1);
      await openMembers(tester, TripRole.owner);
      await tester.tap(find.byKey(const Key('member-menu-friend')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('내보내기'));
      await tester.pumpAndSettle();
    }

    testWidgets('열린 초대 링크가 있으면 "모두 폐기"가 기본 선택되고 함께 폐기한다', (tester) async {
      await openRemoveDialog(tester);

      final checkbox = tester.widget<CheckboxListTile>(
        find.byKey(const Key('revoke-invites-checkbox')),
      );
      expect(checkbox.value, isTrue);
      expect(find.text('열린 초대 링크도 모두 폐기 (1개)'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, '내보내기'));
      await tester.pumpAndSettle();

      verify(() => api.removeMember('t1', 'friend')).called(1);
      verify(() => invitesApi.revokeAll('t1')).called(1);
    });

    testWidgets('"모두 폐기"를 끄면 링크는 그대로 둔다', (tester) async {
      await openRemoveDialog(tester);

      await tester.tap(find.byKey(const Key('revoke-invites-checkbox')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, '내보내기'));
      await tester.pumpAndSettle();

      verify(() => api.removeMember('t1', 'friend')).called(1);
      verifyNever(() => invitesApi.revokeAll(any()));
    });

    testWidgets('owner에게만 초대 링크 버튼이 있다', (tester) async {
      await openMembers(tester, TripRole.owner);
      expect(find.byKey(const Key('open-invites')), findsOneWidget);
    });

    testWidgets('editor에게는 초대 링크 버튼이 없다', (tester) async {
      await openMembers(tester, TripRole.editor);
      expect(find.byKey(const Key('open-invites')), findsNothing);
    });
  });

  testWidgets('여행이 404면 안내하고 목록으로 갈 수 있다', (tester) async {
    when(() => api.snapshot('t1'))
        .thenThrow(const ServerException(statusCode: 404, code: 'not_found'));
    when(api.fetchAll).thenAnswer((_) async => []);

    await pump(tester, const TripDetailScreen(tripId: 't1'));
    expect(find.text('접근할 수 없는 여행입니다.'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '내 여행'));
    await tester.pumpAndSettle();

    expect(find.text('목록 화면'), findsOneWidget);
  });

  group('F6 오프라인 (features/sync-offline.md)', () {
    void goOffline() => container.read(connectivityProvider.notifier).report(reached: false);

    testWidgets('서버에 닿지 못해도 저장된 목록과 마지막 동기화 시각을 보여준다', (tester) async {
      await container.read(tripCacheProvider).replaceTrips([
        makeTrip(title: '저장된 여행', start: DateTime(2026, 12), end: DateTime(2026, 12, 3)),
      ], DateTime.now().subtract(const Duration(hours: 3, minutes: 5)));
      when(api.fetchAll).thenThrow(const NetworkException());
      goOffline();

      await pump(tester, TripListScreen(today: DateTime(2026, 11, 15)));

      expect(find.text('저장된 여행'), findsOneWidget);
      expect(find.byKey(const Key('offline-banner')), findsOneWidget);
      expect(find.text('오프라인 · 마지막 동기화: 3시간 전'), findsOneWidget);
    });

    testWidgets('온라인이면 배너가 없다', (tester) async {
      when(api.fetchAll).thenAnswer((_) async => [makeTrip()]);
      container.read(connectivityProvider.notifier).report(reached: true);

      await pump(tester, TripListScreen(today: DateTime(2026, 11, 15)));

      expect(find.byKey(const Key('offline-banner')), findsNothing);
    });

    testWidgets('오프라인이면 여행 만들기를 막고 안내한다', (tester) async {
      when(api.fetchAll).thenAnswer((_) async => []);
      goOffline();
      await pump(tester, TripListScreen(today: DateTime(2026, 11, 15)));

      await tester.tap(find.text('여행 만들기'));
      await tester.pumpAndSettle();

      expect(find.text('연결 후 수정할 수 있습니다.'), findsOneWidget);
      expect(find.byType(TripFormScreen), findsNothing);
    });

    testWidgets('오프라인이면 여행 상세를 캐시로 보여주고 나가기를 막는다', (tester) async {
      final cache = container.read(tripCacheProvider);
      await cache.saveSnapshot(
        TripSnapshot(
          trip: makeTrip(role: TripRole.editor),
          members: [makeMember('me', '나여행', TripRole.editor)],
        ),
        DateTime.now().subtract(const Duration(minutes: 10)),
      );
      when(() => api.snapshot('t1')).thenThrow(const NetworkException());
      goOffline();

      await pump(tester, const TripDetailScreen(tripId: 't1'));
      expect(find.text('파리 가족여행'), findsOneWidget);
      expect(find.text('오프라인 · 마지막 동기화: 10분 전'), findsOneWidget);

      await tester.tap(find.text('멤버'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(OutlinedButton, '여행 나가기'));
      await tester.pumpAndSettle();

      expect(find.text('연결 후 수정할 수 있습니다.'), findsOneWidget);
      verifyNever(() => api.removeMember(any(), any()));
    });

    testWidgets('캐시로 보던 여행이 404면 안내로 바뀌고 기기 캐시도 지운다 (T08)', (tester) async {
      final cache = container.read(tripCacheProvider);
      await cache.replaceTrips([makeTrip()], DateTime(2026, 11, 14));
      await cache.saveSnapshot(
        TripSnapshot(trip: makeTrip(), members: const []),
        DateTime(2026, 11, 14),
      );
      when(() => api.snapshot('t1'))
          .thenThrow(const ServerException(statusCode: 404, code: 'not_found'));

      await pump(tester, const TripDetailScreen(tripId: 't1'));

      expect(find.text('접근할 수 없는 여행입니다.'), findsOneWidget);
      expect(await cache.readSnapshot('t1'), isNull);
      expect((await cache.readTrips())!.data, isEmpty);
    });
  });

  group('S04 여행 만들기·수정', () {
    testWidgets('빈 폼은 저장하지 않고 항목별 안내를 보여준다', (tester) async {
      await pump(tester, const TripFormScreen());

      await tester.tap(find.widgetWithText(FilledButton, '여행 만들기'));
      await tester.pumpAndSettle();

      expect(find.text('입력해주세요'), findsNWidgets(2));
      expect(find.text('기간을 골라주세요'), findsOneWidget);
      expect(find.text('시간대를 골라주세요'), findsWidgets);
      verifyNever(() => api.create(any()));
    });

    testWidgets('시간대는 검색해서 고른다', (tester) async {
      await pump(
        tester,
        const TripFormScreen(timezoneOptions: ['Asia/Seoul', 'Asia/Tokyo', 'Europe/Paris']),
      );

      await tester.tap(find.byKey(const Key('timezone-field')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'par');
      await tester.pumpAndSettle();
      expect(find.text('Asia/Tokyo'), findsNothing);
      await tester.tap(find.text('Europe/Paris'));
      await tester.pumpAndSettle();

      expect(find.text('Europe/Paris'), findsOneWidget);
    });

    testWidgets('바꾼 필드만 보내고 저장 후 이전 화면으로', (tester) async {
      when(() => api.update('t1', 1, any())).thenAnswer((_) async => makeTrip(version: 2));
      await pump(tester, TripFormScreen(initial: makeTrip()));

      await tester.enterText(find.widgetWithText(TextFormField, '여행 제목'), '  새 제목 ');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      verify(() => api.update('t1', 1, {'title': '새 제목'})).called(1);
      expect(find.text('바닥 화면'), findsOneWidget);
    });

    testWidgets('409면 최신 내용을 보여주고, 다시 적용하면 최신 version으로 보낸다', (tester) async {
      final latest = makeTrip(title: '다른 사람이 바꾼 제목', version: 2);
      when(() => api.update('t1', 1, any())).thenThrow(
        ServerException(
          statusCode: 409,
          code: 'version_conflict',
          body: {'current': latest.toJson()},
        ),
      );
      when(() => api.update('t1', 2, any())).thenAnswer((_) async => makeTrip(version: 3));
      await pump(tester, TripFormScreen(initial: makeTrip()));

      await tester.enterText(find.widgetWithText(TextFormField, '목적지'), '영국 런던');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      expect(find.text('다른 멤버가 먼저 수정했습니다'), findsOneWidget);
      expect(find.textContaining('다른 사람이 바꾼 제목'), findsOneWidget);
      await tester.tap(find.text('내 수정 다시 적용'));
      await tester.pumpAndSettle();

      verify(() => api.update('t1', 2, {'destination': '영국 런던'})).called(1);
      expect(find.text('바닥 화면'), findsOneWidget);
    });

    testWidgets('409에서 취소하면 덮어쓰지 않는다', (tester) async {
      when(() => api.update('t1', 1, any())).thenThrow(
        ServerException(
          statusCode: 409,
          code: 'version_conflict',
          body: {'current': makeTrip(version: 2).toJson()},
        ),
      );
      await pump(tester, TripFormScreen(initial: makeTrip()));

      await tester.enterText(find.widgetWithText(TextFormField, '목적지'), '영국 런던');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      verifyNever(() => api.update('t1', 2, any()));
    });

    testWidgets('네트워크 오류면 저장되지 않았다고 알리고 화면에 남는다', (tester) async {
      when(() => api.update('t1', 1, any())).thenThrow(const NetworkException());
      await pump(tester, TripFormScreen(initial: makeTrip()));

      await tester.enterText(find.widgetWithText(TextFormField, '목적지'), '영국 런던');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      expect(find.textContaining('저장되지 않았습니다'), findsOneWidget);
      expect(find.text('여행 수정'), findsOneWidget);
    });
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travelcopilot/core/state/provider_retry.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_api.dart';
import 'package:travelcopilot/features/itinerary/data/itinerary_models.dart';
import 'package:travelcopilot/features/itinerary/ui/item_form_screen.dart';
import 'package:travelcopilot/features/itinerary/ui/itinerary_tab.dart';
import 'package:travelcopilot/features/places/data/place_models.dart';
import 'package:travelcopilot/features/places/data/places_api.dart';
import 'package:travelcopilot/features/places/ui/place_search_screen.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/data/trips_api.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

import '../trips/trip_fixtures.dart';
import 'itinerary_fixtures.dart';

class _MockItineraryApi extends Mock implements ItineraryApi;

class _MockPlacesApi extends Mock implements PlacesApi;

class _MockTripsApi extends Mock implements TripsApi;

void main() {
  late _MockItineraryApi itinerary;
  late _MockPlacesApi places;
  late _MockTripsApi trips;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(<ItineraryItem>[]);
    registerFallbackValue(ItemDraft(day: DateTime(2026), title: 'x'));
  });

  setUp(() {
    itinerary = _MockItineraryApi();
    places = _MockPlacesApi();
    trips = _MockTripsApi();
    container = ProviderContainer(
      retry: disableAutoRetry,
      overrides: [
        itineraryApiProvider.overrideWithValue(itinerary),
        placesApiProvider.overrideWithValue(places),
        tripsApiProvider.overrideWithValue(trips),
      ],
    );
  });

  tearDown(() => container.dispose());

  TripSnapshot snapshot({TripRole role = TripRole.owner, List<ItineraryItem>? items}) =>
      TripSnapshot(
        trip: makeTrip(role: role),
        members: const [],
        items: items ?? [],
      );

  /// '/'에서 [screen]을 push한 상태로 시작한다 (pop 결과를 확인하려고).
  Future<void> pump(WidgetTester tester, Widget screen) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: Text('바닥 화면')),
        ),
        GoRoute(
          path: '/screen',
          builder: (_, _) => Scaffold(body: screen),
        ),
        GoRoute(path: '/trips/:id/items/:item', builder: (_, s) => Text('항목 ${s.uri}')),
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
    unawaited(router.push('/screen'));
    await tester.pumpAndSettle();
  }

  group('S06 일정 탭', () {
    final items = [
      makeItem(id: 'a', title: '숙소'),
      makeItem(id: 'b', title: '미술관', position: 1, placeId: 'ChIJ_abc'),
      makeItem(id: 'c', title: '다음날', day: DateTime(2026, 12, 22)),
    ];

    testWidgets('고른 날의 항목만 순서대로 보여주고, 날을 바꾸면 바뀐다', (tester) async {
      await pump(
        tester,
        ItineraryTab(
          snapshot: snapshot(items: items),
          today: DateTime(2026, 12, 21),
        ),
      );

      expect(find.text('숙소'), findsOneWidget);
      expect(find.text('미술관'), findsOneWidget);
      expect(find.text('다음날'), findsNothing);
      expect(find.byKey(const Key('place-info-b')), findsOneWidget);

      await tester.tap(find.text('12/22 (화)'));
      await tester.pumpAndSettle();

      expect(find.text('다음날'), findsOneWidget);
      expect(find.text('숙소'), findsNothing);
    });

    testWidgets('viewer에게는 추가·순서 변경이 없다', (tester) async {
      await pump(
        tester,
        ItineraryTab(
          snapshot: snapshot(role: TripRole.viewer, items: items),
          today: DateTime(2026, 12, 21),
        ),
      );

      expect(find.text('일정 추가'), findsNothing);
      expect(find.byType(ReorderableListView), findsNothing);
      expect(find.byType(Dismissible), findsNothing);
    });

    testWidgets('순서를 바꾸면 그날 전체 순서를 서버에 보낸다', (tester) async {
      when(() => itinerary.reorder(any(), any(), any()))
          .thenAnswer((_) async => DayItems(date: DateTime(2026, 12, 21), items: const []));
      when(() => trips.snapshot(any())).thenAnswer((_) async => snapshot(items: items));
      await pump(
        tester,
        ItineraryTab(
          snapshot: snapshot(items: items),
          today: DateTime(2026, 12, 21),
        ),
      );

      final list = tester.widget<ReorderableListView>(find.byType(ReorderableListView));
      list.onReorderItem!(1, 0);
      await tester.pumpAndSettle();

      final sent =
          verify(() => itinerary.reorder('t1', DateTime(2026, 12, 21), captureAny()))
                  .captured
                  .single
              as List<ItineraryItem>;
      expect(sent.map((i) => i.id), ['b', 'a']);
    });
  });

  group('S09 일정 추가·수정', () {
    testWidgets('제목이 비면 저장하지 않는다', (tester) async {
      await pump(tester, ItemFormScreen(snapshot: snapshot(), day: DateTime(2026, 12, 21)));

      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      expect(find.text('입력해주세요'), findsOneWidget);
      verifyNever(() => itinerary.create(any(), any()));
    });

    testWidgets('추가는 입력값을 그대로 보낸다', (tester) async {
      when(() => itinerary.create(any(), any())).thenAnswer((_) async => makeItem());
      await pump(tester, ItemFormScreen(snapshot: snapshot(), day: DateTime(2026, 12, 22)));

      await tester.enterText(find.widgetWithText(TextFormField, '제목'), '  루브르 ');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      final draft = verify(() => itinerary.create('t1', captureAny())).captured.single as ItemDraft;
      expect(draft.title, '루브르');
      expect(draft.day, DateTime(2026, 12, 22));
      expect(find.text('바닥 화면'), findsOneWidget);
    });

    testWidgets('수정은 바뀐 필드만 보내고, 지운 메모는 null로 보낸다', (tester) async {
      when(() => itinerary.update(any(), any(), any(), any())).thenAnswer((_) async => makeItem());
      await pump(
        tester,
        ItemFormScreen(
          snapshot: snapshot(),
          initial: makeItem(memo: '지울 메모'),
        ),
      );

      await tester.enterText(find.widgetWithText(TextFormField, '메모'), '');
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      verify(() => itinerary.update('t1', 'i1', 1, {'memo': null})).called(1);
    });

    testWidgets('viewer에게는 저장 버튼이 없다', (tester) async {
      await pump(
        tester,
        ItemFormScreen(
          snapshot: snapshot(role: TripRole.viewer),
          initial: makeItem(),
        ),
      );

      expect(find.text('일정'), findsWidgets);
      expect(find.widgetWithText(FilledButton, '저장'), findsNothing);
    });

    testWidgets('장소를 고르면 Google 이름 힌트가 나오고, 누르면 제목에 채운다', (tester) async {
      when(
        () => places.autocomplete(
          any(),
          sessionToken: any(named: 'sessionToken'),
          bias: any(named: 'bias'),
        ),
      ).thenAnswer((_) async => const [PlaceSuggestion(placeId: 'ChIJ_abc', name: '오르세 미술관')]);
      when(() => places.details('ChIJ_abc', sessionToken: any(named: 'sessionToken'))).thenAnswer(
        (_) async => const PlaceInfo(
          placeId: 'ChIJ_abc',
          location: LatLng(lat: 48.86, lng: 2.33),
          mapsUrl: 'https://www.google.com/maps/search/?api=1',
          attribution: 'Google Maps',
          address: '파리',
        ),
      );
      when(() => itinerary.create(any(), any())).thenAnswer((_) async => makeItem());
      await pump(tester, ItemFormScreen(snapshot: snapshot(), day: DateTime(2026, 12, 21)));

      await tester.tap(find.byKey(const Key('place-field')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('place-search-field')), '오르세');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.tap(find.text('오르세 미술관'));
      await tester.pumpAndSettle();

      expect(find.text('Google 장소 이름: 오르세 미술관'), findsOneWidget);
      await tester.tap(find.text('이 이름 사용'));
      await tester.tap(find.widgetWithText(FilledButton, '저장'));
      await tester.pumpAndSettle();

      final draft = verify(() => itinerary.create('t1', captureAny())).captured.single as ItemDraft;
      expect(draft.title, '오르세 미술관');
      expect(draft.placeId, 'ChIJ_abc');
    });
  });

  group('S08 장소 검색', () {
    testWidgets('2글자 미만은 묻지 않고, 빠르게 입력하면 마지막 한 번만 묻는다', (tester) async {
      when(
        () => places.autocomplete(
          any(),
          sessionToken: any(named: 'sessionToken'),
          bias: any(named: 'bias'),
        ),
      ).thenAnswer((_) async => const []);
      await pump(tester, const PlaceSearchScreen());
      final field = find.byKey(const Key('place-search-field'));

      await tester.enterText(field, '파');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(field, '파리');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, '파리 에');
      await tester.pump(const Duration(milliseconds: 100));
      await tester.enterText(field, '파리 에펠');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      final calls = verify(
        () => places.autocomplete(
          captureAny(),
          sessionToken: any(named: 'sessionToken'),
          bias: any(named: 'bias'),
        ),
      ).captured;
      expect(calls, ['파리 에펠']);
    });

    testWidgets('자동완성과 장소 상세에 같은 세션 토큰을 쓴다', (tester) async {
      when(
        () => places.autocomplete(
          any(),
          sessionToken: any(named: 'sessionToken'),
          bias: any(named: 'bias'),
        ),
      ).thenAnswer((_) async => const [PlaceSuggestion(placeId: 'ChIJ_abc', name: '오르세 미술관')]);
      when(() => places.details(any(), sessionToken: any(named: 'sessionToken'))).thenAnswer(
        (_) async => const PlaceInfo(
          placeId: 'ChIJ_abc',
          location: LatLng(lat: 1, lng: 2),
          mapsUrl: 'https://www.google.com/maps/search/?api=1',
          attribution: 'Google Maps',
        ),
      );
      await pump(tester, const PlaceSearchScreen());

      await tester.enterText(find.byKey(const Key('place-search-field')), '오르세');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(find.text('Google Maps'), findsOneWidget);
      await tester.tap(find.text('오르세 미술관'));
      await tester.pumpAndSettle();

      final acToken = verify(
        () => places.autocomplete(
          any(),
          sessionToken: captureAny(named: 'sessionToken'),
          bias: any(named: 'bias'),
        ),
      ).captured.single;
      final detailToken = verify(
        () => places.details('ChIJ_abc', sessionToken: captureAny(named: 'sessionToken')),
      ).captured.single;
      expect(acToken, isNotNull);
      expect(detailToken, acToken);
    });
  });
}

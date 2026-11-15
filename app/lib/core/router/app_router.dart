import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';
import 'package:travelcopilot/features/auth/state/auth_controller.dart';
import 'package:travelcopilot/features/auth/ui/login_screen.dart';
import 'package:travelcopilot/features/auth/ui/splash_screen.dart';
import 'package:travelcopilot/features/invites/state/invite_providers.dart';
import 'package:travelcopilot/features/invites/ui/invite_join_screen.dart';
import 'package:travelcopilot/features/invites/ui/invites_screen.dart';
import 'package:travelcopilot/features/itinerary/ui/item_form_screen.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';
import 'package:travelcopilot/features/trips/ui/trip_detail_screen.dart';
import 'package:travelcopilot/features/trips/ui/trip_form_screen.dart';
import 'package:travelcopilot/features/trips/ui/trip_list_screen.dart';

part 'app_router.g.dart';

abstract final class Routes {
  static const splash = '/';
  static const login = '/login';
  static const trips = '/trips';
  static const newTrip = '/trips/new';
  static String trip(String id) => '/trips/$id';
  static String editTrip(String id) => '/trips/$id/edit';
  static String newItem(String tripId, DateTime day) =>
      '/trips/$tripId/items/new?day=${formatDateOnly(day)}';
  static String item(String tripId, String itemId) => '/trips/$tripId/items/$itemId';
  static String invites(String tripId) => '/trips/$tripId/invites';

  /// 초대 참여 (S16). 토큰은 경로에 넣지 않는다 — 메모리 provider에만 둔다.
  static const invite = '/invite';
}

/// 로그인 상태에 따라 화면을 정한다.
///
/// 확인 중 → 시작 화면, 로그인 안 됨 → 로그인 화면, 로그인됨 → 여행 목록.
/// 처리 중인 초대가 있으면([hasPendingInvite]) 로그인 뒤 여행 목록 대신 참여 화면으로 간다.
@visibleForTesting
String? redirectFor(AsyncValue<AppUser?> auth, String location, {bool hasPendingInvite = false}) {
  if (auth.isLoading && !auth.hasValue) {
    return location == Routes.splash ? null : Routes.splash;
  }
  final user = auth.value;
  if (user == null) {
    return location == Routes.login ? null : Routes.login;
  }
  if (location == Routes.splash || location == Routes.login) {
    return hasPendingInvite ? Routes.invite : Routes.trips;
  }
  return null;
}

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // 로그인 상태가 바뀔 때마다 라우터가 redirect를 다시 계산하게 한다
  final authChanges = ValueNotifier<int>(0);
  ref.listen(authControllerProvider, (_, _) => authChanges.value++);

  final router = GoRouter(
    refreshListenable: authChanges,
    redirect: (context, state) => redirectFor(
      ref.read(authControllerProvider),
      state.matchedLocation,
      hasPendingInvite: ref.read(pendingInviteProvider) != null,
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (context, state) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: Routes.invite, builder: (context, state) => const InviteJoinScreen()),
      GoRoute(
        path: Routes.trips,
        builder: (context, state) => const TripListScreen(),
        routes: [
          // 'new'가 ':tripId'보다 먼저 와야 여행 ID로 잘못 해석되지 않는다
          GoRoute(path: 'new', builder: (context, state) => const TripFormScreen()),
          GoRoute(
            path: ':tripId',
            builder: (context, state) => TripDetailScreen(tripId: state.pathParameters['tripId']!),
            routes: [
              GoRoute(
                path: 'invites',
                builder: (context, state) => InvitesScreen(tripId: state.pathParameters['tripId']!),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) =>
                    TripEditScreen(tripId: state.pathParameters['tripId']!),
              ),
              // 'items/new'가 'items/:itemId'보다 먼저 와야 한다
              GoRoute(
                path: 'items/new',
                builder: (context, state) => ItemFormRoute(
                  tripId: state.pathParameters['tripId']!,
                  day: DateTime.tryParse(state.uri.queryParameters['day'] ?? ''),
                ),
              ),
              GoRoute(
                path: 'items/:itemId',
                builder: (context, state) => ItemFormRoute(
                  tripId: state.pathParameters['tripId']!,
                  itemId: state.pathParameters['itemId'],
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(() {
    router.dispose();
    authChanges.dispose();
  });
  return router;
}

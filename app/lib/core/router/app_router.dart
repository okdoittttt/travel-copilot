import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/features/health/ui/health_screen.dart';

part 'app_router.g.dart';

/// 앱 라우터. F1에서 시작·로그인 화면으로 바꾼다.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final router = GoRouter(
    routes: [GoRoute(path: '/', builder: (context, state) => const HealthScreen())],
  );
  ref.onDispose(router.dispose);
  return router;
}

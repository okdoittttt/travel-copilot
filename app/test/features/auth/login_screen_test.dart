import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/state/provider_retry.dart';
import 'package:travelcopilot/features/auth/data/auth_models.dart';
import 'package:travelcopilot/features/auth/data/auth_repository.dart';
import 'package:travelcopilot/features/auth/state/auth_controller.dart';
import 'package:travelcopilot/features/auth/ui/login_screen.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

class _MockRepository extends Mock implements AuthRepository;

void main() {
  late _MockRepository repository;
  late ProviderContainer container;

  Widget app() => UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LoginScreen(),
    ),
  );

  setUp(() {
    repository = _MockRepository();
    when(repository.restoreSession).thenAnswer((_) async => null);
    container = ProviderContainer(
      retry: disableAutoRetry,
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() => container.dispose());

  testWidgets('Google 버튼을 누르면 로그인하고 상태가 로그인됨으로 바뀐다', (tester) async {
    when(repository.signInWithGoogle)
        .thenAnswer((_) async => const AppUser(id: 'u1', displayName: '홍길동'));
    await tester.pumpWidget(app());

    await tester.tap(find.text('Google로 계속하기'));
    await tester.pumpAndSettle();

    expect(container.read(authControllerProvider).value?.displayName, '홍길동');
  });

  testWidgets('로그인에 실패하면 일반 안내 문구를 보여준다', (tester) async {
    when(repository.signInWithGoogle)
        .thenThrow(const ServerException(statusCode: 401, code: 'id_token_invalid'));
    await tester.pumpWidget(app());

    await tester.tap(find.text('Google로 계속하기'));
    await tester.pumpAndSettle();

    expect(find.text('로그인하지 못했습니다. 다시 시도해주세요.'), findsOneWidget);
    expect(find.textContaining('id_token_invalid'), findsNothing);
  });

  testWidgets('사용자가 취소하면 아무 메시지도 없다', (tester) async {
    when(repository.signInWithGoogle).thenAnswer((_) async => null);
    await tester.pumpWidget(app());

    await tester.tap(find.text('Google로 계속하기'));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    expect(container.read(authControllerProvider).value, isNull);
  });
}

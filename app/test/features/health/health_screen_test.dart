import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/core/state/provider_retry.dart';
import 'package:travelcopilot/features/health/data/health.dart';
import 'package:travelcopilot/features/health/state/health_provider.dart';
import 'package:travelcopilot/features/health/ui/health_screen.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

Widget _wrap(Future<Health> Function() load) {
  return ProviderScope(
    retry: disableAutoRetry,
    overrides: [healthProvider.overrideWith((ref) => load())],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: HealthScreen(),
    ),
  );
}

void main() {
  testWidgets('서버가 정상이면 "정상"을 보여준다', (tester) async {
    await tester.pumpWidget(_wrap(() async => const Health(status: 'ok')));
    await tester.pumpAndSettle();

    expect(find.text('정상'), findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });

  testWidgets('연결에 실패하면 "연결 실패"와 다시 시도 버튼을 보여준다', (tester) async {
    await tester.pumpWidget(_wrap(() async => throw const NetworkException()));
    await tester.pumpAndSettle();

    expect(find.text('연결 실패'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
  });
}

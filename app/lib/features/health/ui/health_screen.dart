import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travelcopilot/features/health/state/health_provider.dart';
import 'package:travelcopilot/l10n/gen/app_localizations.dart';

/// 개발 확인용 첫 화면. 서버 연결 상태를 보여준다. F1에서 시작 화면으로 바꾼다.
class HealthScreen extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final health = ref.watch(healthProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.healthTitle)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(switch (health) {
              AsyncData() => l10n.healthOk,
              AsyncError() => l10n.healthFailed,
              _ => l10n.healthChecking,
            }, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            if (health is AsyncError)
              FilledButton(
                onPressed: () => ref.invalidate(healthProvider),
                child: Text(l10n.retry),
              ),
          ],
        ),
      ),
    );
  }
}

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/api/api_client.dart';
import 'package:travelcopilot/features/health/data/health.dart';
import 'package:travelcopilot/features/health/data/health_repository.dart';

part 'health_provider.g.dart';

@riverpod
HealthRepository healthRepository(Ref ref) => HealthRepository(ref.watch(apiClientProvider));

@riverpod
Future<Health> health(Ref ref) => ref.watch(healthRepositoryProvider).check();

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travelcopilot/app.dart';
import 'package:travelcopilot/core/config/app_config.dart';
import 'package:travelcopilot/core/logging/app_logger.dart';
import 'package:travelcopilot/core/state/provider_retry.dart';

void main() {
  setupLogging();
  AppConfig.validate();
  runApp(const ProviderScope(retry: disableAutoRetry, child: App()));
}

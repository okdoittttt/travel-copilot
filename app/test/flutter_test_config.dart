import 'dart:async';

import 'package:drift/drift.dart';

/// 모든 테스트 공통 설정.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  // 테스트마다 메모리 캐시 DB를 새로 만든다 (같은 DB 클래스를 여러 번 여는 것이 의도된 동작)
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  await testMain();
}

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// 로그 한 건을 내보내는 함수. 테스트에서 바꿔 끼울 수 있게 분리했다.
typedef LogSink = void Function(LogRecord record);

/// 앱 전체 로거를 설정한다.
///
/// 릴리스 빌드에서는 WARNING 이상만 받고 콘솔에 출력하지 않는다 (T21).
/// 디버그 빌드에서도 토큰·개인정보는 로그에 넘기지 않는다 — 호출하는 쪽의 책임이다.
void setupLogging({bool isRelease = kReleaseMode, LogSink? sink}) {
  Logger.root.clearListeners();
  Logger.root.level = isRelease ? Level.WARNING : Level.ALL;
  final output = sink ?? (isRelease ? _discard : _toDeveloperLog);
  Logger.root.onRecord.listen(output);
}

void _discard(LogRecord record) {}

void _toDeveloperLog(LogRecord record) {
  developer.log(
    record.message,
    time: record.time,
    level: record.level.value,
    name: record.loggerName,
    error: record.error,
    stackTrace: record.stackTrace,
  );
}

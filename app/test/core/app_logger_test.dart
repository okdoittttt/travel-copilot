import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:travelcopilot/core/logging/app_logger.dart';

void main() {
  final log = Logger('test');

  tearDown(Logger.root.clearListeners);

  test('릴리스 빌드에서는 WARNING 미만 로그를 받지 않는다', () {
    final records = <LogRecord>[];
    setupLogging(isRelease: true, sink: records.add);

    log
      ..fine('디버그 정보')
      ..info('일반 정보')
      ..warning('경고');

    expect(records.map((r) => r.message), ['경고']);
  });

  test('디버그 빌드에서는 모든 레벨을 받는다', () {
    final records = <LogRecord>[];
    setupLogging(sink: records.add);

    log
      ..fine('디버그 정보')
      ..warning('경고');

    expect(records, hasLength(2));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T19: 여행 캐시 DB가 기기 백업(iCloud·Google)에 들어가지 않는다 (features/sync-offline.md 5.8).
void main() {
  test('Android: 자동 백업을 끄고, 12 이상의 백업·기기 이전 규칙도 모두 제외', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(manifest, contains('android:dataExtractionRules="@xml/data_extraction_rules"'));

    final rules = File('android/app/src/main/res/xml/data_extraction_rules.xml').readAsStringSync();
    for (final section in ['cloud-backup', 'device-transfer']) {
      final body = RegExp('<$section>(.*?)</$section>', dotAll: true).firstMatch(rules)!.group(1)!;
      for (final domain in ['root', 'file', 'database', 'sharedpref', 'external']) {
        expect(body, contains('<exclude domain="$domain" path="."/>'), reason: '$section/$domain');
      }
      expect(body, isNot(contains('<include')));
    }
  });

  test('iOS: 캐시 폴더에 백업 제외 속성을 다는 채널이 있다', () {
    final delegate = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(delegate, contains('"travelcopilot/storage"'));
    expect(delegate, contains('isExcludedFromBackup = true'));
  });

  test('캐시 DB는 Documents가 아니라 앱 지원 폴더에 둔다', () {
    final source = File('lib/features/trips/data/trip_cache.dart').readAsStringSync();
    expect(source, contains('getApplicationSupportDirectory()'));
    expect(source, isNot(contains('getApplicationDocumentsDirectory')));
    // drift_flutter 기본값(Documents)을 쓰지 않도록 경로를 직접 준다
    expect(source, contains('databasePath:'));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// T13: 초대 링크는 Universal Links / App Links만 쓰고 커스텀 스킴을 등록하지 않는다.
/// Flutter 기본 딥링크 처리는 끈다 (토큰이 라우터로 넘어가지 않게, features/invites.md 5.7).
void main() {
  test('iOS: 기본 딥링크 처리를 끄고, URL 스킴은 Google 로그인용 하나뿐', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();

    expect(RegExp(r'<key>FlutterDeepLinkingEnabled</key>\s*<false/>').hasMatch(plist), isTrue);
    final schemes = RegExp(
      r'<key>CFBundleURLSchemes</key>\s*<array>(.*?)</array>',
      dotAll: true,
    ).allMatches(plist).expand((m) => RegExp('<string>(.*?)</string>').allMatches(m.group(1)!));
    expect(
      schemes.map((m) => m.group(1)).toList(),
      everyElement(startsWith('com.googleusercontent.apps.')),
    );
  });

  test('Android: 기본 딥링크 처리를 끄고, 링크는 https App Link만', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();

    expect(
      RegExp(r'android:name="flutter_deeplinking_enabled"\s+android:value="false"')
          .hasMatch(manifest),
      isTrue,
    );
    final schemes = RegExp('android:scheme="([^"]+)"')
        .allMatches(manifest)
        .map((m) => m.group(1))
        .toSet();
    expect(schemes, {'https'});
    expect(manifest, contains('android:autoVerify="true"'));
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:travelcopilot/features/invites/data/invite_link.dart';

const _base = 'https://travel.example.com';
final String _token = '${'A' * 40}b-_';

void main() {
  group('parseInviteToken (features/invites.md 5.7, T13)', () {
    test('정상 링크에서 fragment 토큰을 꺼낸다', () {
      expect(parseInviteToken('$_base/invite#$_token', baseUrl: _base), _token);
    });

    test('메신저에서 복사할 때 섞인 앞뒤 공백·줄바꿈은 무시한다', () {
      expect(parseInviteToken('  $_base/invite#$_token\n', baseUrl: _base), _token);
    });

    test('호스트가 다르면 거절 (다른 사이트 링크·피싱)', () {
      for (final link in [
        'https://evil.example.com/invite#$_token',
        'https://travel.example.com.evil.com/invite#$_token',
        'https://travel.example.com:8443/invite#$_token',
      ]) {
        expect(parseInviteToken(link, baseUrl: _base), isNull, reason: link);
      }
    });

    test('https가 아니거나 커스텀 스킴이면 거절', () {
      expect(parseInviteToken('http://travel.example.com/invite#$_token', baseUrl: _base), isNull);
      expect(parseInviteToken('travelcopilot://invite#$_token', baseUrl: _base), isNull);
    });

    test('경로가 다르거나 쿼리가 있으면 거절', () {
      expect(parseInviteToken('$_base/other#$_token', baseUrl: _base), isNull);
      expect(parseInviteToken('$_base/invite?x=1#$_token', baseUrl: _base), isNull);
      // 토큰을 쿼리로 보내는 형식은 받지 않는다 (서버 로그에 남는 형식)
      expect(parseInviteToken('$_base/invite?token=$_token', baseUrl: _base), isNull);
    });

    test('토큰 형식(43자 URL-safe)이 아니면 거절', () {
      for (final token in ['', 'short', 'A' * 42, 'A' * 44, '${'A' * 42}=', '${'A' * 42}/']) {
        expect(parseInviteToken('$_base/invite#$token', baseUrl: _base), isNull, reason: token);
      }
    });

    test('기본 주소가 비어 있으면 아무 링크도 받지 않는다', () {
      expect(parseInviteToken('$_base/invite#$_token', baseUrl: ''), isNull);
    });
  });
}

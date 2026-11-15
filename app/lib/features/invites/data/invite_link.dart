/// 초대 링크 해석 (features/invites.md 5.7).
///
/// 링크 형식: `https://<도메인>/invite#<토큰>`. 토큰은 fragment에 있다.
library;

final _tokenPattern = RegExp(r'^[A-Za-z0-9_-]{43}$');

/// [input]에서 초대 토큰을 꺼낸다. 아니면 null.
///
/// - https이고 호스트·포트가 [baseUrl]과 같아야 한다 (다른 사이트 링크·피싱 방지)
/// - 경로는 `/invite`, 토큰은 `#` 뒤 43자 URL-safe 문자
/// - 붙여넣은 문자열 앞뒤 공백·줄바꿈은 무시한다 (메신저 복사 시 섞여 들어옴)
String? parseInviteToken(String input, {required String baseUrl}) {
  final uri = Uri.tryParse(input.trim());
  final base = Uri.tryParse(baseUrl);
  if (uri == null || base == null) return null;
  if (uri.scheme != 'https' || uri.host.isEmpty) return null;
  if (uri.host.toLowerCase() != base.host.toLowerCase() || uri.port != base.port) return null;
  if (uri.path != '/invite' || uri.hasQuery) return null;
  final token = uri.fragment;
  return _tokenPattern.hasMatch(token) ? token : null;
}

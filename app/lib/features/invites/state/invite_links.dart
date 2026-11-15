import 'package:app_links/app_links.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/router/app_router.dart';
import 'package:travelcopilot/features/invites/data/invite_link.dart';
import 'package:travelcopilot/features/invites/state/invite_providers.dart';

part 'invite_links.g.dart';

/// Universal Link / App Link로 들어온 주소 (features/invites.md 5.7).
///
/// Flutter 기본 딥링크 처리는 꺼 두었다 (iOS `FlutterDeepLinkingEnabled`, Android
/// `flutter_deeplinking_enabled`). 기본 처리는 URL을 라우터 경로로 넘겨서 토큰이 라우터
/// 상태·로그에 들어갈 수 있기 때문이다. 테스트에서 바꿔 끼우려고 provider로 둔다.
@Riverpod(keepAlive: true)
Stream<Uri> incomingLinks(Ref ref) => AppLinks().uriLinkStream;

/// 들어온 링크를 처리한다. 초대 링크면 토큰을 메모리에 두고 참여 화면으로 보낸다.
///
/// 초대 링크가 아니면 아무것도 하지 않는다. 어느 경우에도 URL을 로그에 남기지 않는다.
void handleIncomingLink(Ref ref, Uri uri) {
  final token = parseInviteToken(uri.toString(), baseUrl: ref.read(inviteBaseUrlProvider));
  if (token == null) return;
  ref.read(pendingInviteProvider.notifier).set(token);
  // 로그인이 안 돼 있으면 redirect가 로그인으로 보내고, 로그인 뒤 다시 참여 화면으로 온다
  ref.read(appRouterProvider).go(Routes.invite);
}

/// 앱이 떠 있는 동안 링크를 듣는다. 앱 루트에서 한 번 watch한다.
@Riverpod(keepAlive: true)
void inviteLinkListener(Ref ref) {
  ref.listen(incomingLinksProvider, (_, next) {
    final uri = next.value;
    if (uri != null) handleIncomingLink(ref, uri);
  });
}

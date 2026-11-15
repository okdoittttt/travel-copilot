import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:travelcopilot/core/config/app_config.dart';
import 'package:travelcopilot/features/invites/data/invite_models.dart';
import 'package:travelcopilot/features/invites/data/invites_api.dart';

part 'invite_providers.g.dart';

/// 여행의 초대 링크 목록 (S15). 화면이 열려 있는 동안만 유지.
@riverpod
Future<List<Invite>> invites(Ref ref, String tripId) => ref.watch(invitesApiProvider).list(tripId);

/// 처리 중인 초대 토큰. **메모리에만** 둔다 (features/invites.md 5.7).
///
/// 라우터 경로·디스크·로그에 넣지 않는다. 참여·취소·실패하면 [clear]로 바로 버린다.
@Riverpod(keepAlive: true)
class PendingInvite extends _$PendingInvite {
  @override
  String? build() => null;

  // 토큰을 넣는다는 동작을 이름으로 드러내려고 setter 대신 메서드로 둔다
  // ignore: use_setters_to_change_properties
  void set(String token) => state = token;

  void clear() => state = null;
}

/// 링크 공유 (OS 공유 시트). 테스트에서 바꿔 끼우려고 provider로 둔다.
typedef ShareText = Future<void> Function(String text);

@Riverpod(keepAlive: true)
ShareText shareText(Ref ref) => (text) async {
  await SharePlus.instance.share(ShareParams(text: text));
};

/// 초대 링크 기본 주소. 테스트에서 바꿔 끼우려고 provider로 둔다.
@Riverpod(keepAlive: true)
String inviteBaseUrl(Ref ref) => AppConfig.inviteBaseUrl;

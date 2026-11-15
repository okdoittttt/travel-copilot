import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:travelcopilot/features/trips/data/trip_models.dart';

part 'invite_models.freezed.dart';
part 'invite_models.g.dart';

/// 초대로 받을 수 있는 역할. owner는 없다 (소유권 넘기기로만).
enum InviteRole {
  editor,
  viewer;

  TripRole get tripRole => this == editor ? TripRole.editor : TripRole.viewer;
}

/// 링크 상태. 서버가 계산한다.
enum InviteStatus { active, expired, revoked, exhausted }

/// 초대 링크 목록 항목. 토큰은 없다 (features/invites.md 6절).
@freezed
abstract class Invite with _$Invite {
  const factory({
    required String id,
    required InviteRole role,
    required int maxUses,
    required int useCount,
    required DateTime expiresAt,
    required DateTime createdAt,
    required InviteStatus status,
    DateTime? revokedAt,
    String? createdByName,
  }) = _Invite;

  factory fromJson(Map<String, dynamic> json) => _$InviteFromJson(json);
}

/// 만들기 결과. [url]에 토큰이 들어 있고, 이 응답에서만 받을 수 있다.
class CreatedInvite {
  const new({required this.invite, required this.url});

  factory fromJson(Map<String, dynamic> json) =>
      CreatedInvite(invite: Invite.fromJson(json), url: json['url'] as String);

  final Invite invite;
  final String url;
}

/// 링크 만들기 옵션.
class InviteDraft {
  const new({this.role = InviteRole.viewer, this.maxUses = 10, this.expiresInDays = 3});

  final InviteRole role;
  final int maxUses;
  final int expiresInDays;

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'max_uses': maxUses,
    'expires_in_days': expiresInDays,
  };
}

/// 참여 확인 화면용 정보 (features/invites.md 5.4).
@freezed
abstract class InvitePreview with _$InvitePreview {
  const factory({
    required String tripTitle,
    @DateOnlyConverter() required DateTime startDate,
    @DateOnlyConverter() required DateTime endDate,
    required InviteRole role,
    required bool alreadyMember,
    String? inviterName,
    String? tripId,
  }) = _InvitePreview;

  factory fromJson(Map<String, dynamic> json) => _$InvitePreviewFromJson(json);
}

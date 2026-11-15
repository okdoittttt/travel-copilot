import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:travelcopilot/core/api/api_client.dart';
import 'package:travelcopilot/core/api/app_exception.dart';
import 'package:travelcopilot/features/invites/data/invite_models.dart';

part 'invites_api.g.dart';

/// 초대 서버 API 호출. 실패는 모두 [AppException]으로 바꿔서 던진다.
///
/// 토큰은 요청 본문으로만 보낸다 (쿼리 문자열 금지, features/invites.md 5.2).
class InvitesApi {
  new(this._dio);

  final Dio _dio;

  Future<CreatedInvite> create(String tripId, InviteDraft draft) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/trips/$tripId/invites',
      data: draft.toJson(),
    );
    return CreatedInvite.fromJson(response.data!);
  });

  Future<List<Invite>> list(String tripId) => _call(() async {
    final response = await _dio.get<Map<String, dynamic>>('/trips/$tripId/invites');
    return (response.data!['items'] as List<dynamic>)
        .map((e) => Invite.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  Future<void> revoke(String tripId, String inviteId) => _call(() async {
    await _dio.delete<void>('/trips/$tripId/invites/$inviteId');
  });

  /// 열린 링크를 모두 폐기하고 폐기한 수를 돌려준다.
  Future<int> revokeAll(String tripId) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>('/trips/$tripId/invites/revoke-all');
    return response.data!['revoked'] as int;
  });

  Future<InvitePreview> preview(String token) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/invites/preview',
      data: {'token': token},
    );
    return InvitePreview.fromJson(response.data!);
  });

  /// 참여하고 여행 ID를 돌려준다.
  Future<String> accept(String token) => _call(() async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/invites/accept',
      data: {'token': token},
    );
    return response.data!['trip_id'] as String;
  });

  static Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw AppException.fromDio(error);
    }
  }
}

@Riverpod(keepAlive: true)
InvitesApi invitesApi(Ref ref) => InvitesApi(ref.watch(apiClientProvider));

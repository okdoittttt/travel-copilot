import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity.g.dart';

enum ConnectionStatus { unknown, online, offline }

/// 서버에 닿는지. "네트워크 연결됨"이 아니라 **실제 요청 결과**로 정한다 (features/sync-offline.md 5.4).
///
/// 기내 Wi-Fi처럼 연결은 됐는데 서버에 못 닿는 경우가 많아서 OS의 연결 상태는 믿지 않는다.
@Riverpod(keepAlive: true)
class Connectivity extends _$Connectivity {
  @override
  ConnectionStatus build() => ConnectionStatus.unknown;

  /// 서버가 응답했으면(에러 응답 포함) [reached] = true.
  void report({required bool reached}) {
    final next = reached ? ConnectionStatus.online : ConnectionStatus.offline;
    if (state != next) state = next;
  }
}

/// 모든 API 응답을 보고 [Connectivity]를 바꾼다.
class ConnectivityInterceptor extends Interceptor {
  new(this._report);

  final void Function({required bool reached}) _report;

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _report(reached: true);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // 401·404·500도 서버에 닿은 것이다. 응답이 없을 때만 오프라인
    _report(reached: err.response != null);
    handler.next(err);
  }
}

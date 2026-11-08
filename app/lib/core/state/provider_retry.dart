/// Riverpod의 자동 재시도를 끈다.
///
/// Riverpod 3는 실패한 provider를 조용히 재시도하는데, 그동안 화면은 로딩 상태에
/// 머문다. 이 앱은 에러를 바로 보여주고 다시 시도는 사용자가 고르게 한다 (07-screens 5절).
Duration? disableAutoRetry(int retryCount, Object error) => null;

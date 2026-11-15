import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'maps_config.g.dart';

const _channel = MethodChannel('travelcopilot/config');

/// 앱에 지도 키가 설정됐는지 (iOS AppDelegate가 알려준다).
///
/// 키 없이 지도를 만들면 Google Maps SDK가 앱을 종료시키므로, false면 지도 화면을 막는다.
/// Android는 아직 지도 설정 전이라 false (features/routes-map.md 4절).
@Riverpod(keepAlive: true)
Future<bool> mapsConfigured(Ref ref) async {
  try {
    return await _channel.invokeMethod<bool>('mapsConfigured') ?? false;
  } on MissingPluginException {
    return false;
  } on PlatformException {
    return false;
  }
}

import Flutter
import GoogleMaps
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  /// 지도 키가 설정됐는지. 키 없이 지도를 만들면 Google Maps SDK가 앱을 종료시키므로
  /// Dart 쪽이 이 값을 보고 지도 화면을 막는다 (features/routes-map.md 5.5).
  private static var mapsConfigured = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 키는 Info.plist(GMSApiKey) ← ios/Flutter/Secrets.xcconfig 에서 온다. 코드·git에 키를 두지 않는다
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
      !key.trimmingCharacters(in: .whitespaces).isEmpty
    {
      GMSServices.provideAPIKey(key)
      AppDelegate.mapsConfigured = true
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TravelCopilotConfig") {
      let channel = FlutterMethodChannel(
        name: "travelcopilot/config", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        if call.method == "mapsConfigured" {
          result(AppDelegate.mapsConfigured)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }
    // 여행 캐시 폴더를 iCloud·기기 백업에서 제외한다 (features/sync-offline.md 5.8, T19)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "TravelCopilotStorage") {
      let channel = FlutterMethodChannel(
        name: "travelcopilot/storage", binaryMessenger: registrar.messenger())
      channel.setMethodCallHandler { call, result in
        guard call.method == "excludeFromBackup", let path = call.arguments as? String else {
          result(FlutterMethodNotImplemented)
          return
        }
        var url = URL(fileURLWithPath: path, isDirectory: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        do {
          try url.setResourceValues(values)
          result(nil)
        } catch {
          result(FlutterError(code: "exclude_failed", message: nil, details: nil))
        }
      }
    }
  }
}

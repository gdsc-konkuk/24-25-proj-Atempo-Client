import UIKit
import Flutter
#if canImport(GoogleMaps)
import GoogleMaps
#endif

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // API 키 직접 입력
    #if canImport(GoogleMaps)
    GMSServices.provideAPIKey("AIzaSyDeqCNi-eeLBLPbRNv2TsX2eIzuSSVO_7w")
    #endif
    
    // MethodChannel 설정 - 단순화
    let controller = window?.rootViewController as! FlutterViewController
    let mapsChannel = FlutterMethodChannel(name: "com.medicall/maps", binaryMessenger: controller.binaryMessenger)
    
    mapsChannel.setMethodCallHandler { (call, result) in
      if call.method == "initGoogleMaps" {
        // 항상 성공 반환 (API 키는 이미 설정됨)
        result(true)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

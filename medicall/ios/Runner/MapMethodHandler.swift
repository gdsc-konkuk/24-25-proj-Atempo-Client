import Flutter
import UIKit
import GoogleMaps

class MapMethodHandler: NSObject, FlutterPlugin {
  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "com.medicall/maps", binaryMessenger: registrar.messenger())
    let instance = MapMethodHandler()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }
  
  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "initGoogleMaps" {
      if let args = call.arguments as? [String: Any],
         let apiKey = args["apiKey"] as? String {
        GMSServices.provideAPIKey(apiKey)
        result(true)
      } else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "API key not provided", details: nil))
      }
    } else {
      result(FlutterMethodNotImplemented)
    }
  }
}

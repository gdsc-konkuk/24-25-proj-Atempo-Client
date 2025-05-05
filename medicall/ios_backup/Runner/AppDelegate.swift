import UIKit
import Flutter
#if canImport(GoogleMaps)
import GoogleMaps
#endif
import CoreLocation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  private var locationManager: CLLocationManager?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // API 키 직접 입력
    #if canImport(GoogleMaps)
    GMSServices.provideAPIKey("AIzaSyAw92wiRgypo3fVZ4-R5CbpB4x_Pcj1gwk")
    #endif
    
    // 위치 관리자 초기화 - iOS에서 위치 서비스 제대로 설정
    setupLocationManager()
    
    // MethodChannel 설정
    let controller = window?.rootViewController as! FlutterViewController
    let mapsChannel = FlutterMethodChannel(name: "com.medicall/maps", binaryMessenger: controller.binaryMessenger)
    
    mapsChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      if call.method == "initGoogleMaps" {
        // 항상 성공 반환 (API 키는 이미 설정됨)
        result(true)
      } else if call.method == "requestLocation" {
        // 위치 요청 핸들러 추가
        self.requestLocation(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 위치 관리자 설정
  private func setupLocationManager() {
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    
    // 위치 권한 요청 (사용자에게 최초 한 번만 표시됨)
    locationManager?.requestWhenInUseAuthorization()
    
    // 위치 업데이트 시작
    locationManager?.startUpdatingLocation()
  }
  
  // 위치 요청 메서드
  private func requestLocation(result: @escaping FlutterResult) {
    guard let locationManager = locationManager else {
      result(FlutterError(code: "LOCATION_UNAVAILABLE", 
                        message: "Location manager is not initialized", 
                        details: nil))
      return
    }
    
    // 위치 권한 확인
    let authStatus = CLLocationManager.authorizationStatus()
    if authStatus == .denied || authStatus == .restricted {
      result(FlutterError(code: "LOCATION_PERMISSION_DENIED", 
                        message: "Location permission denied", 
                        details: nil))
      return
    }
    
    // 이미 위치가 있는지 확인
    if let location = locationManager.location {
      // 위치 정보를 Flutter로 반환
      let locationData: [String: Any] = [
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
        "accuracy": location.horizontalAccuracy
      ]
      result(locationData)
    } else {
      // 위치 업데이트 요청
      locationManager.requestLocation()
      // 비동기 요청이므로 일단 null 반환
      result(nil)
    }
  }
  
  // CLLocationManagerDelegate 메서드
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // 위치 업데이트 시 필요한 처리
    print("iOS에서 위치 업데이트: \(locations.last?.coordinate ?? CLLocationCoordinate2D())")
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("iOS 위치 서비스 오류: \(error.localizedDescription)")
  }
}

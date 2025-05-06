import UIKit
import Flutter
#if canImport(GoogleMaps)
import GoogleMaps
#endif
import CoreLocation
import flutter_mapbox_navigation

@main
@objc class AppDelegate: FlutterAppDelegate, CLLocationManagerDelegate {
  private var locationManager: CLLocationManager?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Manually input API key
    #if canImport(GoogleMaps)
    GMSServices.provideAPIKey("AIzaSyAw92wiRgypo3fVZ4-R5CbpB4x_Pcj1gwk")
    #endif
    
    // Mapbox token is set in Info.plist.
    // The flutter_mapbox_navigation plugin automatically uses this value.
    
    // Initialize location manager – properly setup location services in iOS.
    setupLocationManager()
    
    // Setup MethodChannel
    let controller = window?.rootViewController as! FlutterViewController
    let mapsChannel = FlutterMethodChannel(name: "com.medicall/maps", binaryMessenger: controller.binaryMessenger)
    
    mapsChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      
      if call.method == "initGoogleMaps" {
        // Always return success (API key already configured)
        result(true)
      } else if call.method == "requestLocation" {
        // Add location request handler
        self.requestLocation(result: result)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // Setup location manager
  private func setupLocationManager() {
    locationManager = CLLocationManager()
    locationManager?.delegate = self
    locationManager?.desiredAccuracy = kCLLocationAccuracyBest
    
    // Request location permission (displayed only once to the user)
    locationManager?.requestWhenInUseAuthorization()
    
    // Start location updates
    locationManager?.startUpdatingLocation()
  }
  
  // Location request method
  private func requestLocation(result: @escaping FlutterResult) {
    guard let locationManager = locationManager else {
      result(FlutterError(code: "LOCATION_UNAVAILABLE", 
                        message: "Location manager is not initialized", 
                        details: nil))
      return
    }
    
    // Check location permission
    let authStatus = CLLocationManager.authorizationStatus()
    if authStatus == .denied || authStatus == .restricted {
      result(FlutterError(code: "LOCATION_PERMISSION_DENIED", 
                        message: "Location permission denied", 
                        details: nil))
      return
    }
    
    // Check if location already exists
    if let location = locationManager.location {
      // Return location information to Flutter
      let locationData: [String: Any] = [
        "latitude": location.coordinate.latitude,
        "longitude": location.coordinate.longitude,
        "accuracy": location.horizontalAccuracy
      ]
      result(locationData)
    } else {
      // Request location update
      locationManager.requestLocation()
      // Asynchronous request; return nil for now
      result(nil)
    }
  }
  
  // CLLocationManagerDelegate methods
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // Handle actions when location updates occur
    print("Location updated on iOS: \(locations.last?.coordinate ?? CLLocationCoordinate2D())")
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    print("iOS location service error: \(error.localizedDescription)")
  }
}

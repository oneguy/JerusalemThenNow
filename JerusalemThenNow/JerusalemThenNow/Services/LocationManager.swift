import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    private var locationUpdateCompletion: ((CLLocation?) -> Void)?
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        // Check if location services are enabled
        if CLLocationManager.locationServicesEnabled() {
            locationUpdateCompletion = completion
            locationManager.requestLocation()
        } else {
            completion(nil)
        }
    }
    
    func calculateDistance(from: CLLocation, to: CLLocation) -> CLLocationDistance {
        return from.distance(from: to)
    }
    
    func openInGoogleMaps(latitude: Double, longitude: Double) {
        let url = URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)")!
        UIApplication.shared.open(url)
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            locationUpdateCompletion?(location)
            locationUpdateCompletion = nil
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error)")
        locationUpdateCompletion?(nil)
        locationUpdateCompletion = nil
    }
    
    // MARK: - Map Region Helpers
    
    func regionForLocations(_ locations: [Location], currentLocation: CLLocation? = nil) -> MKCoordinateRegion {
        if locations.isEmpty {
            // Default to Jerusalem if no locations
            let jerusalemCoordinate = CLLocationCoordinate2D(latitude: 31.7683, longitude: 35.2137)
            return MKCoordinateRegion(center: jerusalemCoordinate, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        }
        
        var minLat: Double = 90.0
        var maxLat: Double = -90.0
        var minLon: Double = 180.0
        var maxLon: Double = -180.0
        
        // Include current location if available
        if let currentLocation = currentLocation {
            minLat = min(minLat, currentLocation.coordinate.latitude)
            maxLat = max(maxLat, currentLocation.coordinate.latitude)
            minLon = min(minLon, currentLocation.coordinate.longitude)
            maxLon = max(maxLon, currentLocation.coordinate.longitude)
        }
        
        // Include all location points
        for location in locations {
            minLat = min(minLat, location.latitude)
            maxLat = max(maxLat, location.latitude)
            minLon = min(minLon, location.longitude)
            maxLon = max(maxLon, location.longitude)
        }
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(latitudeDelta: (maxLat - minLat) * 1.2, longitudeDelta: (maxLon - minLon) * 1.2)
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    // MARK: - Sorting Helpers
    
    func sortLocationsByDistance(locations: [Location], from currentLocation: CLLocation) -> [Location] {
        return locations.sorted { (loc1, loc2) -> Bool in
            let location1 = CLLocation(latitude: loc1.latitude, longitude: loc1.longitude)
            let location2 = CLLocation(latitude: loc2.latitude, longitude: loc2.longitude)
            
            return currentLocation.distance(from: location1) < currentLocation.distance(from: location2)
        }
    }
}

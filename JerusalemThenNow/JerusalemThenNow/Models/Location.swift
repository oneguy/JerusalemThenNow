import Foundation
import CoreLocation
import UIKit

enum LocationStatus: String, Codable {
    case notVisited // Blue
    case completed // Green
    case inaccessible // Red
    
    var color: UIColor {
        switch self {
        case .notVisited:
            return .systemBlue
        case .completed:
            return .systemGreen
        case .inaccessible:
            return .systemRed
        }
    }
}

struct Location: Codable, Identifiable {
    var id: String // UUID
    var title: String
    var notes: String
    var latitude: Double
    var longitude: Double
    var status: LocationStatus
    var historicalImagePath: String // path to local image
    var historicalImageURL: String // URL to Firebase storage
    var newImagePath: String? // path to new image taken (if any)
    var newImageURL: String? // URL to Firebase storage for new image
    var createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, 
         title: String, 
         notes: String = "", 
         latitude: Double, 
         longitude: Double, 
         status: LocationStatus = .notVisited, 
         historicalImagePath: String, 
         historicalImageURL: String = "", 
         newImagePath: String? = nil, 
         newImageURL: String? = nil) {
        self.id = id
        self.title = title
        self.notes = notes
        self.latitude = latitude
        self.longitude = longitude
        self.status = status
        self.historicalImagePath = historicalImagePath
        self.historicalImageURL = historicalImageURL
        self.newImagePath = newImagePath
        self.newImageURL = newImageURL
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var googleMapsURL: URL? {
        return URL(string: "https://www.google.com/maps/search/?api=1&query=\(latitude),\(longitude)")
    }
    
    mutating func updateStatus(_ status: LocationStatus) {
        self.status = status
        self.updatedAt = Date()
    }
    
    mutating func updateNotes(_ notes: String) {
        self.notes = notes
        self.updatedAt = Date()
    }
    
    mutating func setNewImage(path: String, url: String? = nil) {
        self.newImagePath = path
        if let url = url {
            self.newImageURL = url
        }
        self.status = .completed
        self.updatedAt = Date()
    }
}

import Foundation

enum ImageQuality: String, Codable {
    case high
    case medium
    case low
    
    var compressionQuality: CGFloat {
        switch self {
        case .high:
            return 1.0
        case .medium:
            return 0.7
        case .low:
            return 0.4
        }
    }
}

struct AppSettings: Codable {
    var imageQuality: ImageQuality
    var lastSyncDate: Date?
    
    init(imageQuality: ImageQuality = .high, lastSyncDate: Date? = nil) {
        self.imageQuality = imageQuality
        self.lastSyncDate = lastSyncDate
    }
    
    mutating func updateLastSyncDate() {
        self.lastSyncDate = Date()
    }
}

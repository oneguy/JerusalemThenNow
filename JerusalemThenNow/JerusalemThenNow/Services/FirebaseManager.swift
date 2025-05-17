import Foundation
import Firebase
import FirebaseStorage
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    
    private let db = Firestore.firestore()
    private let storage = Storage.storage()
    
    private init() {
        // Configure Firebase
        FirebaseApp.configure()
    }
    
    // MARK: - Firestore Operations
    
    func uploadLocationsToFirebase(locations: [Location], completion: @escaping (Error?) -> Void) {
        let batch = db.batch()
        
        for location in locations {
            let docRef = db.collection("locations").document(location.id)
            
            let data: [String: Any] = [
                "id": location.id,
                "title": location.title,
                "notes": location.notes,
                "latitude": location.latitude,
                "longitude": location.longitude,
                "status": location.status.rawValue,
                "historicalImageURL": location.historicalImageURL,
                "newImageURL": location.newImageURL as Any,
                "createdAt": location.createdAt,
                "updatedAt": location.updatedAt
            ]
            
            batch.setData(data, forDocument: docRef)
        }
        
        batch.commit { error in
            completion(error)
        }
    }
    
    func downloadLocationsFromFirebase(completion: @escaping ([Location]?, Error?) -> Void) {
        db.collection("locations").getDocuments { (snapshot, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion([], nil)
                return
            }
            
            let locations = documents.compactMap { document -> Location? in
                let data = document.data()
                
                guard let id = data["id"] as? String,
                      let title = data["title"] as? String,
                      let notes = data["notes"] as? String,
                      let latitude = data["latitude"] as? Double,
                      let longitude = data["longitude"] as? Double,
                      let statusRaw = data["status"] as? String,
                      let historicalImageURL = data["historicalImageURL"] as? String,
                      let createdAtTimestamp = data["createdAt"] as? Timestamp,
                      let updatedAtTimestamp = data["updatedAt"] as? Timestamp else {
                    return nil
                }
                
                let status = LocationStatus(rawValue: statusRaw) ?? .notVisited
                let newImageURL = data["newImageURL"] as? String
                
                var location = Location(
                    id: id,
                    title: title,
                    notes: notes,
                    latitude: latitude,
                    longitude: longitude,
                    status: status,
                    historicalImagePath: "",
                    historicalImageURL: historicalImageURL,
                    newImagePath: nil,
                    newImageURL: newImageURL
                )
                
                // Convert Firestore timestamps to Date
                location.createdAt = createdAtTimestamp.dateValue()
                location.updatedAt = updatedAtTimestamp.dateValue()
                
                return location
            }
            
            completion(locations, nil)
        }
    }
    
    // MARK: - Storage Operations
    
    func uploadImage(_ image: UIImage, forLocation locationId: String, isHistorical: Bool, completion: @escaping (String?, Error?) -> Void) {
        guard let imageData = image.jpegData(compressionQuality: DataManager.shared.loadSettingsFromLocal().imageQuality.compressionQuality) else {
            completion(nil, NSError(domain: "FirebaseManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"]))
            return
        }
        
        let imageType = isHistorical ? "historical" : "new"
        let storageRef = storage.reference().child("images/\(locationId)_\(imageType).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        storageRef.putData(imageData, metadata: metadata) { (metadata, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            storageRef.downloadURL { (url, error) in
                if let error = error {
                    completion(nil, error)
                    return
                }
                
                guard let downloadURL = url else {
                    completion(nil, NSError(domain: "FirebaseManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to get download URL"]))
                    return
                }
                
                completion(downloadURL.absoluteString, nil)
            }
        }
    }
    
    func downloadImage(from urlString: String, completion: @escaping (UIImage?, Error?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(nil, NSError(domain: "FirebaseManager", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = data, let image = UIImage(data: data) else {
                completion(nil, NSError(domain: "FirebaseManager", code: 4, userInfo: [NSLocalizedDescriptionKey: "Failed to convert data to image"]))
                return
            }
            
            completion(image, nil)
        }
        
        task.resume()
    }
    
    // MARK: - Sync Operations
    
    func syncToServer(locations: [Location], completion: @escaping (Error?) -> Void) {
        let dispatchGroup = DispatchGroup()
        var syncError: Error?
        
        // First, upload any images that don't have URLs
        for (index, location) in locations.enumerated() {
            var updatedLocation = location
            
            // Upload historical image if needed
            if !location.historicalImagePath.isEmpty && location.historicalImageURL.isEmpty {
                dispatchGroup.enter()
                if let image = DataManager.shared.loadImage(fromPath: location.historicalImagePath) {
                    uploadImage(image, forLocation: location.id, isHistorical: true) { (url, error) in
                        if let error = error {
                            syncError = error
                        } else if let url = url {
                            updatedLocation.historicalImageURL = url
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
            
            // Upload new image if needed
            if let newImagePath = location.newImagePath, !newImagePath.isEmpty, location.newImageURL == nil {
                dispatchGroup.enter()
                if let image = DataManager.shared.loadImage(fromPath: newImagePath) {
                    uploadImage(image, forLocation: location.id, isHistorical: false) { (url, error) in
                        if let error = error {
                            syncError = error
                        } else if let url = url {
                            updatedLocation.newImageURL = url
                        }
                        dispatchGroup.leave()
                    }
                } else {
                    dispatchGroup.leave()
                }
            }
            
            // Update the location in our array if it was modified
            if updatedLocation.historicalImageURL != location.historicalImageURL || updatedLocation.newImageURL != location.newImageURL {
                locations[index] = updatedLocation
            }
        }
        
        // Wait for all image uploads to complete
        dispatchGroup.notify(queue: .main) {
            if let error = syncError {
                completion(error)
                return
            }
            
            // Now upload all location data
            self.uploadLocationsToFirebase(locations: locations) { error in
                if let error = error {
                    completion(error)
                    return
                }
                
                // Update last sync date
                var settings = DataManager.shared.loadSettingsFromLocal()
                settings.updateLastSyncDate()
                DataManager.shared.saveSettingsLocally(settings: settings)
                
                completion(nil)
            }
        }
    }
    
    func syncFromServer(completion: @escaping ([Location]?, Error?) -> Void) {
        downloadLocationsFromFirebase { (locations, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let locations = locations else {
                completion([], nil)
                return
            }
            
            let dispatchGroup = DispatchGroup()
            var updatedLocations = locations
            var syncError: Error?
            
            // Download images for each location
            for (index, location) in locations.enumerated() {
                var updatedLocation = location
                
                // Download historical image
                if !location.historicalImageURL.isEmpty {
                    dispatchGroup.enter()
                    self.downloadImage(from: location.historicalImageURL) { (image, error) in
                        if let error = error {
                            syncError = error
                        } else if let image = image {
                            if let path = DataManager.shared.saveImage(image, withName: "\(location.id)_historical.jpg") {
                                updatedLocation.historicalImagePath = path
                            }
                        }
                        dispatchGroup.leave()
                    }
                }
                
                // Download new image if available
                if let newImageURL = location.newImageURL, !newImageURL.isEmpty {
                    dispatchGroup.enter()
                    self.downloadImage(from: newImageURL) { (image, error) in
                        if let error = error {
                            syncError = error
                        } else if let image = image {
                            if let path = DataManager.shared.saveImage(image, withName: "\(location.id)_new.jpg") {
                                updatedLocation.newImagePath = path
                            }
                        }
                        dispatchGroup.leave()
                    }
                }
                
                updatedLocations[index] = updatedLocation
            }
            
            // Wait for all downloads to complete
            dispatchGroup.notify(queue: .main) {
                if let error = syncError {
                    completion(nil, error)
                    return
                }
                
                // Save all locations locally
                DataManager.shared.saveLocationsLocally(locations: updatedLocations)
                
                // Update last sync date
                var settings = DataManager.shared.loadSettingsFromLocal()
                settings.updateLastSyncDate()
                DataManager.shared.saveSettingsLocally(settings: settings)
                
                completion(updatedLocations, nil)
            }
        }
    }
}

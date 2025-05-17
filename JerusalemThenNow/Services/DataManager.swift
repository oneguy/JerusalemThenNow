import Foundation
import UIKit
import CoreData

class DataManager {
    static let shared = DataManager()
    
    private let fileManager = FileManager.default
    private let userDefaults = UserDefaults.standard
    
    // MARK: - Core Data
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "JerusalemThenNow")
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()
    
    private var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    // MARK: - Local Storage Operations
    
    func saveLocationsLocally(locations: [Location]) {
        // Save to Core Data
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: "LocationEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            
            for location in locations {
                let entity = NSEntityDescription.insertNewObject(forEntityName: "LocationEntity", into: context) as! LocationEntity
                entity.id = location.id
                entity.title = location.title
                entity.notes = location.notes
                entity.latitude = location.latitude
                entity.longitude = location.longitude
                entity.status = location.status.rawValue
                entity.historicalImagePath = location.historicalImagePath
                entity.historicalImageURL = location.historicalImageURL
                entity.newImagePath = location.newImagePath
                entity.newImageURL = location.newImageURL
                entity.createdAt = location.createdAt
                entity.updatedAt = location.updatedAt
            }
            
            try context.save()
        } catch {
            print("Failed to save locations: \(error)")
        }
    }
    
    func loadLocationsFromLocal() -> [Location] {
        let fetchRequest: NSFetchRequest<LocationEntity> = LocationEntity.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            return results.map { entity in
                Location(
                    id: entity.id ?? UUID().uuidString,
                    title: entity.title ?? "",
                    notes: entity.notes ?? "",
                    latitude: entity.latitude,
                    longitude: entity.longitude,
                    status: LocationStatus(rawValue: entity.status ?? "notVisited") ?? .notVisited,
                    historicalImagePath: entity.historicalImagePath ?? "",
                    historicalImageURL: entity.historicalImageURL ?? "",
                    newImagePath: entity.newImagePath,
                    newImageURL: entity.newImageURL
                )
            }
        } catch {
            print("Failed to fetch locations: \(error)")
            return []
        }
    }
    
    func saveSettingsLocally(settings: AppSettings) {
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: "appSettings")
        }
    }
    
    func loadSettingsFromLocal() -> AppSettings {
        if let savedSettings = userDefaults.object(forKey: "appSettings") as? Data,
           let decodedSettings = try? JSONDecoder().decode(AppSettings.self, from: savedSettings) {
            return decodedSettings
        }
        return AppSettings()
    }
    
    // MARK: - Image Storage
    
    func saveImage(_ image: UIImage, withName name: String) -> String? {
        guard let data = image.jpegData(compressionQuality: loadSettingsFromLocal().imageQuality.compressionQuality) else {
            return nil
        }
        
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsDirectory.appendingPathComponent(name)
        
        do {
            try data.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Error saving image: \(error)")
            return nil
        }
    }
    
    func loadImage(fromPath path: String) -> UIImage? {
        return UIImage(contentsOfFile: path)
    }
    
    func deleteImage(atPath path: String) -> Bool {
        do {
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            print("Error deleting image: \(error)")
            return false
        }
    }
    
    // MARK: - Location Operations
    
    func addLocation(_ location: Location) {
        var locations = loadLocationsFromLocal()
        locations.append(location)
        saveLocationsLocally(locations: locations)
    }
    
    func updateLocation(_ location: Location) {
        var locations = loadLocationsFromLocal()
        if let index = locations.firstIndex(where: { $0.id == location.id }) {
            locations[index] = location
            saveLocationsLocally(locations: locations)
        }
    }
    
    func deleteLocation(withId id: String) {
        var locations = loadLocationsFromLocal()
        if let index = locations.firstIndex(where: { $0.id == id }) {
            // Delete associated images
            if let historicalPath = locations[index].historicalImagePath as String?, !historicalPath.isEmpty {
                _ = deleteImage(atPath: historicalPath)
            }
            if let newPath = locations[index].newImagePath, !newPath.isEmpty {
                _ = deleteImage(atPath: newPath)
            }
            
            locations.remove(at: index)
            saveLocationsLocally(locations: locations)
        }
    }
    
    // MARK: - Export Operations
    
    func exportToZip() -> URL? {
        let locations = loadLocationsFromLocal()
        
        // Create temporary directory for export
        let tempDir = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("JerusalemThenNow_Export")
        let imagesDir = tempDir.appendingPathComponent("images")
        let historicalDir = imagesDir.appendingPathComponent("historical")
        let newDir = imagesDir.appendingPathComponent("new")
        
        do {
            // Create directories
            try fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: imagesDir, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: historicalDir, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: newDir, withIntermediateDirectories: true)
            
            // Create CSV file
            var csvContent = "id,title,latitude,longitude,status,notes,google_maps_link,historical_image,new_image\n"
            
            for location in locations {
                // Copy images to export directory
                let historicalImageName = "\(location.id)_historical.jpg"
                let newImageName = "\(location.id)_new.jpg"
                
                if let historicalImage = loadImage(fromPath: location.historicalImagePath) {
                    let historicalDestPath = historicalDir.appendingPathComponent(historicalImageName)
                    if let data = historicalImage.jpegData(compressionQuality: 1.0) {
                        try data.write(to: historicalDestPath)
                    }
                }
                
                if let newImagePath = location.newImagePath, let newImage = loadImage(fromPath: newImagePath) {
                    let newDestPath = newDir.appendingPathComponent(newImageName)
                    if let data = newImage.jpegData(compressionQuality: 1.0) {
                        try data.write(to: newDestPath)
                    }
                }
                
                // Add to CSV
                let googleMapsLink = "https://www.google.com/maps/search/?api=1&query=\(location.latitude),\(location.longitude)"
                let csvLine = "\"\(location.id)\",\"\(location.title)\",\(location.latitude),\(location.longitude),\"\(location.status.rawValue)\",\"\(location.notes.replacingOccurrences(of: "\"", with: "\"\""))\",\"\(googleMapsLink)\",\"images/historical/\(historicalImageName)\",\"images/new/\(newImageName)\"\n"
                csvContent.append(csvLine)
            }
            
            // Write CSV file
            let csvPath = tempDir.appendingPathComponent("locations.csv")
            try csvContent.write(to: csvPath, atomically: true, encoding: .utf8)
            
            // Create ZIP file
            let zipPath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("JerusalemThenNow_Export.zip")
            
            // In a real app, we would use a ZIP library here
            // For this example, we'll just return the directory path
            // In a real implementation, you would use something like:
            // SSZipArchive.createZipFile(atPath: zipPath.path, withContentsOfDirectory: tempDir.path)
            
            return tempDir
        } catch {
            print("Export error: \(error)")
            return nil
        }
    }
}

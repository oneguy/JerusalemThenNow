import Foundation

// MARK: - Core Data Entity Classes

@objc(LocationEntity)
public class LocationEntity: NSManagedObject {
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var notes: String?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var status: String?
    @NSManaged public var historicalImagePath: String?
    @NSManaged public var historicalImageURL: String?
    @NSManaged public var newImagePath: String?
    @NSManaged public var newImageURL: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var updatedAt: Date?
}

extension LocationEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationEntity> {
        return NSFetchRequest<LocationEntity>(entityName: "LocationEntity")
    }
}

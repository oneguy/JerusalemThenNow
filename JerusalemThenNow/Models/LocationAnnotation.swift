import MapKit

class LocationAnnotation: MKPointAnnotation {
    var locationId: String
    var status: LocationStatus
    
    init(location: Location) {
        self.locationId = location.id
        self.status = location.status
        super.init()
        self.coordinate = location.coordinate
        self.title = location.title
    }
    
    var pinColor: UIColor {
        return status.color
    }
}

import UIKit
import CoreLocation

class LocationCell: UITableViewCell {
    
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var statusIndicatorView: UIView!
    @IBOutlet weak var distanceLabel: UILabel!
    
    // MARK: - Properties
    private var location: Location?
    
    // MARK: - Setup
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // Configure status indicator view
        statusIndicatorView.layer.cornerRadius = statusIndicatorView.bounds.width / 2
    }
    
    func configure(with location: Location) {
        self.location = location
        
        // Set title
        titleLabel.text = location.title
        
        // Set status indicator color
        statusIndicatorView.backgroundColor = location.status.color
        
        // Clear distance initially
        distanceLabel.text = ""
    }
    
    func setDistance(_ distance: CLLocationDistance?) {
        if let distance = distance {
            // Format distance based on length
            if distance < 1000 {
                distanceLabel.text = String(format: "%.0f m", distance)
            } else {
                distanceLabel.text = String(format: "%.1f km", distance / 1000)
            }
        } else {
            distanceLabel.text = ""
        }
    }
}

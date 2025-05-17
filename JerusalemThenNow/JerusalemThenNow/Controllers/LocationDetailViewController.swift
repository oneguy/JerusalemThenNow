import UIKit
import MapKit

class LocationDetailViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var coordinatesLabel: UILabel!
    @IBOutlet weak var statusSegmentedControl: UISegmentedControl!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var historicalImageView: UIImageView!
    @IBOutlet weak var newImageView: UIImageView!
    @IBOutlet weak var openInMapsButton: UIButton!
    @IBOutlet weak var cameraButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var sideBySideButton: UIButton!
    
    // MARK: - Properties
    var location: Location!
    private let dataManager = DataManager.shared
    private let locationManager = LocationManager.shared
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        displayLocationDetails()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        // Configure status segmented control
        statusSegmentedControl.removeAllSegments()
        statusSegmentedControl.insertSegment(withTitle: "Not Visited", at: 0, animated: false)
        statusSegmentedControl.insertSegment(withTitle: "Completed", at: 1, animated: false)
        statusSegmentedControl.insertSegment(withTitle: "Inaccessible", at: 2, animated: false)
        
        // Set up notes text view
        notesTextView.layer.borderColor = UIColor.lightGray.cgColor
        notesTextView.layer.borderWidth = 1.0
        notesTextView.layer.cornerRadius = 5.0
        
        // Set up image views
        historicalImageView.contentMode = .scaleAspectFit
        historicalImageView.layer.borderColor = UIColor.lightGray.cgColor
        historicalImageView.layer.borderWidth = 1.0
        historicalImageView.layer.cornerRadius = 5.0
        
        newImageView.contentMode = .scaleAspectFit
        newImageView.layer.borderColor = UIColor.lightGray.cgColor
        newImageView.layer.borderWidth = 1.0
        newImageView.layer.cornerRadius = 5.0
        
        // Set up buttons
        openInMapsButton.layer.cornerRadius = 5.0
        cameraButton.layer.cornerRadius = 5.0
        deleteButton.layer.cornerRadius = 5.0
        sideBySideButton.layer.cornerRadius = 5.0
        
        // Add tap gesture to images for fullscreen view
        let historicalTapGesture = UITapGestureRecognizer(target: self, action: #selector(historicalImageTapped))
        historicalImageView.addGestureRecognizer(historicalTapGesture)
        historicalImageView.isUserInteractionEnabled = true
        
        let newTapGesture = UITapGestureRecognizer(target: self, action: #selector(newImageTapped))
        newImageView.addGestureRecognizer(newTapGesture)
        newImageView.isUserInteractionEnabled = true
    }
    
    private func displayLocationDetails() {
        // Set title and coordinates
        titleLabel.text = location.title
        coordinatesLabel.text = String(format: "%.6f, %.6f", location.latitude, location.longitude)
        
        // Set status
        switch location.status {
        case .notVisited:
            statusSegmentedControl.selectedSegmentIndex = 0
        case .completed:
            statusSegmentedControl.selectedSegmentIndex = 1
        case .inaccessible:
            statusSegmentedControl.selectedSegmentIndex = 2
        }
        
        // Set notes
        notesTextView.text = location.notes
        
        // Load historical image
        if let historicalImage = dataManager.loadImage(fromPath: location.historicalImagePath) {
            historicalImageView.image = historicalImage
        }
        
        // Load new image if available
        if let newImagePath = location.newImagePath, let newImage = dataManager.loadImage(fromPath: newImagePath) {
            newImageView.image = newImage
            newImageView.isHidden = false
            sideBySideButton.isEnabled = true
        } else {
            newImageView.isHidden = true
            sideBySideButton.isEnabled = false
        }
    }
    
    // MARK: - Action Methods
    
    @IBAction func statusChanged(_ sender: UISegmentedControl) {
        var updatedLocation = location!
        
        switch sender.selectedSegmentIndex {
        case 0:
            updatedLocation.updateStatus(.notVisited)
        case 1:
            updatedLocation.updateStatus(.completed)
        case 2:
            updatedLocation.updateStatus(.inaccessible)
        default:
            break
        }
        
        dataManager.updateLocation(updatedLocation)
        location = updatedLocation
    }
    
    @IBAction func saveNotesButtonTapped(_ sender: UIButton) {
        var updatedLocation = location!
        updatedLocation.updateNotes(notesTextView.text)
        
        dataManager.updateLocation(updatedLocation)
        location = updatedLocation
        
        // Hide keyboard
        notesTextView.resignFirstResponder()
        
        // Show confirmation
        let alert = UIAlertController(title: "Notes Saved", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func openInMapsButtonTapped(_ sender: UIButton) {
        locationManager.openInGoogleMaps(latitude: location.latitude, longitude: location.longitude)
    }
    
    @IBAction func cameraButtonTapped(_ sender: UIButton) {
        // Navigate to camera view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let cameraVC = storyboard.instantiateViewController(withIdentifier: "CameraViewController") as? CameraViewController {
            cameraVC.location = location
            navigationController?.pushViewController(cameraVC, animated: true)
        }
    }
    
    @IBAction func deleteButtonTapped(_ sender: UIButton) {
        // Show confirmation alert
        let alert = UIAlertController(title: "Delete Location", message: "Are you sure you want to delete this location?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self, let location = self.location else { return }
            
            self.dataManager.deleteLocation(withId: location.id)
            self.navigationController?.popViewController(animated: true)
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func sideBySideButtonTapped(_ sender: UIButton) {
        // Navigate to side-by-side comparison view
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let comparisonVC = storyboard.instantiateViewController(withIdentifier: "ComparisonViewController") as? ComparisonViewController {
            comparisonVC.location = location
            navigationController?.pushViewController(comparisonVC, animated: true)
        }
    }
    
    @objc func historicalImageTapped() {
        showFullscreenImage(historicalImageView.image, title: "Historical Image")
    }
    
    @objc func newImageTapped() {
        showFullscreenImage(newImageView.image, title: "New Image")
    }
    
    private func showFullscreenImage(_ image: UIImage?, title: String) {
        guard let image = image else { return }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let fullscreenVC = storyboard.instantiateViewController(withIdentifier: "FullscreenImageViewController") as? FullscreenImageViewController {
            fullscreenVC.image = image
            fullscreenVC.imageTitle = title
            navigationController?.pushViewController(fullscreenVC, animated: true)
        }
    }
}

// MARK: - UITextViewDelegate

extension LocationDetailViewController: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        // Scroll to make text view visible when keyboard appears
        let bottomOffset = CGPoint(x: 0, y: textView.frame.maxY - view.frame.height + 250)
        if bottomOffset.y > 0 {
            view.setContentOffset(bottomOffset, animated: true)
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        // Reset scroll position when keyboard disappears
        view.setContentOffset(.zero, animated: true)
    }
}

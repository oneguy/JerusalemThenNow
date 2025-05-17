import UIKit

class SettingsViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var imageQualitySegmentedControl: UISegmentedControl!
    @IBOutlet weak var lastSyncLabel: UILabel!
    @IBOutlet weak var syncToServerButton: UIButton!
    @IBOutlet weak var syncFromServerButton: UIButton!
    @IBOutlet weak var exportButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: - Properties
    private let dataManager = DataManager.shared
    private let firebaseManager = FirebaseManager.shared
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadSettings()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        // Configure image quality segmented control
        imageQualitySegmentedControl.removeAllSegments()
        imageQualitySegmentedControl.insertSegment(withTitle: "High", at: 0, animated: false)
        imageQualitySegmentedControl.insertSegment(withTitle: "Medium", at: 1, animated: false)
        imageQualitySegmentedControl.insertSegment(withTitle: "Low", at: 2, animated: false)
        
        // Configure buttons
        syncToServerButton.layer.cornerRadius = 5.0
        syncFromServerButton.layer.cornerRadius = 5.0
        exportButton.layer.cornerRadius = 5.0
        
        // Hide activity indicator initially
        activityIndicator.hidesWhenStopped = true
    }
    
    private func loadSettings() {
        let settings = dataManager.loadSettingsFromLocal()
        
        // Set image quality selection
        switch settings.imageQuality {
        case .high:
            imageQualitySegmentedControl.selectedSegmentIndex = 0
        case .medium:
            imageQualitySegmentedControl.selectedSegmentIndex = 1
        case .low:
            imageQualitySegmentedControl.selectedSegmentIndex = 2
        }
        
        // Set last sync date
        if let lastSyncDate = settings.lastSyncDate {
            let dateFormatter = DateFormatter()
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            lastSyncLabel.text = "Last sync: \(dateFormatter.string(from: lastSyncDate))"
        } else {
            lastSyncLabel.text = "Last sync: Never"
        }
    }
    
    // MARK: - Action Methods
    
    @IBAction func imageQualityChanged(_ sender: UISegmentedControl) {
        var settings = dataManager.loadSettingsFromLocal()
        
        switch sender.selectedSegmentIndex {
        case 0:
            settings.imageQuality = .high
        case 1:
            settings.imageQuality = .medium
        case 2:
            settings.imageQuality = .low
        default:
            break
        }
        
        dataManager.saveSettingsLocally(settings: settings)
    }
    
    @IBAction func syncToServerButtonTapped(_ sender: UIButton) {
        // Show activity indicator
        activityIndicator.startAnimating()
        
        // Disable buttons during sync
        setButtonsEnabled(false)
        
        // Get locations from local storage
        let locations = dataManager.loadLocationsFromLocal()
        
        // Sync to server
        firebaseManager.syncToServer(locations: locations) { [weak self] error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Hide activity indicator
                self.activityIndicator.stopAnimating()
                
                // Re-enable buttons
                self.setButtonsEnabled(true)
                
                if let error = error {
                    self.showAlert(title: "Sync Error", message: error.localizedDescription)
                } else {
                    // Update last sync date display
                    self.loadSettings()
                    self.showAlert(title: "Sync Complete", message: "Data successfully uploaded to server")
                }
            }
        }
    }
    
    @IBAction func syncFromServerButtonTapped(_ sender: UIButton) {
        // Show activity indicator
        activityIndicator.startAnimating()
        
        // Disable buttons during sync
        setButtonsEnabled(false)
        
        // Sync from server
        firebaseManager.syncFromServer { [weak self] (locations, error) in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                // Hide activity indicator
                self.activityIndicator.stopAnimating()
                
                // Re-enable buttons
                self.setButtonsEnabled(true)
                
                if let error = error {
                    self.showAlert(title: "Sync Error", message: error.localizedDescription)
                } else {
                    // Update last sync date display
                    self.loadSettings()
                    self.showAlert(title: "Sync Complete", message: "Data successfully downloaded from server")
                }
            }
        }
    }
    
    @IBAction func exportButtonTapped(_ sender: UIButton) {
        // Show activity indicator
        activityIndicator.startAnimating()
        
        // Disable buttons during export
        setButtonsEnabled(false)
        
        // Export data
        if let exportURL = dataManager.exportToZip() {
            // Hide activity indicator
            activityIndicator.stopAnimating()
            
            // Re-enable buttons
            setButtonsEnabled(true)
            
            // Share exported file
            let activityViewController = UIActivityViewController(activityItems: [exportURL], applicationActivities: nil)
            present(activityViewController, animated: true)
        } else {
            // Hide activity indicator
            activityIndicator.stopAnimating()
            
            // Re-enable buttons
            setButtonsEnabled(true)
            
            showAlert(title: "Export Error", message: "Failed to export data")
        }
    }
    
    private func setButtonsEnabled(_ enabled: Bool) {
        syncToServerButton.isEnabled = enabled
        syncFromServerButton.isEnabled = enabled
        exportButton.isEnabled = enabled
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

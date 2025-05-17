import UIKit

class ImageReviewViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var capturedImageView: UIImageView!
    @IBOutlet weak var historicalImageView: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var retakeButton: UIButton!
    
    // MARK: - Properties
    var capturedImage: UIImage!
    var location: Location!
    private let dataManager = DataManager.shared
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadImages()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        title = "Review Photo"
        
        // Configure image views
        capturedImageView.contentMode = .scaleAspectFit
        historicalImageView.contentMode = .scaleAspectFit
        
        // Configure buttons
        saveButton.layer.cornerRadius = 5.0
        retakeButton.layer.cornerRadius = 5.0
    }
    
    private func loadImages() {
        // Set captured image
        capturedImageView.image = capturedImage
        
        // Load historical image
        if let historicalImage = dataManager.loadImage(fromPath: location.historicalImagePath) {
            historicalImageView.image = historicalImage
        }
    }
    
    // MARK: - Action Methods
    
    @IBAction func saveButtonTapped(_ sender: UIButton) {
        // Navigate back to location detail
        navigationController?.popToViewController(ofClass: LocationDetailViewController.self) ?? navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func retakeButtonTapped(_ sender: UIButton) {
        // Navigate back to camera view
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        guard let image = capturedImage else { return }
        
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityViewController, animated: true)
    }
}

// MARK: - UINavigationController Extension

extension UINavigationController {
    func popToViewController(ofClass: AnyClass, animated: Bool = true) -> UIViewController? {
        if let vc = viewControllers.last(where: { $0.isKind(of: ofClass) }) {
            popToViewController(vc, animated: animated)
            return vc
        }
        return nil
    }
}

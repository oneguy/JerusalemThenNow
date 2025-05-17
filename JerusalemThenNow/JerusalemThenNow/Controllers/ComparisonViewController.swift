import UIKit

class ComparisonViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var historicalImageView: UIImageView!
    @IBOutlet weak var newImageView: UIImageView!
    @IBOutlet weak var sliderView: UIView!
    @IBOutlet weak var sliderPosition: NSLayoutConstraint!
    @IBOutlet weak var panHandle: UIView!
    
    // MARK: - Properties
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
        title = "Then & Now Comparison"
        
        // Configure image views
        historicalImageView.contentMode = .scaleAspectFit
        newImageView.contentMode = .scaleAspectFit
        
        // Configure slider handle
        panHandle.layer.cornerRadius = 3.0
        panHandle.backgroundColor = .white
        panHandle.layer.shadowColor = UIColor.black.cgColor
        panHandle.layer.shadowOffset = CGSize(width: 0, height: 2)
        panHandle.layer.shadowRadius = 2.0
        panHandle.layer.shadowOpacity = 0.5
        
        // Add pan gesture for slider
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        sliderView.addGestureRecognizer(panGesture)
    }
    
    private func loadImages() {
        // Load historical image
        if let historicalImage = dataManager.loadImage(fromPath: location.historicalImagePath) {
            historicalImageView.image = historicalImage
        }
        
        // Load new image
        if let newImagePath = location.newImagePath, let newImage = dataManager.loadImage(fromPath: newImagePath) {
            newImageView.image = newImage
        } else {
            // If no new image, show placeholder
            newImageView.image = UIImage(systemName: "photo")
            newImageView.tintColor = .gray
        }
    }
    
    // MARK: - Action Methods
    
    @objc func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        // Calculate new position
        let newPosition = sliderPosition.constant + translation.x
        
        // Constrain to view bounds
        let minPosition: CGFloat = 0
        let maxPosition = view.bounds.width
        
        sliderPosition.constant = min(max(newPosition, minPosition), maxPosition)
        
        // Reset translation
        gesture.setTranslation(.zero, in: view)
    }
    
    @IBAction func shareButtonTapped(_ sender: UIButton) {
        // Create a composite image of the comparison
        if let compositeImage = createComparisonImage() {
            // Share the image
            let activityViewController = UIActivityViewController(activityItems: [compositeImage], applicationActivities: nil)
            present(activityViewController, animated: true)
        }
    }
    
    private func createComparisonImage() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0.0)
        
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        
        let compositeImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return compositeImage
    }
}

import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var cameraPreviewView: UIView!
    @IBOutlet weak var overlayImageView: UIImageView!
    @IBOutlet weak var opacitySlider: UISlider!
    @IBOutlet weak var captureButton: UIButton!
    @IBOutlet weak var effectsSegmentedControl: UISegmentedControl!
    
    // MARK: - Properties
    var location: Location!
    private let cameraManager = CameraManager.shared
    private let dataManager = DataManager.shared
    private var historicalImage: UIImage?
    private var currentEffect: AlignmentEffect = .none
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupCamera()
        loadHistoricalImage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Start camera session
        cameraManager.startCameraSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Stop camera session
        cameraManager.stopCameraSession()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        // Configure capture button
        captureButton.layer.cornerRadius = captureButton.bounds.width / 2
        captureButton.layer.borderWidth = 3.0
        captureButton.layer.borderColor = UIColor.white.cgColor
        
        // Configure overlay image view
        overlayImageView.contentMode = .scaleAspectFill
        overlayImageView.alpha = CGFloat(opacitySlider.value)
        
        // Configure effects segmented control
        effectsSegmentedControl.removeAllSegments()
        effectsSegmentedControl.insertSegment(withTitle: "None", at: 0, animated: false)
        effectsSegmentedControl.insertSegment(withTitle: "Contrast", at: 1, animated: false)
        effectsSegmentedControl.insertSegment(withTitle: "Edges", at: 2, animated: false)
        effectsSegmentedControl.insertSegment(withTitle: "Grid", at: 3, animated: false)
        effectsSegmentedControl.selectedSegmentIndex = 0
        
        // Add pinch gesture for zoom
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        cameraPreviewView.addGestureRecognizer(pinchGesture)
    }
    
    private func setupCamera() {
        // Set up camera session
        if cameraManager.setupCameraSession() {
            cameraManager.setupPreviewLayer(in: cameraPreviewView)
        } else {
            showAlert(title: "Camera Error", message: "Could not set up camera. Please check camera permissions.")
        }
    }
    
    private func loadHistoricalImage() {
        // Load historical image
        if let image = dataManager.loadImage(fromPath: location.historicalImagePath) {
            historicalImage = image
            overlayImageView.image = image
        }
    }
    
    // MARK: - Action Methods
    
    @IBAction func opacitySliderChanged(_ sender: UISlider) {
        overlayImageView.alpha = CGFloat(sender.value)
    }
    
    @IBAction func captureButtonTapped(_ sender: UIButton) {
        // Get image quality from settings
        let imageQuality = dataManager.loadSettingsFromLocal().imageQuality
        
        // Capture photo
        cameraManager.capturePhoto(quality: imageQuality) { [weak self] (image, error) in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.showAlert(title: "Capture Error", message: error.localizedDescription)
                }
                return
            }
            
            guard let image = image else {
                DispatchQueue.main.async {
                    self.showAlert(title: "Capture Error", message: "Failed to capture image")
                }
                return
            }
            
            // Save image to photo library
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
            
            // Save image to app storage
            if let imagePath = self.dataManager.saveImage(image, withName: "\(self.location.id)_new.jpg") {
                var updatedLocation = self.location!
                updatedLocation.setNewImage(path: imagePath)
                self.dataManager.updateLocation(updatedLocation)
                self.location = updatedLocation
                
                // Show review screen
                DispatchQueue.main.async {
                    self.showImageReviewScreen(image)
                }
            }
        }
    }
    
    @IBAction func effectsChanged(_ sender: UISegmentedControl) {
        guard let historicalImage = historicalImage else { return }
        
        switch sender.selectedSegmentIndex {
        case 0:
            currentEffect = .none
            overlayImageView.image = historicalImage
        case 1:
            currentEffect = .highContrast
            overlayImageView.image = cameraManager.applyAlignmentEffect(effect: .highContrast, to: historicalImage)
        case 2:
            currentEffect = .edgeDetection
            overlayImageView.image = cameraManager.applyAlignmentEffect(effect: .edgeDetection, to: historicalImage)
        case 3:
            currentEffect = .gridOverlay
            overlayImageView.image = cameraManager.applyAlignmentEffect(effect: .gridOverlay, to: historicalImage)
        default:
            break
        }
    }
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            cameraManager.switchLens(zoomFactor: gesture.scale)
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            showAlert(title: "Save Error", message: error.localizedDescription)
        }
    }
    
    private func showImageReviewScreen(_ image: UIImage) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let reviewVC = storyboard.instantiateViewController(withIdentifier: "ImageReviewViewController") as? ImageReviewViewController {
            reviewVC.capturedImage = image
            reviewVC.location = location
            navigationController?.pushViewController(reviewVC, animated: true)
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

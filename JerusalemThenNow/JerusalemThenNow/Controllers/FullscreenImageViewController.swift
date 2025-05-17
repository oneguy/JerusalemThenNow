import UIKit

class FullscreenImageViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollView: UIScrollView!
    
    // MARK: - Properties
    var image: UIImage!
    var imageTitle: String = "Image"
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupGestures()
    }
    
    // MARK: - Setup Methods
    
    private func setupUI() {
        title = imageTitle
        
        // Configure scroll view
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 4.0
        
        // Configure image view
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
    }
    
    private func setupGestures() {
        // Double tap to zoom
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapGesture)
    }
    
    // MARK: - Action Methods
    
    @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            // Zoom out
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            // Zoom in to the tapped point
            let location = gesture.location(in: imageView)
            let zoomRect = CGRect(
                x: location.x - 100,
                y: location.y - 100,
                width: 200,
                height: 200
            )
            scrollView.zoom(to: zoomRect, animated: true)
        }
    }
    
    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        guard let image = image else { return }
        
        let activityViewController = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        present(activityViewController, animated: true)
    }
}

// MARK: - UIScrollViewDelegate

extension FullscreenImageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Center the image in the scroll view
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}

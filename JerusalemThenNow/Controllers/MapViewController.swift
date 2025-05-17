import UIKit
import MapKit

class MapViewController: UIViewController {
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    
    // MARK: - Properties
    private var locations: [Location] = []
    private var annotations: [LocationAnnotation] = []
    private let locationManager = LocationManager.shared
    private let dataManager = DataManager.shared
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupMapView()
        setupLongPressGesture()
        locationManager.requestLocationPermission()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reload locations from local storage
        loadLocations()
    }
    
    // MARK: - Setup Methods
    
    private func setupMapView() {
        mapView.delegate = self
        mapView.showsUserLocation = true
    }
    
    private func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0
        mapView.addGestureRecognizer(longPressGesture)
    }
    
    // MARK: - Data Methods
    
    private func loadLocations() {
        locations = dataManager.loadLocationsFromLocal()
        updateMapAnnotations()
        
        // Center map on locations
        locationManager.getCurrentLocation { [weak self] currentLocation in
            guard let self = self else { return }
            
            let region = self.locationManager.regionForLocations(self.locations, currentLocation: currentLocation)
            self.mapView.setRegion(region, animated: true)
        }
    }
    
    private func updateMapAnnotations() {
        // Remove existing annotations
        mapView.removeAnnotations(annotations)
        annotations.removeAll()
        
        // Add new annotations
        for location in locations {
            let annotation = LocationAnnotation(location: location)
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
    }
    
    // MARK: - Action Methods
    
    @objc private func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let coordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            // Show alert to add new location
            showAddLocationAlert(at: coordinate)
        }
    }
    
    private func showAddLocationAlert(at coordinate: CLLocationCoordinate2D) {
        let alert = UIAlertController(title: "Add New Location", message: "Enter a title for this location", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "Location Title"
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let self = self,
                  let titleField = alert.textFields?.first,
                  let title = titleField.text, !title.isEmpty else {
                return
            }
            
            // Show image picker to select historical image
            self.showImagePicker(for: coordinate, title: title)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(addAction)
        
        present(alert, animated: true)
    }
    
    private func showImagePicker(for coordinate: CLLocationCoordinate2D, title: String) {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
        // Store coordinate and title for use in delegate method
        UserDefaults.standard.set(coordinate.latitude, forKey: "tempLocationLatitude")
        UserDefaults.standard.set(coordinate.longitude, forKey: "tempLocationLongitude")
        UserDefaults.standard.set(title, forKey: "tempLocationTitle")
        
        present(imagePicker, animated: true)
    }
    
    private func navigateToLocationDetail(_ location: Location) {
        // Navigate to location detail view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let detailVC = storyboard.instantiateViewController(withIdentifier: "LocationDetailViewController") as? LocationDetailViewController {
            detailVC.location = location
            navigationController?.pushViewController(detailVC, animated: true)
        }
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Skip user location annotation
        if annotation is MKUserLocation {
            return nil
        }
        
        // Cast to our custom annotation
        guard let locationAnnotation = annotation as? LocationAnnotation else {
            return nil
        }
        
        let identifier = "LocationPin"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
        
        if annotationView == nil {
            annotationView = MKMarkerAnnotationView(annotation: locationAnnotation, reuseIdentifier: identifier)
            annotationView?.canShowCallout = true
            
            // Add detail disclosure button
            let detailButton = UIButton(type: .detailDisclosure)
            annotationView?.rightCalloutAccessoryView = detailButton
        } else {
            annotationView?.annotation = locationAnnotation
        }
        
        // Set pin color based on location status
        annotationView?.markerTintColor = locationAnnotation.pinColor
        
        return annotationView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        guard let annotation = view.annotation as? LocationAnnotation,
              let location = locations.first(where: { $0.id == annotation.locationId }) else {
            return
        }
        
        navigateToLocationDetail(location)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension MapViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage,
              let latitude = UserDefaults.standard.object(forKey: "tempLocationLatitude") as? Double,
              let longitude = UserDefaults.standard.object(forKey: "tempLocationLongitude") as? Double,
              let title = UserDefaults.standard.string(forKey: "tempLocationTitle") else {
            picker.dismiss(animated: true)
            return
        }
        
        // Save image to local storage
        if let imagePath = dataManager.saveImage(image, withName: "\(UUID().uuidString)_historical.jpg") {
            // Create new location
            let newLocation = Location(
                title: title,
                latitude: latitude,
                longitude: longitude,
                historicalImagePath: imagePath
            )
            
            // Add to data manager
            dataManager.addLocation(newLocation)
            
            // Reload locations
            loadLocations()
        }
        
        // Clean up temporary storage
        UserDefaults.standard.removeObject(forKey: "tempLocationLatitude")
        UserDefaults.standard.removeObject(forKey: "tempLocationLongitude")
        UserDefaults.standard.removeObject(forKey: "tempLocationTitle")
        
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        // Clean up temporary storage
        UserDefaults.standard.removeObject(forKey: "tempLocationLatitude")
        UserDefaults.standard.removeObject(forKey: "tempLocationLongitude")
        UserDefaults.standard.removeObject(forKey: "tempLocationTitle")
        
        picker.dismiss(animated: true)
    }
}

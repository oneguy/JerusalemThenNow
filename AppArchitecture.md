# Jerusalem Then & Now App Architecture

## Overview
The Jerusalem Then & Now app is designed to help users capture modern photos from the same angles as historical images of Jerusalem. The app will use a combination of local storage and Firebase backend for data persistence, with manual sync capabilities.

## Core Components

### 1. Data Models

#### Location Model
```swift
struct Location: Codable, Identifiable {
    var id: String // UUID
    var title: String
    var notes: String
    var latitude: Double
    var longitude: Double
    var status: LocationStatus // enum: notVisited, completed, inaccessible
    var historicalImagePath: String // path to local image
    var historicalImageURL: String // URL to Firebase storage
    var newImagePath: String? // path to new image taken (if any)
    var newImageURL: String? // URL to Firebase storage for new image
    var createdAt: Date
    var updatedAt: Date
}

enum LocationStatus: String, Codable {
    case notVisited // Blue
    case completed // Green
    case inaccessible // Red
}
```

#### App Settings Model
```swift
struct AppSettings: Codable {
    var imageQuality: ImageQuality // enum: high, medium, low
    var lastSyncDate: Date?
}

enum ImageQuality: String, Codable {
    case high
    case medium
    case low
}
```

### 2. Services

#### DataManager
Responsible for managing local data persistence and synchronization with Firebase.

```swift
class DataManager {
    // Local storage operations
    func saveLocationsLocally(locations: [Location])
    func loadLocationsFromLocal() -> [Location]
    func saveSettingsLocally(settings: AppSettings)
    func loadSettingsFromLocal() -> AppSettings
    
    // Firebase operations
    func uploadLocationsToFirebase(locations: [Location])
    func downloadLocationsFromFirebase() -> [Location]
    func uploadImage(image: UIImage, path: String) -> String // Returns URL
    func downloadImage(url: String) -> UIImage?
    
    // Sync operations
    func syncToServer() // Push local data to Firebase
    func syncFromServer() // Pull data from Firebase to local
    
    // Export operations
    func exportToZip() -> URL? // Returns URL to the exported ZIP file
}
```

#### LocationManager
Handles location-related operations and map interactions.

```swift
class LocationManager {
    func getCurrentLocation() -> CLLocation?
    func calculateDistance(from: CLLocation, to: CLLocation) -> CLLocationDistance
    func openInGoogleMaps(latitude: Double, longitude: Double)
}
```

#### CameraManager
Manages camera operations, including lens switching and image capture.

```swift
class CameraManager {
    func setupCameraSession()
    func startCameraSession()
    func stopCameraSession()
    func capturePhoto(quality: ImageQuality) -> UIImage?
    func switchLens(zoomFactor: CGFloat) // Automatically switches between available lenses
    func applyOverlay(historicalImage: UIImage, opacity: Float) -> CIFilter?
    func applyAlignmentEffect(effect: AlignmentEffect) -> CIFilter?
}

enum AlignmentEffect {
    case highContrast
    case edgeDetection
    case gridOverlay
    // Other effects as needed
}
```

### 3. View Controllers

#### MapViewController
Displays locations on a map with color-coded pins.

```swift
class MapViewController: UIViewController {
    // Map view and related UI elements
    // Location pins with color coding
    // Long press gesture recognizer for adding new locations
    
    func setupMapView()
    func displayLocations(locations: [Location])
    func updateLocationStatus(location: Location, status: LocationStatus)
    func handleLongPress(gestureRecognizer: UILongPressGestureRecognizer)
    func navigateToLocationDetail(location: Location)
}
```

#### LocationListViewController
Displays locations in a list format.

```swift
class LocationListViewController: UIViewController {
    // Table view for locations
    
    func setupTableView()
    func displayLocations(locations: [Location])
    func navigateToLocationDetail(location: Location)
}
```

#### LocationDetailViewController
Shows details of a selected location, including historical image and notes.

```swift
class LocationDetailViewController: UIViewController {
    // UI elements for displaying location details
    // Historical image view
    // New image view (if available)
    // Notes text view
    // Status selection controls
    // Camera button
    // Delete button
    
    func displayLocationDetails(location: Location)
    func updateLocationStatus(status: LocationStatus)
    func updateLocationNotes(notes: String)
    func openCamera()
    func deleteLocation()
    func openInGoogleMaps()
}
```

#### CameraViewController
Provides camera interface with historical image overlay.

```swift
class CameraViewController: UIViewController {
    // Camera preview view
    // Historical image overlay view
    // Opacity slider for overlay
    // Zoom controls
    // Capture button
    // Alignment effect buttons
    
    func setupCameraInterface()
    func updateOverlayOpacity(opacity: Float)
    func handlePinchGesture(gestureRecognizer: UIPinchGestureRecognizer)
    func capturePhoto()
    func applyAlignmentEffect(effect: AlignmentEffect)
}
```

#### SettingsViewController
Manages app settings and data synchronization.

```swift
class SettingsViewController: UIViewController {
    // Image quality selection
    // Sync buttons
    // Export button
    
    func updateImageQuality(quality: ImageQuality)
    func syncToServer()
    func syncFromServer()
    func exportData()
}
```

### 4. Navigation Flow

1. **Main Tab Bar Controller**
   - Map Tab
   - List Tab
   - Settings Tab

2. **Map View Flow**
   - View locations on map
   - Long press to add new location
   - Tap location pin to view details
   - From details, navigate to camera view

3. **List View Flow**
   - View locations in list
   - Tap location to view details
   - From details, navigate to camera view

4. **Camera View Flow**
   - View camera with historical image overlay
   - Adjust overlay opacity
   - Apply alignment effects
   - Capture photo
   - Return to location details with new photo

5. **Settings Flow**
   - Adjust image quality
   - Sync data to/from server
   - Export data to ZIP with CSV

### 5. Firebase Integration

#### Firebase Services Used
- **Firestore**: For storing location data
- **Storage**: For storing images
- **No Authentication**: As per requirements, using hardcoded credentials

#### Data Structure
```
/locations/{locationId}
  - id: String
  - title: String
  - notes: String
  - latitude: Double
  - longitude: Double
  - status: String
  - historicalImageURL: String
  - newImageURL: String?
  - createdAt: Timestamp
  - updatedAt: Timestamp

/images/{imageId}
  - Binary image data
```

### 6. Local Storage

#### Core Data
- Location entity
- Settings entity

#### File System
- Historical images
- New captured images

### 7. Export Functionality

#### ZIP Structure
```
JerusalemThenNow_Export/
  - locations.csv
  - images/
    - historical/
      - {locationId}_historical.jpg
    - new/
      - {locationId}_new.jpg
```

#### CSV Format
```
id,title,latitude,longitude,status,notes,google_maps_link,historical_image,new_image
```

## Technical Considerations

### 1. Camera Implementation
- Using AVFoundation for camera access
- Automatic lens switching based on zoom level
- Core Image filters for alignment effects

### 2. Map Implementation
- Using MapKit for map display
- Custom annotations for color-coded pins
- Long press gesture recognizer for adding new locations

### 3. Data Synchronization
- Manual sync triggered by user
- Simple pull/push operations
- No conflict resolution (last write wins)

### 4. Performance Considerations
- Efficient image loading and caching
- Lazy loading of images in list view
- Optimized camera preview rendering

### 5. Error Handling
- Graceful handling of network errors
- Local fallback when Firebase is unavailable
- User feedback for operation success/failure

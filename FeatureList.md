# Jerusalem Then & Now App - Feature List

## 1. Map Interface
- **Interactive Map View**: Display all locations with color-coded pins
  - Blue pins: Not visited locations
  - Green pins: Completed locations
  - Red pins: Inaccessible locations
- **Location Addition**: Long press on map to add new location
- **Location Selection**: Tap on pin to view location details
- **Current Location**: Show user's current location on map
- **Map Navigation**: Standard pan and zoom controls

## 2. List Interface
- **Sortable Location List**: View all locations in list format
  - Sort by distance from current location
  - Sort by status (not visited, completed, inaccessible)
  - Sort by creation date
- **Color-Coded Status**: Visual indicators matching map pin colors
- **Quick Actions**: Swipe actions for marking status or deleting

## 3. Location Management
- **Location Details View**: View and edit location information
  - Title/name of location
  - GPS coordinates
  - Status indicator with ability to change
  - Notes field
  - Historical image display
  - New image display (if available)
  - Side-by-side comparison view
- **Google Maps Integration**: Open location in Google Maps
- **Location Deletion**: Delete location with confirmation dialog
- **Notes Management**: Add, edit, and save notes for each location

## 4. Camera Interface
- **Camera View**: Native camera interface
- **Historical Image Overlay**: Adjustable opacity slider for overlay
- **Alignment Aids**:
  - High contrast mode
  - Edge detection
  - Grid overlay
  - Other visual aids for alignment
- **Zoom Control**: Pinch-to-zoom functionality
- **Automatic Lens Switching**: Switch between available lenses based on zoom level
  - Wide-angle lens
  - 1x standard lens
  - 5x telephoto lens (when available)
- **Image Capture**: Take photo with highest quality
- **Image Review**: Review captured image before saving

## 5. Image Management
- **Dual Storage**: Save images to both app and device photo library
- **Side-by-Side Comparison**: View historical and new images together
- **Image Quality Settings**: Configure image capture quality
  - High (default)
  - Medium
  - Low

## 6. Data Synchronization
- **Firebase Integration**: Store data in Firebase backend
  - Firestore for location data
  - Firebase Storage for images
- **Manual Sync Controls**:
  - "Pull data from server" button
  - "Push data to server" button
- **Sync Status Indicator**: Show last sync date/time
- **Offline Functionality**: Full app functionality without internet connection

## 7. Export Functionality
- **ZIP Export**: Create ZIP file containing all app data
  - CSV file with location information
  - Historical images folder
  - New images folder
  - Google Maps links for each location
- **Share Options**: Share ZIP file via standard iOS share sheet

## 8. Settings
- **Image Quality Configuration**: Set default image capture quality
- **Sync Controls**: Manual sync buttons
- **Export Controls**: Generate and share ZIP file
- **Storage Information**: View local and server storage usage

## 9. User Interface
- **Native iOS Design**: Clean, simple interface following iOS design guidelines
- **Tab-Based Navigation**:
  - Map tab
  - List tab
  - Settings tab
- **Responsive Layout**: Optimized for various iPhone models
- **Dark Mode Support**: Compatible with iOS dark mode

## 10. Performance & Technical Features
- **Efficient Image Handling**: Optimize image loading and processing
- **Background Processing**: Handle sync operations in background
- **Error Handling**: Graceful error handling with user feedback
- **Data Persistence**: Reliable local storage with Core Data
- **Camera Optimization**: Efficient camera preview and capture

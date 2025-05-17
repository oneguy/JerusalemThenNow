# Jerusalem Then & Now App - User Guide

## Overview

The Jerusalem Then & Now app is designed to help you capture modern photos from the same angles as historical images of Jerusalem. This guide will walk you through the app's features and how to use them effectively.

## Getting Started

### Installation
1. Open the Xcode project file (`JerusalemThenNow.xcodeproj`)
2. Connect your iPhone to your Mac
3. Select your device as the build target
4. Build and run the app on your device

### Firebase Setup (Optional)
The app comes with hardcoded Firebase credentials for simplicity. If you want to use your own Firebase account:
1. Create a new Firebase project at [firebase.google.com](https://firebase.google.com)
2. Add an iOS app to your Firebase project
3. Download the `GoogleService-Info.plist` file
4. Replace the existing file in the project with your downloaded file

## Main Features

### Map View
- **View Locations**: All saved locations appear as pins on the map
- **Color-Coded Pins**: 
  - Blue: Not visited locations
  - Green: Completed locations (photos taken)
  - Red: Inaccessible locations
- **Add New Location**: Long press on the map to add a new location
- **View Location Details**: Tap on a pin to view details about that location

### List View
- **View All Locations**: See all locations in a list format
- **Sort Options**: Sort by distance, status, or creation date
- **Quick Actions**: Swipe left on a location to access quick actions:
  - Change status (Not Visited, Completed, Inaccessible)
  - Delete location

### Location Details
- **View Historical Image**: See the historical image for the location
- **View New Image**: If you've taken a photo, view it alongside the historical image
- **Add Notes**: Add notes about the location for future reference
- **Change Status**: Mark the location as Not Visited, Completed, or Inaccessible
- **Open in Maps**: Open the location in Google Maps for navigation
- **Take Photo**: Open the camera interface to capture a new photo
- **Side-by-Side Comparison**: View historical and new images side by side
- **Delete Location**: Remove the location from the app

### Camera Interface
- **Historical Image Overlay**: See the historical image overlaid on the camera view
- **Adjust Opacity**: Slide to adjust the opacity of the overlay
- **Alignment Aids**: Choose from different alignment effects:
  - None: Standard overlay
  - Contrast: High contrast mode for better alignment
  - Edges: Edge detection for structural alignment
  - Grid: Grid overlay for composition
- **Zoom**: Pinch to zoom the camera view
- **Capture Photo**: Take a photo that matches the historical angle

### Settings
- **Image Quality**: Choose between High, Medium, or Low quality for captured photos
- **Sync Data**: Manually sync data to and from the Firebase server
- **Export Data**: Export all app data to a ZIP file containing:
  - CSV file with location information
  - Historical images
  - New images
  - Google Maps links

## Workflow

### Adding a New Location
1. Navigate to the Map tab
2. Long press on the desired location on the map
3. Enter a title for the location
4. Select a historical image from your photo library
5. The new location will appear as a blue pin on the map

### Capturing a New Photo
1. Navigate to a location via the Map or List view
2. Tap on the location to view details
3. Tap the "Camera" button
4. Use the overlay to align your shot with the historical image
5. Adjust the opacity slider as needed
6. Apply alignment effects if helpful
7. Capture the photo
8. Review the photo and save or retake
9. The location will be marked as completed (green)

### Viewing Comparisons
1. Navigate to a location with both historical and new images
2. Tap the "Side by Side" button
3. Use the slider to compare the images
4. Share the comparison if desired

### Exporting Data
1. Navigate to the Settings tab
2. Tap "Export Data"
3. Choose how you want to share the ZIP file
4. The ZIP contains all location data, images, and a CSV file

## Tips for Best Results
- Visit locations at similar times of day as the historical photos
- Consider weather conditions for the best matching shots
- Use the alignment aids to match architectural features
- Add detailed notes about each location for future reference
- Regularly sync your data to the server to prevent data loss

## Troubleshooting
- **Camera Not Working**: Check camera permissions in your device settings
- **Location Services Not Working**: Check location permissions in your device settings
- **Sync Issues**: Ensure you have an internet connection and try again
- **Image Quality Issues**: Change the image quality setting in the Settings tab

## Contact
For any questions or issues, please contact the developer.

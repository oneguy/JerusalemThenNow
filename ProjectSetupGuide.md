# Jerusalem Then & Now - Xcode Project Setup Guide

This guide will walk you through setting up the Jerusalem Then & Now app as a proper Xcode project. Follow these steps to create a working project with all the source files.

## Step 1: Create a New Xcode Project

1. Open Xcode
2. Select "Create a new Xcode project"
3. Choose "App" under iOS templates
4. Click "Next"
5. Enter the following details:
   - Product Name: JerusalemThenNow
   - Interface: Storyboard
   - Language: Swift
   - Organization Identifier: com.example (or your preferred identifier)
   - Uncheck "Use Core Data" (we'll add it manually)
   - Check "Include Tests" if you want to add tests later
6. Click "Next"
7. Choose a location to save your project
8. Click "Create"

## Step 2: Set Up Project Structure

Create the following folder structure in your project:

1. Right-click on the JerusalemThenNow folder in the Project Navigator
2. Select "New Group" and create the following groups:
   - Models
   - Views
   - Controllers
   - Services
   - Application (move AppDelegate.swift and SceneDelegate.swift here)
   - Resources (move Assets.xcassets here)

## Step 3: Add Source Files

Add all the Swift source files from the provided package to your project:

### Models
1. Right-click on the Models folder
2. Select "Add Files to 'JerusalemThenNow'..."
3. Navigate to the location where you extracted the source files
4. Select and add:
   - Location.swift
   - AppSettings.swift
   - LocationAnnotation.swift

### Views
1. Right-click on the Views folder
2. Select "Add Files to 'JerusalemThenNow'..."
3. Add:
   - LocationCell.swift

### Controllers
1. Right-click on the Controllers folder
2. Select "Add Files to 'JerusalemThenNow'..."
3. Add:
   - MapViewController.swift
   - LocationListViewController.swift
   - LocationDetailViewController.swift
   - CameraViewController.swift
   - SettingsViewController.swift
   - ComparisonViewController.swift
   - FullscreenImageViewController.swift
   - ImageReviewViewController.swift

### Services
1. Right-click on the Services folder
2. Select "Add Files to 'JerusalemThenNow'..."
3. Add:
   - DataManager.swift
   - FirebaseManager.swift
   - LocationManager.swift
   - CameraManager.swift

## Step 4: Set Up Core Data

1. Right-click on the JerusalemThenNow folder in the Project Navigator
2. Select "New File..."
3. Choose "Data Model" under the "Core Data" section
4. Name it "JerusalemThenNow"
5. Click "Create"
6. Open the data model file
7. Add a new Entity named "LocationEntity"
8. Add the following attributes to LocationEntity:
   - id: String
   - title: String
   - notes: String
   - latitude: Double
   - longitude: Double
   - status: String
   - historicalImagePath: String
   - historicalImageURL: String
   - newImagePath: String (optional)
   - newImageURL: String (optional)
   - createdAt: Date
   - updatedAt: Date

## Step 5: Set Up Firebase

1. If you don't already have Firebase set up:
   - Go to [firebase.google.com](https://firebase.google.com)
   - Create a new project
   - Add an iOS app to your project
   - Download the GoogleService-Info.plist file

2. Add Firebase to your project:
   - Drag the GoogleService-Info.plist file into your project
   - Make sure "Copy items if needed" is checked
   - Add to your main target

3. Install Firebase SDK:
   - In Xcode, select File > Add Packages...
   - Enter the Firebase iOS SDK URL: https://github.com/firebase/firebase-ios-sdk
   - Select the following Firebase products:
     - FirebaseFirestore
     - FirebaseStorage

## Step 6: Configure Info.plist

Add the following keys to your Info.plist file:

1. Right-click on Info.plist
2. Select "Open As" > "Source Code"
3. Add the following entries before the closing `</dict>` tag:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture modern photos that match historical images.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app needs location access to show your position relative to historical photo locations.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to save captured photos and import historical images.</string>
```

## Step 7: Set Up the Main Storyboard

1. Open Main.storyboard
2. Delete the default View Controller
3. Add a Tab Bar Controller as the initial view controller
4. Add three View Controllers connected to the Tab Bar Controller
5. Set the class of each View Controller:
   - First tab: MapViewController
   - Second tab: LocationListViewController
   - Third tab: SettingsViewController
6. Set the tab bar item titles and icons:
   - First tab: "Map" with map icon
   - Second tab: "List" with list icon
   - Third tab: "Settings" with gear icon
7. Add Navigation Controllers to each tab
8. Design the UI for each view controller according to the app's requirements

## Step 8: Create Additional Storyboard Scenes

Create the following additional view controllers in the storyboard:
1. LocationDetailViewController
2. CameraViewController
3. ComparisonViewController
4. FullscreenImageViewController
5. ImageReviewViewController

Connect them with appropriate segues from their parent view controllers.

## Step 9: Build and Run

1. Select your target device
2. Click the Run button or press Cmd+R
3. The app should build and run successfully

## Troubleshooting

If you encounter any issues:

1. **Build Errors**: Check that all files are added to the correct target
2. **Missing Dependencies**: Ensure Firebase is properly installed
3. **Permission Issues**: Verify that all required permissions are in Info.plist
4. **Storyboard Connections**: Check that all IBOutlets and IBActions are properly connected

## Next Steps

Once your project is set up and running:

1. Test all features to ensure they work as expected
2. Customize the UI to match your preferences
3. Add your own historical images of Jerusalem
4. Deploy to your device for field testing

## Additional Resources

- The provided UserGuide.md contains detailed information on how to use the app
- The AppArchitecture.md file explains the technical architecture of the app
- The FeatureList.md file outlines all the features implemented in the app

import Foundation
import AVFoundation
import UIKit
import CoreImage

enum AlignmentEffect {
    case none
    case highContrast
    case edgeDetection
    case gridOverlay
}

class CameraManager: NSObject {
    static let shared = CameraManager()
    
    private var captureSession: AVCaptureSession?
    private var videoDeviceInput: AVCaptureDeviceInput?
    private var photoOutput: AVCapturePhotoOutput?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var photoCaptureCompletionBlock: ((UIImage?, Error?) -> Void)?
    
    private override init() {
        super.init()
    }
    
    // MARK: - Camera Setup
    
    func setupCameraSession() -> Bool {
        captureSession = AVCaptureSession()
        
        guard let captureSession = captureSession else { return false }
        
        captureSession.beginConfiguration()
        
        // Set up video input
        guard let videoDevice = bestCamera() else {
            print("Could not find any suitable camera device")
            return false
        }
        
        do {
            videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput!) {
                captureSession.addInput(videoDeviceInput!)
            } else {
                print("Could not add video device input to the session")
                captureSession.commitConfiguration()
                return false
            }
        } catch {
            print("Could not create video device input: \(error)")
            captureSession.commitConfiguration()
            return false
        }
        
        // Set up photo output
        photoOutput = AVCapturePhotoOutput()
        photoOutput?.isHighResolutionCaptureEnabled = true
        
        if captureSession.canAddOutput(photoOutput!) {
            captureSession.addOutput(photoOutput!)
        } else {
            print("Could not add photo output to the session")
            captureSession.commitConfiguration()
            return false
        }
        
        captureSession.sessionPreset = .photo
        captureSession.commitConfiguration()
        
        return true
    }
    
    private func bestCamera() -> AVCaptureDevice? {
        if let device = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
            return device
        }
        if let device = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
            return device
        }
        return AVCaptureDevice.default(for: .video)
    }
    
    func setupPreviewLayer(in view: UIView) {
        guard let captureSession = captureSession else { return }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        
        if let previewLayer = previewLayer {
            view.layer.insertSublayer(previewLayer, at: 0)
        }
    }
    
    // MARK: - Camera Control
    
    func startCameraSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession?.startRunning()
        }
    }
    
    func stopCameraSession() {
        captureSession?.stopRunning()
    }
    
    func switchLens(zoomFactor: CGFloat) {
        guard let device = videoDeviceInput?.device else { return }
        
        do {
            try device.lockForConfiguration()
            
            // Check if the device supports zoom
            if device.isVirtualDevice {
                // For devices with multiple cameras, we can try to select the appropriate one
                // based on the zoom factor
                
                // This is a simplified implementation - in a real app, you would check
                // the available constituentDevices and select the appropriate one
                
                if zoomFactor <= 1.0 {
                    // Use wide angle if available
                    if let ultraWideCamera = AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) {
                        switchToDevice(ultraWideCamera)
                    }
                } else if zoomFactor <= 2.0 {
                    // Use standard wide camera
                    if let wideCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                        switchToDevice(wideCamera)
                    }
                } else {
                    // Use telephoto if available
                    if let telephotoCamera = AVCaptureDevice.default(.builtInTelephotoCamera, for: .video, position: .back) {
                        switchToDevice(telephotoCamera)
                    }
                }
            } else {
                // For single camera devices, just use zoom
                let maxZoom = device.activeFormat.videoMaxZoomFactor
                let clampedZoom = min(max(1.0, zoomFactor), maxZoom)
                device.videoZoomFactor = clampedZoom
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error setting zoom: \(error)")
        }
    }
    
    private func switchToDevice(_ device: AVCaptureDevice) {
        guard let captureSession = captureSession else { return }
        
        captureSession.beginConfiguration()
        
        // Remove existing input
        if let existingInput = videoDeviceInput {
            captureSession.removeInput(existingInput)
        }
        
        // Add new input
        do {
            let newInput = try AVCaptureDeviceInput(device: device)
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
                videoDeviceInput = newInput
            }
        } catch {
            print("Error creating device input: \(error)")
            if let existingInput = videoDeviceInput, captureSession.canAddInput(existingInput) {
                captureSession.addInput(existingInput)
            }
        }
        
        captureSession.commitConfiguration()
    }
    
    // MARK: - Photo Capture
    
    func capturePhoto(quality: ImageQuality, completion: @escaping (UIImage?, Error?) -> Void) {
        guard let photoOutput = photoOutput else {
            completion(nil, NSError(domain: "CameraManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Photo output not available"]))
            return
        }
        
        photoCaptureCompletionBlock = completion
        
        let settings = AVCapturePhotoSettings()
        
        // Configure photo quality
        settings.isHighResolutionPhotoEnabled = (quality == .high)
        
        // Set flash mode
        if videoDeviceInput?.device.isFlashAvailable == true {
            settings.flashMode = .auto
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // MARK: - Image Effects
    
    func applyOverlay(historicalImage: UIImage, opacity: Float) -> UIImage? {
        guard let currentFrame = getCurrentFrame() else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(currentFrame.size, false, 0.0)
        
        // Draw current frame
        currentFrame.draw(in: CGRect(origin: .zero, size: currentFrame.size))
        
        // Draw historical image with opacity
        historicalImage.draw(in: CGRect(origin: .zero, size: currentFrame.size), blendMode: .normal, alpha: CGFloat(opacity))
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImage
    }
    
    func applyAlignmentEffect(effect: AlignmentEffect, to image: UIImage) -> UIImage? {
        switch effect {
        case .none:
            return image
            
        case .highContrast:
            return applyHighContrast(to: image)
            
        case .edgeDetection:
            return applyEdgeDetection(to: image)
            
        case .gridOverlay:
            return applyGrid(to: image)
        }
    }
    
    private func applyHighContrast(to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIColorControls")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.5, forKey: kCIInputContrastKey) // Increase contrast
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgOutputImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgOutputImage)
    }
    
    private func applyEdgeDetection(to image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter(name: "CIEdges")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(5.0, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter?.outputImage else { return nil }
        
        let context = CIContext()
        guard let cgOutputImage = context.createCGImage(outputImage, from: outputImage.extent) else { return nil }
        
        return UIImage(cgImage: cgOutputImage)
    }
    
    private func applyGrid(to image: UIImage) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(image.size, false, 0.0)
        
        // Draw the original image
        image.draw(in: CGRect(origin: .zero, size: image.size))
        
        // Draw grid lines
        let context = UIGraphicsGetCurrentContext()
        context?.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        context?.setLineWidth(1.0)
        
        // Draw horizontal lines
        let horizontalSpacing = image.size.height / 3
        for i in 1...2 {
            let y = horizontalSpacing * CGFloat(i)
            context?.move(to: CGPoint(x: 0, y: y))
            context?.addLine(to: CGPoint(x: image.size.width, y: y))
        }
        
        // Draw vertical lines
        let verticalSpacing = image.size.width / 3
        for i in 1...2 {
            let x = verticalSpacing * CGFloat(i)
            context?.move(to: CGPoint(x: x, y: 0))
            context?.addLine(to: CGPoint(x: x, y: image.size.height))
        }
        
        context?.strokePath()
        
        let resultImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resultImage
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentFrame() -> UIImage? {
        guard let previewLayer = previewLayer else { return nil }
        
        UIGraphicsBeginImageContextWithOptions(previewLayer.frame.size, false, 0.0)
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        previewLayer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image
    }
}

// MARK: - AVCapturePhotoCaptureDelegate

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            photoCaptureCompletionBlock?(nil, error)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            photoCaptureCompletionBlock?(nil, NSError(domain: "CameraManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not create image from photo data"]))
            return
        }
        
        photoCaptureCompletionBlock?(image, nil)
    }
}

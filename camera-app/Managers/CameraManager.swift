//
//  CameraManager.swift
//  camera-app
//
//  Created by Kerem Uslular on 15.08.2024.
//

import Foundation
import AVFoundation
import UIKit

class CameraManager: NSObject {
    var captureSession: AVCaptureSession?
    
    let photoOutput = AVCapturePhotoOutput()
    let captureQueue = DispatchQueue(label: "com.camera.captureQueue", qos: .userInitiated)
    
    var captureTimer: Timer?
    var isPaused = false
    var elapsedTime: TimeInterval = 0
    var maxCaptureDuration: TimeInterval = 60
    var startTime: Date?
    
    let targetDimention = CMVideoDimensions(width: 3000, height: 4000)
    
    // MARK: - Session Functions
    
    func setupSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else {
            AlertUtility.show(title: "Capture Session Error", message: "Failed to create capture session.")
            return
        }
        
        captureSession.sessionPreset = .high

        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            AlertUtility.show(title: "Camera Error", message: "Failed to get the default camera.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                AlertUtility.show(title: "Input Error", message: "Failed to add camera input to capture session.")
                return
            }
            
            if captureSession.canAddOutput(photoOutput) {
                captureSession.addOutput(photoOutput)
                photoOutput.isHighResolutionCaptureEnabled = true
                photoOutput.maxPhotoQualityPrioritization = .speed
                if #available(iOS 16.0, *) {
                    let supportedDimensions = camera.activeFormat.supportedMaxPhotoDimensions
                    
                    // Choose closest to targetDimention
                    let desiredDimensions = targetDimention
                    if let closestMatch = supportedDimensions.min(by: {
                        abs($0.width - desiredDimensions.width) + abs($0.height - desiredDimensions.height) <
                        abs($1.width - desiredDimensions.width) + abs($1.height - desiredDimensions.height)
                    }) {
                        photoOutput.maxPhotoDimensions = closestMatch
                        print("Set maxPhotoDimensions to: \(closestMatch.width)x\(closestMatch.height)")
                    }
                }
            } else {
                AlertUtility.show(title: "Output Error", message: "Failed to add photo output to capture session.")
                return
            }
        } catch {
            AlertUtility.show(title: "Setup Error", message: "Error setting up camera input: \(error.localizedDescription)")
            return
        }
    }
    
    func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            completion(true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                completion(granted)
            }
        case .denied, .restricted:
            let settingsAction = UIAlertAction(title: "Settings", style: .default) { _ in
                guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
                if UIApplication.shared.canOpenURL(settingsURL) {
                    UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
                }
            }
            AlertUtility.show(
                title: "Camera Access Required",
                message: "This app requires access to the camera. Please enable camera permissions in settings.",
                actions: [settingsAction]
            )
            completion(false)
        @unknown default:
            fatalError("Unknown authorization status for camera access.")
        }
    }
    
    func startSession() {
        guard let captureSession = captureSession else { return }
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .background).async {
                self.captureSession?.startRunning()
            }
        }
    }
    
    func stopSession() {
        guard let captureSession = captureSession else { return }
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
    
    // MARK: - Capture Functions
    
    func startCapturing() {
        guard captureTimer == nil else { return }
        
        startTime = Date()
        captureTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(capturePhoto), userInfo: nil, repeats: true)
        scheduleCaptureStop()
    }
    
    func scheduleCaptureStop() {
        let remainingTime = maxCaptureDuration - elapsedTime
        DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
            self.stopCapturing()
        }
    }
    
    func stopCapturing() {
        captureTimer?.invalidate()
        captureTimer = nil
        isPaused = false
        elapsedTime = 0
    }
    
    func pauseUnpauseCapturing() {
        if isPaused {
            startCapturing()
        } else {
            captureTimer?.invalidate()
            captureTimer = nil
            if let startTime = startTime {
                elapsedTime += Date().timeIntervalSince(startTime)
            }
        }
        isPaused.toggle()
    }
    
    @objc func capturePhoto() {
        let settings: AVCapturePhotoSettings

        if #available(iOS 16.0, *) {
            settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        } else {
            settings = AVCapturePhotoSettings()
        }

        settings.isHighResolutionPhotoEnabled = true
                
        // Capture photo in the background
        captureQueue.async {
            self.photoOutput.capturePhoto(with: settings, delegate: self)
        }
    }
    
    // MARK: - Storage Functions
    func saveImageToDisk(_ imageData: Data) {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let fileName = "IMG_\(UUID().uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            print("Image saved to: \(fileURL)")
        } catch {
            print("Error saving image: \(error)")
        }
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        if let image = UIImage(data: imageData) {
            print("Captured image resolution: \(image.size.width)x\(image.size.height)")
        }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.saveImageToDisk(imageData)
        }
    }
}

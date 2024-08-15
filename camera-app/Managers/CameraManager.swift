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
    
    var captureTimer: Timer?
    var isPaused = false
    var elapsedTime: TimeInterval = 0
    var maxCaptureDuration: TimeInterval = 60
    var startTime: Date?
    
    func setupSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else {
            AlertUtility.show(title: "Capture Session Error", message: "Failed to create capture session.")
            return
        }
        
        captureSession.sessionPreset = .photo
        
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
            setupSession()
            completion(true)
            
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if granted {
                    self.setupSession()
                }
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
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.saveImageToDisk(imageData)
        }
    }
    
    // TODO: Implement image storage logic
    // Temporarily adds images to files in device
    func saveImageToDisk(_ imageData: Data) {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let fileName = "IMG_\(UUID().uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            if let image = UIImage(data: imageData), let resizedImage = image.resized(to: CGSize(width: 4000, height: 3000)), let resizedImageData = resizedImage.jpegData(compressionQuality: 1.0) {
                try resizedImageData.write(to: fileURL)
                print("Image saved to: \(fileURL)")
            } else {
                print("Failed to resize the image.")
            }
        } catch {
            print("Error saving image: \(error)")
        }
    }
}

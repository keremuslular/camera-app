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
        captureSession?.startRunning()
    }
    
    func stopSession() {
        captureSession?.stopRunning()
    }
    
    func startCapturing() {
        captureTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(capturePhoto), userInfo: nil, repeats: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 60) {
            self.stopCapturing()
        }
    }
    
    func stopCapturing() {
        captureTimer?.invalidate()
        captureTimer = nil
    }
    
    @objc func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        saveImage(with: imageData)
    }
    
    func saveImage(with imageData: Data) {
        let fileManager = FileManager.default
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let fileName = "IMG_\(UUID().uuidString).jpg"
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: fileURL)
            AlertUtility.show(title: "Image Saved", message: "Image saved to: \(fileURL)")
        } catch {
            AlertUtility.show(title: "Save Error", message: "Error saving image: \(error)")
        }
    }
}

//
//  CameraManager.swift
//  camera-app
//
//  Created by Kerem Uslular on 15.08.2024.
//

import Foundation
import AVFoundation
import UIKit

protocol CameraManagerDelegate: NSObjectProtocol {
    func cameraManagerDidCapture(_: CameraManager)
}

class CameraManager: NSObject {
    weak var delegate: CameraManagerDelegate?
    
    var camera: AVCaptureDevice?
    var captureSession: AVCaptureSession?
    
    let photoOutput = AVCapturePhotoOutput()
    let captureQueue = DispatchQueue(label: "com.camera.captureQueue", qos: .userInitiated)
    
    var captureTimer: Timer?
    var isPaused = false
    var elapsedTime: TimeInterval = 0
    var startTime: Date?
    
    let preferredDimensions = CMVideoDimensions(width: 3000, height: 4000)
    let preferredCameraTypes: [AVCaptureDevice.DeviceType] = [
        .builtInTripleCamera,
        .builtInDualCamera
    ]
    
    override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(applicaitonWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIApplication.willTerminateNotification, object: nil)
    }
    
    // MARK: - Camera Setup
    
    func setupCamera() -> AVCaptureDevice? {
        for cameraType in preferredCameraTypes {
            if let camera = AVCaptureDevice.default(cameraType, for: .video, position: .back) {
                if !camera.isExposureModeSupported(.custom) {
                    print("Camera \(cameraType.rawValue) does not support custom exposure mode.")
                    continue
                }
                
                var closestFormat: AVCaptureDevice.Format?
                var closestDifference: Int32 = .max
                
                for format in camera.formats {
                    let description = format.formatDescription
                    let dimensions = CMVideoFormatDescriptionGetDimensions(description)
                    
                    let widthDifference = abs(dimensions.width - preferredDimensions.width)
                    let heightDifference = abs(dimensions.height - preferredDimensions.height)
                    let totalDifference = widthDifference + heightDifference
                    
                    if totalDifference < closestDifference {
                        closestDifference = totalDifference
                        closestFormat = format
                    }
                }
                
                if let bestFormat = closestFormat {
                    do {
                        try camera.lockForConfiguration()
                        camera.activeFormat = bestFormat
                        camera.unlockForConfiguration()
                        return camera
                    } catch {
                        print("Error setting camera format: \(error)")
                    }
                } else {
                    print("No suitable format found for \(cameraType.rawValue)")
                }
            } else {
                print("Device does not suppport \(cameraType.rawValue)")
            }
        }
        
        // Fall back to the default wide-angle camera
        return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
    }
    
    func setISO(_ iso: Float?, completion: @escaping (Result<Float?, Error>) -> Void) {
        guard let camera = camera else {
            completion(.failure(CameraError.cameraUnavailable))
            return
        }
        
        do {
            if let iso = iso {
                let clampedISO = max(camera.activeFormat.minISO, min(iso, camera.activeFormat.maxISO))
                try setExposureMode(iso: clampedISO)
                completion(.success(clampedISO))
            } else {
                try camera.lockForConfiguration()
                camera.exposureMode = .continuousAutoExposure
                camera.unlockForConfiguration()
                completion(.success(nil))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func setShutterSpeed(_ shutterSpeed: Int?, completion: @escaping (Result<Int?, Error>) -> Void) {
        guard let camera = camera else {
            completion(.failure(CameraError.cameraUnavailable))
            return
        }
        
        do {
            if let shutterSpeed = shutterSpeed  {
                let exposureDuration = CMTimeMake(value: 1, timescale: Int32(shutterSpeed))
                let clampedISO = max(camera.activeFormat.minISO, min(camera.iso, camera.activeFormat.maxISO))
                try setExposureMode(duration: exposureDuration, iso: clampedISO)
                completion(.success(shutterSpeed))
            } else {
                try camera.lockForConfiguration()
                camera.exposureMode = .continuousAutoExposure
                camera.unlockForConfiguration()
                completion(.success(nil))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func setExposureMode(duration: CMTime? = nil, iso: Float? = nil) throws {
        guard let camera = camera else {
            throw CameraError.cameraUnavailable
        }

        if camera.isExposureModeSupported(.custom) {
            do {
                try camera.lockForConfiguration()
                camera.setExposureModeCustom(duration: duration ?? camera.exposureDuration, iso: iso ?? camera.iso)
                camera.unlockForConfiguration()
            } catch {
                camera.unlockForConfiguration()
                throw CameraError.configurationFailed
            }
        } else {
            throw CameraError.unsupportedExposureMode
        }
    }
    
    // MARK: - Session Setup
    
    func setupSession() {
        captureSession = AVCaptureSession()
        guard let captureSession = captureSession else {
            AlertUtility.show(title: "Capture Session Error", message: "Failed to create capture session.")
            return
        }
        
        camera = setupCamera()
        
        guard let camera = camera else {
            AlertUtility.show(title: "Camera Error", message: "Failed to get the camera.")
            return
        }
        
        do {
            captureSession.sessionPreset = .photo

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
    
    @objc func applicaitonWillTerminate() {
        stopCapturing()
        StorageManager.shared.deleteAll()
    }
    
    func getSupportedISOs() -> [Float] {
        guard let camera = camera else { return [] }
        
        let minISO = camera.activeFormat.minISO
        let maxISO = camera.activeFormat.maxISO
        
        var isoValues: [Float] = []
        var currentISO = minISO
        
        while currentISO <= maxISO {
            isoValues.append(currentISO)
            currentISO *= 2
        }
        
        if !isoValues.contains(maxISO) {
            isoValues.append(maxISO)
        }
        
        return isoValues
    }
    
    func getSupportedShutterSpeeds() -> [Double] {
        guard let camera = camera else {
            return []
        }
        let minDuration = camera.activeFormat.minExposureDuration.seconds
        let maxDuration = camera.activeFormat.maxExposureDuration.seconds
        let speedSteps: [Double] = [1/1000, 1/500, 1/250, 1/125, 1/60, 1/30, 1/15, 1/8, 1/4] // Common shutter speeds
        
        return speedSteps.filter { $0 >= minDuration && $0 <= maxDuration }
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
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            StorageManager.shared.save(with: imageData)
        }
        delegate?.cameraManagerDidCapture(self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        AudioServicesDisposeSystemSoundID(1108)
    }
}

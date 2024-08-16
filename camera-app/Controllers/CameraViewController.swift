//
//  CameraViewController.swift
//  camera-app
//
//  Created by Kerem Uslular on 15.08.2024.
//

import Foundation
import UIKit
import SnapKit
import AVFoundation

class CameraViewController: UIViewController {
    let previewView = UIView()
    let captureButton = UIButton(type: .system)
    
    let cameraManager = CameraManager()
    var isCapturing = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestCameraAccessAndStartSession()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraManager.stopSession()
    }
    
    func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(previewView)
        previewView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        captureButton.setTitle("Start Capture", for: .normal)
        captureButton.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        view.addSubview(captureButton)
        captureButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
            make.centerX.equalToSuperview()
            make.width.equalTo(200)
            make.height.equalTo(50)
        }
    }
    
    func requestCameraAccessAndStartSession() {
        cameraManager.requestCameraPermission { [weak self] granted in
            guard granted else { return }
            self?.setupCameraSession()
        }
    }
    
    func setupCameraSession() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.cameraManager.setupSession()
            
            let previewLayer = AVCaptureVideoPreviewLayer(session: self.cameraManager.captureSession!)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = self.previewView.bounds
            self.previewView.layer.addSublayer(previewLayer)
            
            self.cameraManager.startSession()
        }
    }
    
    @objc func captureButtonTapped() {
        if isCapturing {
            cameraManager.pauseUnpauseCapturing()
            updateCaptureButtonTitle()
        } else {
            cameraManager.startCapturing()
            isCapturing = true
            updateCaptureButtonTitle()
        }
    }
    
    func updateCaptureButtonTitle() {
        if cameraManager.isPaused {
            captureButton.setTitle("Resume Capture", for: .normal)
        } else {
            captureButton.setTitle(isCapturing ? "Pause Capture" : "Start Capture", for: .normal)
        }
    }
}


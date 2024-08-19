//
//  CameraViewController.swift
//  camera-app
//
//  Created by Kerem Uslular on 15.08.2024.
//

import Foundation
import UIKit
import AVFoundation

class CameraViewController: UIViewController {
    let previewView: UIView = {
        let view = UIView()
        view.cornerRadius(radius: 5.0)
        view.border(width: 1.0, color: .white.withAlphaComponent(0.5))
        return view
    }()
    
    let latestImageView: UIImageView = {
        let iv = UIImageView()
        iv.cornerRadius(radius: 5.0)
        iv.border(width: 1.0, color: .white.withAlphaComponent(0.5))
        iv.contentMode = .scaleAspectFill
        iv.isHidden = true
        return iv
    }()
    
    lazy var timerView: CaptureTimerView = {
        let timer = CaptureTimerView()
        navigationItem.titleView = timer
        return timer
    }()
    
    lazy var isoButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "ISO: AUTO", style: .plain, target: self, action: #selector(isoButtonTapped))
        btn.setTitleTextAttributes([.font: UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium), .foregroundColor: UIColor.white], for: .normal)
        return btn
    }()
    
    lazy var shutterSpeedButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "Shutter: AUTO", style: .plain, target: self, action: #selector(shutterSpeedButtonTapped))
        btn.setTitleTextAttributes([.font: UIFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium), .foregroundColor: UIColor.white], for: .normal)
        return btn
    }()
    
    lazy var captureButton: CaptureButton = {
        let btn = CaptureButton()
        btn.addTarget(self, action: #selector(captureButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    lazy var infoButton: ImageTitleButton = {
        let btn = ImageTitleButton()
        btn.type = .info
        btn.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    lazy var resetButton: ImageTitleButton = {
        let btn = ImageTitleButton()
        btn.type = .reset
        btn.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    lazy var cameraManager: CameraManager = {
        let manager = CameraManager()
        manager.delegate = self
        return manager
    }()
    
    var isCapturing = false
    var didAppearOnce = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        requestCameraAccessAndStartSession()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if didAppearOnce {
            cameraManager.startSession()
        }
        didAppearOnce = true
        if !latestImageView.isHidden {
            latestImageView.image = StorageManager.shared.getLatestImage()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        cameraManager.stopSession()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        [previewView, latestImageView, captureButton, infoButton, resetButton].forEach(view.addSubview)
        
        previewView.snp.makeConstraints { make in
            make.leading.trailing.centerX.centerY.equalToSuperview()
            make.height.equalTo(previewView.snp.width).multipliedBy(4.0 / 3.0)
        }
        
        latestImageView.snp.makeConstraints { make in
            make.edges.equalTo(previewView)
        }
        
        captureButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20.0)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(80.0)
        }
        
        infoButton.snp.makeConstraints { make in
            make.centerY.equalTo(captureButton)
            make.leading.equalToSuperview().inset(40.0)
            make.width.equalTo(40.0)
        }
        
        resetButton.snp.makeConstraints { make in
            make.centerY.equalTo(captureButton)
            make.trailing.equalToSuperview().inset(40.0)
            make.width.equalTo(40.0)
        }
        
        timerView.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(150.0)
            make.height.equalTo(40)
        }
        
        navigationItem.leftBarButtonItem = isoButton
        navigationItem.rightBarButtonItem = shutterSpeedButton
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
            if cameraManager.isPaused {
                captureButton.captureState = .paused
                timerView.pauseTimer()
                latestImageView.isHidden = false
                latestImageView.image = StorageManager.shared.getLatestImage()
            } else {
                captureButton.captureState = .capturing
                timerView.startTimer()
                latestImageView.isHidden = true
            }
        } else {
            latestImageView.isHidden = true
            cameraManager.startCapturing()
            captureButton.captureState = .capturing
            timerView.startTimer()
            isCapturing = true
        }
    }
    
    @objc func isoButtonTapped() {
        let alertController = UIAlertController(title: "Select ISO", message: nil, preferredStyle: .actionSheet)
        let isoValues = ["AUTO"] + cameraManager.getSupportedISOs().map { "ISO \(Int($0))" }

        isoValues.forEach { iso in
            alertController.addAction(UIAlertAction(title: iso, style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                if iso == "AUTO" {
                    self.cameraManager.ISO = nil
                    self.isoButton.title = "ISO: AUTO"
                    self.shutterSpeedButton.title = "Shutter: AUTO"
                } else if let isoValue = Float(iso.replacingOccurrences(of: "ISO ", with: "")) {
                    self.cameraManager.ISO = isoValue
                    self.isoButton.title = "ISO: \(Int(isoValue))"
                }
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func shutterSpeedButtonTapped() {
        let alertController = UIAlertController(title: "Select Shutter Speed", message: nil, preferredStyle: .actionSheet)
        let shutterSpeeds = ["AUTO"] + cameraManager.getSupportedShutterSpeeds().map { "1/\(Int(1/$0)) sec" }

        shutterSpeeds.forEach { speed in
            alertController.addAction(UIAlertAction(title: speed, style: .default, handler: { [weak self] _ in
                guard let self = self else { return }
                if speed == "AUTO" {
                    self.cameraManager.shutterSpeed = nil
                    self.isoButton.title = "ISO: AUTO"
                    self.shutterSpeedButton.title = "Shutter: AUTO"
                } else if let speedValue = Double(speed.replacingOccurrences(of: "1/", with: "").replacingOccurrences(of: " sec", with: "")) {
                    self.cameraManager.shutterSpeed = speedValue
                    self.shutterSpeedButton.title = "Shutter: 1/\(Int(speedValue))"
                }
            }))
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    @objc func infoButtonTapped() {
        if isCapturing {
            if !cameraManager.isPaused {
                cameraManager.pauseUnpauseCapturing()
                captureButton.captureState = .paused
                timerView.pauseTimer()
                latestImageView.isHidden = false
                latestImageView.image = StorageManager.shared.getLatestImage()
            }
        }
        let infoViewController = InfoViewController()
        infoViewController.recordingTime = cameraManager.elapsedTime
        navigationController?.pushViewController(infoViewController, animated: true)
    }
    
    @objc func resetButtonTapped() {
        cameraManager.stopCapturing()
        StorageManager.shared.deleteAll()
        
        timerView.resetTimer()
        captureButton.captureState = .initial
        infoButton.captureCount = 0
        isCapturing = false
        latestImageView.isHidden = true
        latestImageView.image = nil
        isoButton.title = "ISO: AUTO"
        shutterSpeedButton.title = "Shutter: AUTO"
    }
}

extension CameraViewController: CameraManagerDelegate {
    func cameraManagerDidCapture(_: CameraManager) {
        previewView.pulseBorder(for: 0.1, from: .white.withAlphaComponent(0.2))
        infoButton.increaseCaptureCount()
    }
}

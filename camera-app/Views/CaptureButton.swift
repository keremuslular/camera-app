//
//  CaptureButton.swift
//  camera-app
//
//  Created by Kerem Uslular on 16.08.2024.
//

import Foundation
import UIKit
import SnapKit

class CaptureButton: UIButton {
    enum CaptureState {
        case initial
        case capturing
        case paused
    }
    
    var captureState: CaptureState = .initial {
        didSet {
            switch captureState {
            case .initial:
                reset()
            case .capturing:
                start()
            case .paused:
                pause()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI() {
        cornerRadius(radius: 40.0)
        border(width: 5.0, color: .white)
        backgroundColor = .clear
    }
    
    func start() {
        UIView.animate(withDuration: 0.2) {
            self.backgroundColor = .red
            self.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        let pulseAnimation: CABasicAnimation = {
            let anim = CABasicAnimation(keyPath: "transform.scale")
            anim.duration = 1.0
            anim.fromValue = 1.1
            anim.toValue = 1.0
            anim.autoreverses = true
            anim.repeatCount = .infinity
            return anim
        }()
        layer.add(pulseAnimation, forKey: "pulse")
    }
    
    func pause() {
        layer.removeAllAnimations()
        UIView.animate(withDuration: 0.2) {
            self.backgroundColor = .lightGray
            self.transform = CGAffineTransform.identity
        }
    }
    
    func reset() {
        layer.removeAllAnimations()
        UIView.animate(withDuration: 0.2) {
            self.backgroundColor = .clear
            self.transform = CGAffineTransform.identity
        }
    }
}

//
//  UIViewExtension.swift
//  camera-app
//
//  Created by Kerem Uslular on 15.08.2024.
//

import UIKit

extension UIView {
    func cornerRadius(radius: CGFloat, corners: CACornerMask = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMaxYCorner]) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
        layer.maskedCorners = corners
    }

    func border(width: CGFloat, color: UIColor) {
        layer.borderWidth = width
        layer.borderColor = color.cgColor
    }
    
    func pulseBorder(for duration: TimeInterval, from: UIColor? = nil, to: UIColor? = nil) {
        let initialColor = layer.borderColor
        UIView.animate(withDuration: duration / 2, animations: {
            if let color = from {
                self.layer.borderColor = color.cgColor
            } else {
                self.layer.borderColor = UIColor.clear.cgColor
            }
        }) { _ in
            UIView.animate(withDuration: duration / 2) {
                if let color = to {
                    self.layer.borderColor = color.cgColor
                } else {
                    self.layer.borderColor = initialColor
                }
            }
        }
    }
}

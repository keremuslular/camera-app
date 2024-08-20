//
//  CameraError.swift
//  camera-app
//
//  Created by Kerem Uslular on 20.08.2024.
//

import Foundation

enum CameraError: Error {
    case cameraUnavailable
    case unsupportedExposureMode
    case configurationFailed
}

extension CameraError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .cameraUnavailable:
            return NSLocalizedString(
                "The camera is unavailable. Make sure your device's camera is working properly.",
                comment: "Camera unavailable error"
            )
        case .unsupportedExposureMode:
            return NSLocalizedString(
                "Your device does not support custom exposure settings. The camera will automatically adjust the ISO and shutter speed for optimal exposure.",
                comment: "Unsupported exposure mode error"
            )
        case .configurationFailed:
            return NSLocalizedString(
                "Failed to configure the camera. Please try again.",
                comment: "Configuration failed error"
            )
        }
    }
}

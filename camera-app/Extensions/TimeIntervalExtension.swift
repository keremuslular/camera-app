//
//  TimeIntervalExtension.swift
//  camera-app
//
//  Created by Kerem Uslular on 19.08.2024.
//

import Foundation

extension TimeInterval {
    func asTimerText() -> String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

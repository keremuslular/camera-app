//
//  DateExtension.swift
//  camera-app
//
//  Created by Kerem Uslular on 17.08.2024.
//

import Foundation

extension Date {
    func formattedString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy, HH:mm"
        return formatter.string(from: self)
    }
}

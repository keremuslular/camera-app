//
//  Capture.swift
//  camera-app
//
//  Created by Kerem Uslular on 17.08.2024.
//

import UIKit

struct Capture {
    let fileURL: URL
    let name: String
    let dimensions: CGSize
    let timestamp: Date
    
    init?(fileURL: URL) {
        guard let image = UIImage(contentsOfFile: fileURL.path) else { return nil }
        self.fileURL = fileURL
        self.name = fileURL.lastPathComponent
        self.dimensions = CGSize(width: image.size.width, height: image.size.height)
        
        if let attributes = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
           let creationDate = attributes[.creationDate] as? Date {
            self.timestamp = creationDate
        } else {
            self.timestamp = Date()
        }
    }
}

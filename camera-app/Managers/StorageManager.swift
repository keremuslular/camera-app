//
//  StorageManager.swift
//  camera-app
//
//  Created by Kerem Uslular on 17.08.2024.
//

import Foundation
import UIKit

class StorageManager {
    static let shared = StorageManager()
    
    var documentsDirectory: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    func imagePath(for fileName: String) -> URL {
        return documentsDirectory.appendingPathComponent(fileName)
    }
    
    func get(named fileName: String) -> Capture? {
        let fileURL = imagePath(for: fileName)
        
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            print("No image found at path: \(fileURL)")
            return nil
        }
        return Capture(fileURL: fileURL)
    }
    
    @discardableResult
    func save(with imageData: Data) -> Capture? {
        let fileName = "IMG_\(UUID().uuidString).jpg"
        let fileURL = imagePath(for: fileName)
        
        do {
            try imageData.write(to: fileURL)
            return Capture(fileURL: fileURL)
        } catch {
            print("Error saving image: \(error)")
        }
        return nil
    }
    
    @discardableResult
    func delete(named fileName: String) -> Bool {
        let fileURL = imagePath(for: fileName)
        
        do {
            try FileManager.default.removeItem(at: fileURL)
            return true
        } catch {
            print("Error deleting image: \(error)")
            return false
        }
    }
    
    func getLatestImage() -> UIImage? {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            if let latestFileURL = fileURLs.sorted(by: {
                let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }).first {
                return UIImage(contentsOfFile: latestFileURL.path)
            }
        } catch {
            print("Error retrieving the latest image: \(error)")
        }
        
        return nil
    }
    
    func getAll() -> [Capture] {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: [.creationDateKey], options: [])
            
            return fileURLs.sorted(by: {
                let date1 = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2 // Most recent first
            }).compactMap { get(named: $0.lastPathComponent) }
            
        } catch {
            print("Error retrieving captures: \(error)")
            return []
        }
    }
    
    func deleteAll() {
        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil, options: [])
            
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
            
        } catch {
            print("Error deleting all images: \(error)")
        }
    }
}

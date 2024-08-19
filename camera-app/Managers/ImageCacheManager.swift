//
//  ImageCacheManager.swift
//  camera-app
//
//  Created by Kerem Uslular on 19.08.2024.
//

import Foundation
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()
    
    var cache = NSCache<NSURL, UIImage>()
    
    func loadImage(from url: URL, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        if let cachedImage = cache.object(forKey: url as NSURL) {
            completion(cachedImage)
            return
        }
        
        DispatchQueue.global(qos: .background).async {
            let downsampledImage = self.downsampleImage(from: url, to: targetSize)
            if let image = downsampledImage {
                self.cache.setObject(image, forKey: url as NSURL)
            }
            DispatchQueue.main.async {
                completion(downsampledImage)
            }
        }
    }
    
    private func downsampleImage(from url: URL, to targetSize: CGSize) -> UIImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, imageSourceOptions) else { return nil }
        
        let maxDimensionInPixels = max(targetSize.width, targetSize.height) * UIScreen.main.scale
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as CFDictionary
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else { return nil }
        return UIImage(cgImage: downsampledImage)
    }
}

//
//  UIImageExtension.swift
//  camera-app
//
//  Created by Kerem Uslular on 15.08.2024.
//

import UIKit

extension UIImage {
    func resized(to targetSize: CGSize) -> UIImage? {
        let size = self.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        let scaleFactor = max(widthRatio, heightRatio)

        let scaledImageSize = CGSize(width: size.width * scaleFactor, height: size.height * scaleFactor)

        UIGraphicsBeginImageContextWithOptions(targetSize, false, 1.0)
        let thumbnailRect = CGRect(
            origin: .zero,
            size: scaledImageSize
        ).integral
        self.draw(in: thumbnailRect)

        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage
    }
}

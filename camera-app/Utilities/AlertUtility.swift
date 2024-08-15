//
//  AlertUtility.swift
//  camera-app
//
//  Created by Kerem Uslular on 15.08.2024.
//

import Foundation
import UIKit

class AlertUtility {
    static func show(title: String, message: String, actions: [UIAlertAction] = []) {
        guard let topViewController = topMostViewController() else { return }

        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        actions.forEach(alert.addAction(_:))
        topViewController.present(alert, animated: true, completion: nil)
    }
}

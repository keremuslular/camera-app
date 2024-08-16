//
//  TopViewControllerUtility.swift
//  camera-app
//
//  Created by Kerem Uslular on 15.08.2024.
//

import UIKit

func topMostViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes
    let windowScene = scenes.first as? UIWindowScene

    let keyWindow = windowScene?.windows.first { $0.isKeyWindow }

    var topController = keyWindow?.rootViewController
    while let presentedController = topController?.presentedViewController {
        topController = presentedController
    }
    return topController
}

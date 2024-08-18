//
//  CapturePreviewViewController.swift
//  camera-app
//
//  Created by Kerem Uslular on 17.08.2024.
//

import Foundation
import UIKit

protocol CapturePreviewViewControllerDelegate: NSObjectProtocol {
    func capturePreviewViewController(_ viewController: CapturePreviewViewController, didDelete capture: Capture)
}

class CapturePreviewViewController: UIViewController {
    lazy var imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.cornerRadius(radius: 10.0)
        iv.border(width: 1.0, color: .white)
        return iv
    }()
    
    lazy var infoButton: UIButton = {
        let btn = UIButton(type: .infoLight)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    var capture: Capture? {
        didSet {
            guard let capture = capture else { return }
            imageView.image = capture.image
            imageView.snp.makeConstraints { make in
                make.height.equalTo(imageView.snp.width).multipliedBy(capture.dimensions.height / capture.dimensions.width)
            }
        }
    }
    
    weak var delegate: CapturePreviewViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        [imageView, infoButton].forEach(view.addSubview)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(50.0)
        }
        
        infoButton.snp.makeConstraints { make in
            make.top.equalTo(imageView).offset(10.0)
            make.trailing.equalTo(imageView).offset(-10.0)
            make.width.height.equalTo(30.0)
        }
    }
    
    @objc func infoButtonTapped() {
        guard let capture = capture else { return }
        let alertController = UIAlertController(
            title: capture.name,
            message: "Dimensions: \(Int(capture.dimensions.width))x\(Int(capture.dimensions.height))\nDate: \(capture.timestamp.formattedString())",
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.delegate?.capturePreviewViewController(self, didDelete: capture)
        }
        alertController.addAction(deleteAction)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alertController.addAction(dismissAction)
        
        alertController.modalPresentationStyle = .popover
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = infoButton
            popoverController.sourceRect = infoButton.bounds
            popoverController.permittedArrowDirections = .any
        }
        
        present(alertController, animated: true, completion: nil)
    }
}

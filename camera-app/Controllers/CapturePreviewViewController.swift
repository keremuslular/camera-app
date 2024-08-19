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
    
    let infoLabel: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.textAlignment = .center
        return lbl
    }()
    
    lazy var deleteButton: UIButton = {
        let btn = UIButton()
        btn.cornerRadius(radius: 10.0)
        btn.border(width: 1.0, color: .white)
        btn.backgroundColor = .red.withAlphaComponent(0.5)
        btn.setTitle("Delete", for: .normal)
        btn.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    var capture: Capture? {
        didSet {
            guard let capture = capture else { return }
            imageView.image = capture.image
            imageView.snp.makeConstraints { make in
                make.height.equalTo(imageView.snp.width).multipliedBy(capture.dimensions.height / capture.dimensions.width)
            }
            
            let text = NSMutableAttributedString(string: capture.name, attributes: [.font: UIFont.systemFont(ofSize: 16.0, weight: .bold), .foregroundColor: UIColor.white])
            text.append(NSAttributedString(string: "\n\nResolution: \(Int(capture.dimensions.width))x\(Int(capture.dimensions.height))\n\nDate: \(capture.timestamp.formattedString())", attributes: [.font: UIFont.systemFont(ofSize: 14.0, weight: .semibold), .foregroundColor: UIColor.white]))
            infoLabel.attributedText = text
        }
    }
    
    weak var delegate: CapturePreviewViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        [imageView, infoLabel, deleteButton].forEach(view.addSubview)
        
        imageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(20.0)
            make.height.equalTo(imageView.snp.width).multipliedBy(4.0 / 3.0)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(10.0)
            make.leading.trailing.equalToSuperview()
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(infoLabel.snp.bottom).offset(10.0)
            make.leading.trailing.equalTo(imageView)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(20.0)
            make.height.equalTo(80.0)
        }
    }
    
    @objc func deleteButtonTapped() {
        guard let capture = capture else { return }
        delegate?.capturePreviewViewController(self, didDelete: capture)
    }
}

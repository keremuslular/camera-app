//
//  ImageTitleButton.swift
//  camera-app
//
//  Created by Kerem Uslular on 19.08.2024.
//

import Foundation
import UIKit

class ImageTitleButton: UIButton {
    enum ButtonType {
        case info
        case reset
    }
    
    var type: ButtonType? {
        didSet {
            guard let type = type else { return }
            switch type {
            case .info:
                buttonImageView.image = UIImage(named: "ic_info")
                buttonTitleLabel.text = "Captures\n(\(captureCount))"
            case .reset:
                buttonImageView.image = UIImage(named: "ic_reset")
                buttonTitleLabel.text = "Reset"
            }
        }
    }
    
    var captureCount = 0 {
        didSet {
            buttonTitleLabel.text = "Captures\n(\(captureCount))"
        }
    }
    
    var buttonImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .white
        iv.cornerRadius(radius: 20.0)
        return iv
    }()
    
    var buttonTitleLabel: UILabel = {
        let lbl = UILabel()
        lbl.font = .systemFont(ofSize: 8.0, weight: .semibold)
        lbl.textColor = .white
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        return lbl
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI() {
        [buttonImageView, buttonTitleLabel].forEach(addSubview)
        
        buttonImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(buttonImageView.snp.width)
        }
        
        buttonTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(buttonImageView.snp.bottom).offset(4.0)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    func increaseCaptureCount() {
        if type == .info {
            captureCount += 1
        }
    }
}

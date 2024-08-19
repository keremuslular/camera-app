//
//  CaptureCollectionViewCell.swift
//  camera-app
//
//  Created by Kerem Uslular on 17.08.2024.
//

import Foundation
import UIKit
import Reusable

protocol CaptureCollectionViewCellDelegate: NSObjectProtocol {
    func captureCollectionViewCell(_ cell: CaptureCollectionViewCell, didTapInfoOf capture: Capture)
}

class CaptureCollectionViewCell: UICollectionViewCell, Reusable {
    let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.cornerRadius(radius: 10.0)
        iv.border(width: 1.0, color: .white)
            return iv
        }()
    
    lazy var infoButton: UIButton = {
        let btn = UIButton(type: .infoDark)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(infoButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    var selectedView: UIView = {
        let view = UIView()
        view.cornerRadius(radius: 10.0)
        view.border(width: 1.0, color: .white)
        return view
    }()
    
    override var isSelected: Bool {
        didSet {
            selectedView.backgroundColor = isSelected ? .white.withAlphaComponent(0.5) : .clear
        }
    }
    
    var selectionEnabled: Bool = false {
        didSet {
            infoButton.isHidden = selectionEnabled
            selectedView.isHidden = !selectionEnabled
        }
    }
    
    var capture: Capture?
    
    weak var delegate: CaptureCollectionViewCellDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func setupUI() {
        [imageView, infoButton, selectedView].forEach(contentView.addSubview)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        infoButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(5.0)
            make.width.height.equalTo(20.0)
        }
        
        selectedView.snp.makeConstraints { make in
            make.edges.equalTo(infoButton)
        }
    }
    
    func prepare(with capture: Capture, selectionEnabled: Bool) {
        self.capture = capture
        self.imageView.image = capture.image
        self.selectionEnabled = selectionEnabled
    }
    
    @objc func infoButtonTapped() {
        guard let capture = capture else { return }
        delegate?.captureCollectionViewCell(self, didTapInfoOf: capture)
    }
}

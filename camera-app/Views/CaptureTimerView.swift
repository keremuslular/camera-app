//
//  CaptureTimerView.swift
//  camera-app
//
//  Created by Kerem Uslular on 16.08.2024.
//

import UIKit

class CaptureTimerView: UIView {
    let timerLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .white
        lbl.font = .monospacedDigitSystemFont(ofSize: 20, weight: .medium)
        lbl.text = "00:00"
        lbl.isHidden = true
        return lbl
    }()
    
    let recordView: UIView = {
       let view = UIView()
        view.backgroundColor = .red
        view.cornerRadius(radius: 10.0)
        view.isHidden = true
        return view
    }()
    
    var timer: Timer?
    var elapsedTime: TimeInterval = 0 {
        didSet {
            timerLabel.text = elapsedTime.asTimerText()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    func setupUI() {
        [recordView, timerLabel].forEach(addSubview)
        recordView.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
            make.width.height.equalTo(20.0)
        }

        timerLabel.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.leading.equalTo(recordView.snp.trailing).offset(5.0)
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        timerLabel.isHidden = false
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        recordView.isHidden = false
        recordView.backgroundColor = .red
    }
    
    func pauseTimer() {
        timer?.invalidate()
        recordView.backgroundColor = .lightGray
    }
    
    func resetTimer() {
        timer?.invalidate()
        elapsedTime = 0
        timerLabel.isHidden = true
        recordView.isHidden = true
    }
    
    @objc func updateTimer() {
        elapsedTime += 1
    }
}


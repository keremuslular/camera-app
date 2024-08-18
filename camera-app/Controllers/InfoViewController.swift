//
//  InfoViewController.swift
//  camera-app
//
//  Created by Kerem Uslular on 17.08.2024.
//

import UIKit
import Reusable

class InfoViewController: UIViewController {
    lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        cv.delegate = self
        cv.dataSource = self
        cv.register(cellType: CaptureCollectionViewCell.self)
        cv.showsVerticalScrollIndicator = false
        cv.alwaysBounceVertical = true
        cv.allowsMultipleSelection = false
        return cv
    }()
    
    lazy var flowLayout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        let spacing = CGFloat(5.0)
        let columnCount = 3
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        layout.scrollDirection = .vertical
        let width = (UIScreen.main.bounds.width - (spacing * CGFloat(columnCount - 1))) / CGFloat(columnCount)
        layout.itemSize = CGSize(width: CGFloat(width), height: CGFloat(width))
        return layout
    }()
    
    lazy var selectButton: UIBarButtonItem = {
        let btn = UIBarButtonItem(title: "Select", style: .plain, target: self, action: #selector(selectButtonTapped))
        return btn
    }()
    
    lazy var fixedSpace: UIBarButtonItem = {
        let space = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        space.width = 30.0
        return space
    }()
    
    lazy var deleteButton: UIBarButtonItem = {
        let btn = UIButton()
        btn.setImage(UIImage(named: "ic_delete")?.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.snp.makeConstraints { make in
            make.width.height.equalTo(20.0)
        }
        btn.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        let barBtn = UIBarButtonItem(customView: btn)
        barBtn.isHidden = true
        return barBtn
    }()
    
    var captures = [Capture]() {
        didSet {
            DispatchQueue.main.async {
                self.collectionView.reloadData()
                self.setTitle()
            }
        }
    }
    
    var selectedCaptureNames = Set<String>()
        
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captures = StorageManager.shared.getAll()
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        [collectionView].forEach(view.addSubview)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        navigationItem.rightBarButtonItems = [selectButton, fixedSpace, deleteButton]
    }
    
    func setTitle() {
        let titleLabel: UILabel = {
            let lbl = UILabel()
            lbl.numberOfLines = 0
            lbl.textAlignment = .center
            let text = NSMutableAttributedString(string: "Info\n", attributes: [.font: UIFont.preferredFont(forTextStyle: .headline)])
            text.append(NSAttributedString(string: "Capture count: \(captures.count)", attributes: [.font: UIFont.systemFont(ofSize: 12.0)]))
            lbl.attributedText = text
            return lbl
        }()
        navigationItem.titleView = titleLabel
    }
    
    @objc func selectButtonTapped() {
        let isSelecting = collectionView.allowsMultipleSelection
        collectionView.allowsMultipleSelection = !isSelecting
        
        selectButton.title = isSelecting ? "Select" : "Done"
        deleteButton.isHidden = isSelecting
        
        if isSelecting {
            selectedCaptureNames.removeAll()
        }
        
        collectionView.reloadData()
    }
    
    @objc func deleteButtonTapped() {
        handleMultiDeletion()
        collectionView.allowsMultipleSelection = false
        selectButton.title = "Select"
        deleteButton.isHidden = true
    }
    
    func handleDeletion(capture: Capture) {
        StorageManager.shared.delete(named: capture.name)
        captures = StorageManager.shared.getAll()
    }
    
    func handleMultiDeletion() {
        selectedCaptureNames.forEach { name in
            StorageManager.shared.delete(named: name)
        }
        captures = StorageManager.shared.getAll()
        selectedCaptureNames.removeAll()
    }
}

extension InfoViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        captures.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(for: indexPath, cellType: CaptureCollectionViewCell.self)
        cell.prepare(with: captures[indexPath.item], selectionEnabled: collectionView.allowsMultipleSelection)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let capture = captures[indexPath.item]
        
        if collectionView.allowsMultipleSelection {
            selectedCaptureNames.insert(capture.name)
        } else {
            let previewViewController = CapturePreviewViewController()
            previewViewController.capture = capture
            previewViewController.delegate = self
            previewViewController.modalPresentationStyle = .pageSheet
            present(previewViewController, animated: true, completion: nil)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if collectionView.allowsMultipleSelection {
            let capture = captures[indexPath.item]
            selectedCaptureNames.remove(capture.name)
        }
    }
}

extension InfoViewController: CaptureCollectionViewCellDelegate {
    func captureCollectionViewCell(_ cell: CaptureCollectionViewCell, didTapInfoOf capture: Capture) {
        let alertController = UIAlertController(
            title: capture.name,
            message: "Dimensions: \(Int(capture.dimensions.width))x\(Int(capture.dimensions.height))\nDate: \(capture.timestamp.formattedString())",
            preferredStyle: .actionSheet
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.handleDeletion(capture: capture)
        }
        alertController.addAction(deleteAction)
        
        let dismissAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alertController.addAction(dismissAction)
        
        alertController.modalPresentationStyle = .popover
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = cell.infoButton
            popoverController.sourceRect = cell.infoButton.bounds
            popoverController.permittedArrowDirections = .any
            popoverController.delegate = self
        }
        
        present(alertController, animated: true, completion: nil)
    }
}

extension InfoViewController: CapturePreviewViewControllerDelegate {
    func capturePreviewViewController(_ viewController: CapturePreviewViewController, didDelete capture: Capture) {
        viewController.dismiss(animated: true) {
            self.handleDeletion(capture: capture)
        }
    }
}

extension InfoViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}

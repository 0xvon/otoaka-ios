//
//  ReadQRCodeViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/04.
//

import Foundation
import SafariServices
import UIComponent
import UIKit
import Endpoint
import Combine
import MercariQRScanner

final class ReadQRCodeViewController: UIViewController, Instantiable {
    typealias Input = Void
    let dependencyProvider: LoggedInDependencyProvider
    let urlSchemeActionViewModel: UrlSchemeActionViewModel
    private lazy var galleryButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(galleryTapped), for: .touchUpInside)
        button.setImage(UIImage(systemName: "photo")?.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        return button
    }()
    
    private var cancellables: [AnyCancellable] = []
    private lazy var qrScannerView = QRScannerView(frame: view.bounds)
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        self.urlSchemeActionViewModel = UrlSchemeActionViewModel(dependencyProvider: dependencyProvider)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
    }
    
    func setup() {
        view.addSubview(qrScannerView)
        qrScannerView.configure(delegate: self)
        qrScannerView.startRunning()
        
        view.addSubview(galleryButton)
        NSLayoutConstraint.activate([
            galleryButton.widthAnchor.constraint(equalToConstant: 40),
            galleryButton.heightAnchor.constraint(equalToConstant: 40),
            galleryButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor, constant: 24),
            galleryButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -24)
        ])
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        bind()
    }
    
    func bind() {
        urlSchemeActionViewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .pushToUserDetail(let input):
                let vc = UserDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToGroupDetail(let input):
                let vc = BandDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToLiveDetail(let input):
                let vc = LiveDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .pushToPostDetail(let input):
                let vc = PostDetailViewController(dependencyProvider: dependencyProvider, input: input)
                self.navigationController?.pushViewController(vc, animated: true)
            case .reportError(let err):
                print(String(describing: err))
                showAlert(title: "見つかりませんでした", message: "URLが正しいかお確かめの上再度お試しください")
            }
        }
        .store(in: &cancellables)
    }
    
    @objc private func galleryTapped() {
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            self.present(picker, animated: true, completion: nil)
        }
    }
    
    func readQRFromLibraryPhoto(image: UIImage) {
        let detector = CIDetector(ofType: CIDetectorTypeQRCode, context: nil, options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        let ciImage = CIImage(image: image)!
        
        if let feature = detector?.features(in: ciImage).first as? CIQRCodeFeature {
            let url = URL(string: feature.messageString!)!
            urlSchemeActionViewModel.action(url: url)
        } else {
            showAlert(title: "スキャン失敗", message: "選択された画像からQRコードを読み取ることができませんでした。")
        }
    }
}

extension ReadQRCodeViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        readQRFromLibraryPhoto(image: image)
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ReadQRCodeViewController: QRScannerViewDelegate {
    func qrScannerView(_ qrScannerView: QRScannerView, didFailure error: QRScannerError) {
    }
    
    func qrScannerView(_ qrScannerView: QRScannerView, didSuccess code: String) {
        if let url = URL(string: code) {
            urlSchemeActionViewModel.action(url: url)
        }
    }
}

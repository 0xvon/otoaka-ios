//
//  SocialShareViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/03.
//

import Foundation
import SafariServices
import UIComponent
import UIKit
import Endpoint

final class SocialShareViewController: UIViewController, Instantiable {
    typealias Input = Void
    let dependencyProvider: LoggedInDependencyProvider
    
    private lazy var appLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "AppLogo")
        return imageView
    }()
    private lazy var qrCodeImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        imageView.isUserInteractionEnabled = true
        imageView.layer.cornerRadius = 20
//        imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(userTapped)))
        return imageView
    }()
    private lazy var linkLabel: UIButton = {
        let label = UIButton()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.titleLabel?.font = Brand.font(for: .largeStrong)
        label.setTitleColor(Brand.color(for: .text(.primary)), for: .normal)
        label.addTarget(self, action: #selector(linkLabelTapped), for: .touchUpInside)
        return label
    }()
    private lazy var readButton: PrimaryButton = {
        let button = PrimaryButton(text: "")
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(systemName: "camera")?.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal), for: .normal)
        button.setTitle("QRコードをスキャン", for: .normal)
        button.layer.cornerRadius = 24
        button.addTarget(self, action: #selector(readButtonTapped), for: .touchUpInside)
        return button
    }()
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
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
        view.backgroundColor = Brand.color(for: .background(.primary))
        
        view.addSubview(appLogoImageView)
        NSLayoutConstraint.activate([
            appLogoImageView.widthAnchor.constraint(equalToConstant: 300),
            appLogoImageView.heightAnchor.constraint(equalToConstant: 40),
            appLogoImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 48),
            appLogoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        view.addSubview(qrCodeImageView)
        NSLayoutConstraint.activate([
            qrCodeImageView.widthAnchor.constraint(equalTo: appLogoImageView.widthAnchor),
            qrCodeImageView.heightAnchor.constraint(equalTo: qrCodeImageView.widthAnchor),
            qrCodeImageView.centerXAnchor.constraint(equalTo: appLogoImageView.centerXAnchor),
            qrCodeImageView.topAnchor.constraint(equalTo: appLogoImageView.bottomAnchor, constant: 48),
        ])
        showQRCode()
        
        view.addSubview(linkLabel)
        NSLayoutConstraint.activate([
            linkLabel.widthAnchor.constraint(equalTo: appLogoImageView.widthAnchor),
            linkLabel.centerXAnchor.constraint(equalTo: appLogoImageView.centerXAnchor),
            linkLabel.topAnchor.constraint(equalTo: qrCodeImageView.bottomAnchor, constant: 24),
        ])
        linkLabel.setTitle(dependencyProvider.user.username, for: .normal)
        
        view.addSubview(readButton)
        NSLayoutConstraint.activate([
            readButton.widthAnchor.constraint(equalTo: appLogoImageView.widthAnchor),
            readButton.centerXAnchor.constraint(equalTo: appLogoImageView.centerXAnchor),
            readButton.heightAnchor.constraint(equalToConstant: 48),
            readButton.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -24),
        ])
        
        let linkItem = UIBarButtonItem(
            image: UIImage(systemName: "link")!.withTintColor(Brand.color(for: .text(.primary)), renderingMode: .alwaysOriginal),
            style: .plain,
            target: self,
            action: #selector(linkLabelTapped)
        )
        let shareItem = UIBarButtonItem(
            barButtonSystemItem: .action,
            target: self,
            action: #selector(shareButtonTapped)
        )
        navigationItem.setRightBarButtonItems([
            linkItem,
            shareItem,
        ], animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        setup()
    }
    
    func bind() {
        
    }
    
    private func showQRCode() {
        DispatchQueue.main.async { [unowned self] in
            if let username = dependencyProvider.user.username, let data = "band.rocketfor://ios/users/\(username)".data(using: .utf8) {
                let qr = CIFilter(name: "CIQRCodeGenerator", parameters: ["inputMessage": data, "inputCorrectionLevel": "M"])!
                let sizeTransform = CGAffineTransform(scaleX: 10, y: 10)
                let qrImage = qr.outputImage!.transformed(by: sizeTransform)
                qrCodeImageView.image = UIImage(ciImage: qrImage)
            }
        }
        
    }
    
    @objc private func linkLabelTapped() {
        let url = URL(string: "https://rocketfor.band/users/\(dependencyProvider.user.username!)")!
        let safari = SFSafariViewController(url: url)
        safari.dismissButtonStyle = .close
        present(safari, animated: true, completion: nil)
    }
    
    @objc private func shareButtonTapped() {
        share(type: .user(dependencyProvider.user))
    }
    
    @objc private func readButtonTapped() {
        let vc = ReadQRCodeViewController(dependencyProvider: dependencyProvider, input: ())
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}

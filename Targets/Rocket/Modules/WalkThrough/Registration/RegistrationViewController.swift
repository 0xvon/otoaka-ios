//
//  RegistrationViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import AWSCognitoAuth
import SafariServices
import UIKit
import Combine

final class RegistrationViewController: UIViewController, Instantiable {
    typealias SignedUpHandler = () -> Void
    typealias Input = SignedUpHandler

    lazy var viewModel = RegistrationViewModel(
        auth: dependencyProvider.auth,
        apiClient: dependencyProvider.apiClient
    )

    @IBOutlet weak var backgroundImageView: UIImageView! {
        didSet {
            backgroundImageView.layer.opacity = 0.8
            backgroundImageView.image = UIImage(named: "dpf")
            backgroundImageView.contentMode = .scaleAspectFill
        }
    }
    private lazy var appLogoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "AppLogo")
        return imageView
    }()
    private lazy var descriptionTextView: UITextView = {
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textColor = Brand.color(for: .text(.primary))
        textView.font = Brand.font(for: .mediumStrong)
        textView.text = "ライブ好きのためのSNS"
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        return textView
    }()
    private lazy var TermsOfServiceButton: UIButton = {
        let button = UIButton()
        button.setTitle("利用規約", for: .normal)
        button.titleLabel?.font = Brand.font(for: .mediumStrong)
        button.setTitleColor(Brand.color(for: .brand(.secondary)), for: .normal)
        button.addTarget(self, action: #selector(tosDidTapped), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    @IBOutlet weak var signInButtonView: Button! {
        didSet {
            signInButtonView.setTitle("利用規約に同意してログイン", for: .normal)
        }
    }

    var dependencyProvider: DependencyProvider
    var signedUpHandler: SignedUpHandler
    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: DependencyProvider, input: @escaping Input) {
        self.dependencyProvider = dependencyProvider
        self.signedUpHandler = input
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.largeTitleDisplayMode = .never
        setup()
        bind()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dependencyProvider.auth.delegate = self
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        
        self.navigationController?.navigationBar.isTranslucent = true
        self.navigationController?.navigationBar.barTintColor = .clear
        self.navigationController?.navigationBar.backgroundColor = .clear
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
//        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.presentationController?.delegate = self
    }
    
    func bind() {
        signInButtonView.listen { [unowned self] in
            viewModel.getSignupStatus()
        }

        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .signupStatus(let isSignedup):
                if isSignedup {
                    self.signedUpHandler()
                    self.dismiss(animated: true)
                } else {
                    viewModel.signup()
                }
            case .error(let error):
                print(error)
                self.showAlert()
            case .didCreateUser(_):
                self.dismiss(animated: true, completion: nil)
            }
        }.store(in: &cancellables)
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        
        view.addSubview(appLogoImageView)
        NSLayoutConstraint.activate([
            appLogoImageView.widthAnchor.constraint(equalToConstant: 300),
            appLogoImageView.heightAnchor.constraint(equalToConstant: 40),
            appLogoImageView.topAnchor.constraint(equalTo: view.topAnchor, constant: 64),
            appLogoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        view.addSubview(descriptionTextView)
        NSLayoutConstraint.activate([
            descriptionTextView.topAnchor.constraint(equalTo: appLogoImageView.bottomAnchor, constant: 16),
            descriptionTextView.heightAnchor.constraint(equalToConstant: 60),
            descriptionTextView.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 8),
            descriptionTextView.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -8),
        ])
        
        view.addSubview(TermsOfServiceButton)
        NSLayoutConstraint.activate([
            TermsOfServiceButton.heightAnchor.constraint(equalToConstant: 20),
            TermsOfServiceButton.topAnchor.constraint(equalTo: signInButtonView.bottomAnchor, constant: 8),
            TermsOfServiceButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    private var awsCognitoAuthSaferiViewControllerWorkaround: AWSCognitoAuthSaferiViewControllerWorkaround?
    class AWSCognitoAuthSaferiViewControllerWorkaround: NSObject, UIAdaptivePresentationControllerDelegate {
        weak var controller: SFSafariViewController?
        weak var originalDelegate: SFSafariViewControllerDelegate?
        init(controller: SFSafariViewController, originalDelegate: SFSafariViewControllerDelegate?) {
            self.controller = controller
            self.originalDelegate = originalDelegate
        }
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            originalDelegate?.safariViewControllerDidFinish?(controller!)
        }
        func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
            return .formSheet
        }
    }

    // Workaround: AWSCognitoAuth doesn't handle presentationControllerShouldDismiss for SFSafariViewController,
    // so callback function passed to getSession will not be called when a user dismissed SFSafariVC with drag gesture.
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        var flag = flag
        if let safariVC = viewControllerToPresent as? SFSafariViewController {
            awsCognitoAuthSaferiViewControllerWorkaround = AWSCognitoAuthSaferiViewControllerWorkaround(
                controller: safariVC, originalDelegate: safariVC.delegate
            )
            safariVC.presentationController?.delegate = awsCognitoAuthSaferiViewControllerWorkaround
            // AWSCognitoAuth passes `animated` option as always false 😡
            flag = true
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
    
    @objc private func tosDidTapped() {
        guard let url = URL(string: "https://www.notion.so/masatojames/57b1f47c538443249baf1db83abdc462") else { return }
        let safari = SFSafariViewController(url: url)
        safari.dismissButtonStyle = .close
        present(safari, animated: true, completion: nil)
    }
}

extension RegistrationViewController: AWSCognitoAuthDelegate {
    func getViewController() -> UIViewController {
        return self
    }
}

extension RegistrationViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return false
    }
}

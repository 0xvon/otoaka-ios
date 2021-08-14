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
        textView.text = "同じアーティストが好きな人や\n同じライブに行く予定の人をすぐに探せます"
        textView.backgroundColor = .clear
        textView.textAlignment = .center
        return textView
    }()
    @IBOutlet weak var signInButtonView: Button! {
        didSet {
            signInButtonView.setTitle("ログイン", for: .normal)
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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dependencyProvider.auth.delegate = self
        dependencyProvider.viewHierarchy.activateFloatingOverlay(isActive: false)
        
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.shadowImage = UIImage()
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.presentationController?.delegate = self
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
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

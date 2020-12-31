//
//  RegistrationViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import AWSCognitoAuth
import SafariServices
import UIKit

final class RegistrationViewController: UIViewController, Instantiable {
    typealias SignedUpHandler = () -> Void
    typealias Input = SignedUpHandler

    lazy var viewModel = RegistrationViewModel(
        auth: dependencyProvider.auth,
        apiClient: dependencyProvider.apiClient,
        outputHander: { [dependencyProvider] output in
            switch output {
            case .signupStatus(let isSignedup):
                if isSignedup {
                    DispatchQueue.main.async {
                        self.signedUpHandler()
                        self.dismiss(animated: true)
                    }
                } else {
                    DispatchQueue.main.async {
                        let vc = CreateUserViewController(
                            dependencyProvider: self.dependencyProvider, input: ())
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            case .error(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "エラー", message: String(describing: error))
                }
            }
        }
    )

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var signInButtonView: Button!

    var dependencyProvider: DependencyProvider
    var signedUpHandler: SignedUpHandler

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
        setup()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.dependencyProvider.auth.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.presentationController?.delegate = self
    }

    func setup() {
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        backgroundImageView.layer.opacity = 0.6
        backgroundImageView.image = UIImage(named: "live")
        backgroundImageView.contentMode = .scaleAspectFill

        signInButtonView.setTitle("サインイン", for: .normal)
        signInButtonView.listen { [weak self] in
            self?.signInButtonTapped()
        }
    }

    func signInButtonTapped() {
        viewModel.getSignupStatus()
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

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
            backgroundImageView.layer.opacity = 0.6
            backgroundImageView.image = UIImage(named: "live")
            backgroundImageView.contentMode = .scaleAspectFill
        }
    }
    @IBOutlet weak var signInButtonView: Button! {
        didSet {
            signInButtonView.setTitle("ユーザー登録/ログイン", for: .normal)
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
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationController?.presentationController?.delegate = self
    }

    func setup() {
        title = "ユーザー登録"
        self.view.backgroundColor = Brand.color(for: .background(.primary))
        signInButtonView.listen { [viewModel] in
            viewModel.getSignupStatus()
        }

        viewModel.output.receive(on: DispatchQueue.main).sink { [unowned self] output in
            switch output {
            case .signupStatus(let isSignedup):
                if isSignedup {
                    self.signedUpHandler()
                    self.dismiss(animated: true)
                } else {
                    let vc = CreateUserViewController(
                        dependencyProvider: self.dependencyProvider, input: ())
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            case .error(let error):
                self.showAlert(title: "エラー", message: String(describing: error))
            }
        }.store(in: &cancellables)
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

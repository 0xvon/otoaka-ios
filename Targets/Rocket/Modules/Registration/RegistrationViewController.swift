//
//  RegistrationViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import AWSCognitoAuth
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
                    self.showAlert(title: "エラー", message: error.localizedDescription)
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

        self.dependencyProvider.auth.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
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
}

extension RegistrationViewController: AWSCognitoAuthDelegate {
    func getViewController() -> UIViewController {
        return self
    }
}

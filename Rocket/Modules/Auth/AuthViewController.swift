//
//  AuthViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import UIKit
import AWSCognitoAuth

final class AuthViewController: UIViewController, Instantiable {
    typealias SignedUpHandler = () -> Void
    typealias Input = SignedUpHandler
    
    lazy var viewModel = AuthViewModel(
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
                        let vc = CreateUserViewController(dependencyProvider: self.dependencyProvider, input: ())
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            case .error(let error):
                print(error)
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
        self.view.backgroundColor = style.color.background.get()
        backgroundImageView.layer.opacity = 0.6
        backgroundImageView.image = UIImage(named: "live")
        backgroundImageView.contentMode = .scaleAspectFill

        signInButtonView.inject(input: (text: "サインイン", image: nil))
        signInButtonView.listen { [weak self] in
            self?.signInButtonTapped()
        }
    }
    
    func signInButtonTapped() {
        viewModel.getSignupStatus()
    }
}

extension AuthViewController: AWSCognitoAuthDelegate {
    func getViewController() -> UIViewController {
        return self
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct AuthViewController_Previews: PreviewProvider {
    static var previews: some View {
        ViewControllerWrapper<AuthViewController>(
            dependencyProvider: .make(),
            input: {}
        )
    }
}

#endif

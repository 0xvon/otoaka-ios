//
//  AuthViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import UIKit
import AWSCognitoAuth

final class AuthViewController: UIViewController, Instantiable {
    typealias Input = Void
    
    lazy var viewModel = AuthViewModel(
        auth: dependencyProvider.auth,
        apiClient: dependencyProvider.apiClient,
        outputHander: { [dependencyProvider] output in
            switch output {
            case .signin(let session):
                guard let idToken = session.idToken else { return }
                do {
                    try dependencyProvider.apiClient.login(with: idToken.tokenString)
                } catch let error {
                    print(error)
                }
                DispatchQueue.main.async {
                    self.signupStatus()
                }
            case .signupStatus(let isSignedup):
                if isSignedup {
                    DispatchQueue.main.async {
                        self.getUser()
                    }
                } else {
                    DispatchQueue.main.async {
                        let vc = CreateUserViewController(dependencyProvider: self.dependencyProvider, input: ())
                        self.navigationController?.pushViewController(vc, animated: true)
                    }
                }
            case.getUser(let user):
                DispatchQueue.main.async {
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                    let provider = LoggedInDependencyProvider(provider: self.dependencyProvider, user: user)
                    let vc = HomeViewController(dependencyProvider: provider, input: ())
                    self.navigationController?.pushViewController(vc, animated: true)
                }
            case .error(let error):
                print(error)
            }
        }
    )
    
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var signInButtonView: Button!
    
    var dependencyProvider: DependencyProvider
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        super.init(nibName: nil, bundle: nil)
        
        self.dependencyProvider.auth.delegate = self
        self.signin()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    func signin() {
        viewModel.signin()
    }
    
    func signupStatus() {
        viewModel.getSignupStatus()
    }
    
    func getUser() {
        viewModel.getUser()
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
        signin()
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
            input: ()
        )
    }
}

#endif

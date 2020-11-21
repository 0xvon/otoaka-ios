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
            case .signin(let session, let isSignedup):
                guard let idToken = session.idToken else { return }
                dependencyProvider.apiClient.login(with: idToken.tokenString)
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
                    let vc = HomeViewController(dependencyProvider: self.dependencyProvider, input: user)
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
        viewModel.signin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
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
        viewModel.signin()
    }
    
    func getUser() {
        viewModel.getUser()
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

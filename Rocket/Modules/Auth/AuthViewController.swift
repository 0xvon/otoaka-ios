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
        outputHander: { output in
            switch output {
            case .signin(let session):
                guard let session = session else { print("howwwww"); return }
                self.session = session
                self.label.text = session.username
            case .signout:
                self.session = nil
                self.label.text = "signed out"
            case .error(let error):
                print(error)
            }
        }
    )

    var session: AWSCognitoAuthUserSession?
    var dependencyProvider: DependencyProvider
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var signinButton: UIButton!
    @IBOutlet weak var signoutButton: UIButton!
    
    init(dependencyProvider: DependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        super.init(nibName: nil, bundle: nil)
        
        self.dependencyProvider.auth.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.label.text = session?.username ?? "signed out"
    }
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        viewModel.signin()
    }
    
    @IBAction func signOutButtontapped(_ sender: Any) {
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

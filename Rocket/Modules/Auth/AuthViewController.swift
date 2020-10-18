//
//  AuthViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import UIKit
import AWSCognitoAuth

class AuthViewController: UIViewController, XibInstantiable, AWSCognitoAuthDelegate {
    
    var viewModel: AuthViewModel!
    var input: Void!
    var auth: AWSCognitoAuth = AWSCognitoAuth.default()
    var session: AWSCognitoAuthUserSession?
    
    typealias Input = Void
    static var xibName: String { "AuthViewController" }
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signinButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.auth.delegate = self
    }
    
    func inject(input: Void) {
        viewModel = AuthViewModel(outputHander: {output in
            print("hello")
            switch output {
            case .id(let endpoint):
                print(endpoint)
                self.label.text = "hello"
            case .login:
                print("login")
            case .signin(let session):
                guard let session = session else { print("howwwww"); return }
                self.session = session
                self.label.text = session.username
                
            }
        })
    }
    
    func getViewController() -> UIViewController {
        return self
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        viewModel.login()
    }
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        viewModel.signin(auth: self.auth)
    }
}

#if DEBUG && canImport(SwiftUI)
import SwiftUI

struct AuthViewControllerWrapper: UIViewControllerRepresentable {
    
    typealias UIViewControllerType = AuthViewController
    let input: AuthViewController.Input
    
    init(input: AuthViewController.Input) {
        self.input = input
    }
    
    func makeUIViewController(context: Context) -> AuthViewController {
        let vc = AuthViewController.init(input: ())
        return vc
    }
    
    func updateUIViewController(_ uiViewController: AuthViewController, context: Context) {
        uiViewController.inject(input: ())
    }
    
}

struct AuthViewController_Previews: PreviewProvider {
    static var previews: some View {
        AuthViewControllerWrapper(input: ())
    }
}

#endif

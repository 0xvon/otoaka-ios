//
//  AuthViewController.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import Foundation
import UIKit

class AuthViewController: UIViewController, XibInstantiable {
    
    var viewModel: AuthViewModel!
    var input: Void!
    typealias Input = Void
    static var xibName: String { "AuthViewController" }
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var signinButton: UIButton!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
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
            case .signin:
                print("signin")
            }
        })
    }
    
    @IBAction func loginButtonTapped(_ sender: Any) {
        viewModel.login()
    }
    
    @IBAction func signInButtonTapped(_ sender: Any) {
        viewModel.signin()
    }
}

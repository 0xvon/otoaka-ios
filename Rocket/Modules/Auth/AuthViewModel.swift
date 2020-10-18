//
//  AuthViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import Foundation
import Endpoint
import AWSCognitoAuth

class AuthViewModel {
    enum Output {
        case signout
        case signin(AWSCognitoAuthUserSession?)
        case error(Error)
    }
    
    let auth: AWSCognitoAuth
    let outputHandler: (Output) -> Void
    init(auth: AWSCognitoAuth, outputHander: @escaping (Output) -> Void) {
        self.auth = auth
        self.outputHandler = outputHander
    }
    
    func signout() {
        auth.signOut { (error: Error?) in
            if let error = error { print("signout error: \(error)"); self.outputHandler(.error(error)) }
            self.outputHandler(.signout)
        }
    }
    
    func signin() {
        auth.getSession { (session: AWSCognitoAuthUserSession?, error: Error?) in
            print("session called")
            if let error = error { print("signin error: \(error)"); self.outputHandler(.error(error)) }
            guard let session = session else { return }
            self.outputHandler(.signin(session))
        }
    }
}

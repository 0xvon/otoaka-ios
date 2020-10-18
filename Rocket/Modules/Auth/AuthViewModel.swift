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
        case id(Endpoint)
        case login
        case signin(AWSCognitoAuthUserSession?)
    }
    
    let outputHandler: (Output) -> Void
    init(outputHander: @escaping (Output) -> Void) {
        self.outputHandler = outputHander
    }
    
    func fetchAccount() {
        let endpoint: Endpoint = Endpoint()
        outputHandler(.id(endpoint))
    }
    
    func login() {
        
    }
    
    func signin(auth: AWSCognitoAuth) {
        auth.getSession { (session: AWSCognitoAuthUserSession?, error: Error?) in
            if let error = error { print("signin error: \(error)"); self.outputHandler(.signin(nil)) }
            guard let session = session else { return }
            self.outputHandler(.signin(session))
        }
    }
}

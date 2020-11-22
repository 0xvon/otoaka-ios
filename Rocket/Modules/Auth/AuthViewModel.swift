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
        case signin(AWSCognitoAuthUserSession)
        case signupStatus(Bool)
        case getUser(User)
        case error(Error)
    }
    
    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let outputHandler: (Output) -> Void
    init(auth: AWSCognitoAuth, apiClient: APIClient, outputHander: @escaping (Output) -> Void) {
        self.auth = auth
        self.apiClient = apiClient
        self.outputHandler = outputHander
    }
    
    func signin() {
        auth.getSession { [apiClient] (session: AWSCognitoAuthUserSession?, error: Error?) in
            if let error = error {
                self.outputHandler(.error(error))
            }
            
            guard let session = session else {
                self.outputHandler(.error("session not found" as! Error))
                return
            }
            
            guard let idToken = session.idToken?.tokenString else {
                self.outputHandler(.error("idToken not found" as! Error))
                return
            }
            apiClient.login(with: idToken)
            self.outputHandler(.signin(session))
        }
    }
    
    func getSignupStatus() {
        do {
            try apiClient.request(SignupStatus.self) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.signupStatus(res.isSignedup))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }
    
    func getUser() {
        do {
            try apiClient.request(GetUserInfo.self) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.getUser(res))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }
}

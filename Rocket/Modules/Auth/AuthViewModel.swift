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
        case signupStatus(Bool)
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
    
    func getSignupStatus() {
        apiClient.request(SignupStatus.self) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.signupStatus(res.isSignedup))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
}

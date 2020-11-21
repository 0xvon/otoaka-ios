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
        case signin(AWSCognitoAuthUserSession, Bool)
        case getUser(User, String)
        case error(Error)
    }
    
    let auth: AWSCognitoAuth
    let apiEndpoint: String
    let outputHandler: (Output) -> Void
    init(auth: AWSCognitoAuth, apiEndpoint: String,  outputHander: @escaping (Output) -> Void) {
        self.auth = auth
        self.apiEndpoint = apiEndpoint
        self.outputHandler = outputHander
    }
    
    func signin() {
        auth.getSession { (session: AWSCognitoAuthUserSession?, error: Error?) in
            if let error = error {
                self.outputHandler(.error(error))
            }
            
            guard let session = session else {
                self.outputHandler(.error("session not found" as! Error))
                return
            }
            
            guard let idToken = session.idToken else {
                self.outputHandler(.error("id token not found" as! Error))
                return
            }
            
            let signupStatusAPIClient = APIClient<SignupStatus>(baseUrl: self.apiEndpoint, idToken: idToken.tokenString)
            let req: SignupStatus.Request = Empty()
            
            signupStatusAPIClient.request(req: req) { res in
                self.outputHandler(.signin(session, res.isSignedup))
            }
        }
    }
    
    func getUser(idToken: String) {
        let getUserInfoAPIClient = APIClient<GetUserInfo>(baseUrl: self.apiEndpoint, idToken: idToken)
        let req: GetUserInfo.Request = Empty()
        
        getUserInfoAPIClient.request(req: req) { res in
            self.outputHandler(.getUser(res, idToken))
        }
    }
}

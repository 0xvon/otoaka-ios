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
            
            let path = DevelopmentConfig.apiEndpoint + "/" + SignupStatus.pathPattern.joined(separator: "/")
            guard let url = URL(string: path) else {
                self.outputHandler(.error("request url not found" as! Error))
                return
            }
            
            guard let token = session.idToken else {
                self.outputHandler(.error("id token not found" as! Error))
                return
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = SignupStatus.method.rawValue
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(token.tokenString)", forHTTPHeaderField: "Authorization")
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    self.outputHandler(.error(error))
                }
                
                guard let data = data else { return }
                do {
                    let response = try JSONDecoder().decode(SignupStatus.Response.self, from: data)
                    self.outputHandler(.signin(session, response.isSignedup))
                } catch let error {
                    self.outputHandler(.error(error))
                }
            }
            task.resume()
        }
    }
    
    func getUser(idToken: String) {
        let path = DevelopmentConfig.apiEndpoint + "/" + GetUserInfo.pathPattern.joined(separator: "/")
        guard let url = URL(string: path) else {
            self.outputHandler(.error("request url not found" as! Error))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = GetUserInfo.method.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                self.outputHandler(.error(error))
            }
            
            guard let data = data else { return }
            do {
                let response = try JSONDecoder().decode(GetUserInfo.Response.self, from: data)
                self.outputHandler(.getUser(response, idToken))
            } catch let error {
                self.outputHandler(.error(error))
            }
        }
        task.resume()
    }
}

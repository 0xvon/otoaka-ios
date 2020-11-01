//
//  InvitationViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import Foundation
import Endpoint

class InvitationViewModel {
    enum Output {
        case joinGroup
        case error(String)
    }
    
    let idToken: String
    let apiEndpoint: String
    let s3Bucket: String
    let outputHandler: (Output) -> Void
    
    init(idToken: String, apiEndpoint: String, s3Bucket: String, outputHander: @escaping (Output) -> Void) {
        self.idToken = idToken
        self.apiEndpoint = apiEndpoint
        self.s3Bucket = s3Bucket
        self.outputHandler = outputHander
    }
    
    func joinGroup(invitationCode: String?) {
        if let invitationCode = invitationCode {
            let path = DevelopmentConfig.apiEndpoint + "/" + JoinGroup.pathPattern.joined(separator: "/")
            guard let url = URL(string: path) else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = Signup.method.rawValue
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.addValue("Bearer \(self.idToken)", forHTTPHeaderField: "Authorization")
            let body = JoinGroup.Request(invitationId: invitationCode)
            request.httpBody = try! JSONEncoder().encode(body)
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    self.outputHandler(.error(error.localizedDescription))
                }
                
                guard let data = data else { return }
                do {
                    let _ = try JSONDecoder().decode(JoinGroup.Response.self, from: data)
                    self.outputHandler(.joinGroup)
                } catch {
                    self.outputHandler(.error(String(data: data, encoding: .utf8)!))
                }
            }
            task.resume()
            
        } else {
            outputHandler(.error("invitation code not found"))
        }
    }
    
    func enterInvitationCode(invitationCode: String?) {
        
    }
}

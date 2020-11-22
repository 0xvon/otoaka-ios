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
        case error(Error)
    }
    
    let apiClient: APIClient
    let s3Bucket: String
    let outputHandler: (Output) -> Void
    
    init(apiClient: APIClient, s3Bucket: String, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.s3Bucket = s3Bucket
        self.outputHandler = outputHander
    }
    
    func joinGroup(invitationCode: String?) {
        if let invitationCode = invitationCode {
            let req = JoinGroup.Request(invitationId: invitationCode)
            do {
                try apiClient.request(JoinGroup.self, request: req) { result in
                    switch result {
                    case .success:
                        self.outputHandler(.joinGroup)
                    case .failure(let error):
                        self.outputHandler(.error(error))
                    }
                }    
            } catch {
                self.outputHandler(.error("request faild" as! Error))
            }
        } else {
            outputHandler(.error("invitation code not found" as! Error))
        }
    }
    
    func enterInvitationCode(invitationCode: String?) {
        
    }
}

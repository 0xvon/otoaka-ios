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
            
            // FIXME
            try! apiClient.request(JoinGroup.self, request: req) { result in
                switch result {
                case .success:
                    self.outputHandler(.joinGroup)
                case .failure(let error):
                    // FIXME
                    fatalError(String(describing: error))
                }
            }
        } else {
            outputHandler(.error("invitation code not found"))
        }
    }
    
    func enterInvitationCode(invitationCode: String?) {
        
    }
}

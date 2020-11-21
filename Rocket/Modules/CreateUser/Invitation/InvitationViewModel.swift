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
            let joinGroupAPIClient = APIClient<JoinGroup>(baseUrl: self.apiEndpoint, idToken: self.idToken)
            let req: JoinGroup.Request = JoinGroup.Request(invitationId: invitationCode)
            
            joinGroupAPIClient.request(req: req) { res in
                self.outputHandler(.joinGroup)
            }
        } else {
            outputHandler(.error("invitation code not found"))
        }
    }
    
    func enterInvitationCode(invitationCode: String?) {
        
    }
}

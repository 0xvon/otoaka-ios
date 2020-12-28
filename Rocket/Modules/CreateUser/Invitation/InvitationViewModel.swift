//
//  InvitationViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import Endpoint
import Foundation

class InvitationViewModel {
    enum Output {
        case joinGroup
        case error(Error)
    }

    let apiClient: APIClient
    let s3Client: S3Client
    let outputHandler: (Output) -> Void

    init(apiClient: APIClient, s3Client: S3Client, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.s3Client = s3Client
        self.outputHandler = outputHander
    }

    func joinGroup(invitationCode: String?) {
        if let invitationCode = invitationCode {
            let req = JoinGroup.Request(invitationId: invitationCode)
            apiClient.request(JoinGroup.self, request: req) { result in
                switch result {
                case .success:
                    self.outputHandler(.joinGroup)
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        }
    }

    func enterInvitationCode(invitationCode: String?) {

    }
}

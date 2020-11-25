//
//  AccountViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/29.
//

import AWSCognitoAuth
import Endpoint
import UIKit

class AccountViewModel {
    enum Output {
        case inviteGroup(InviteGroup.Invitation)
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let user: User
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, user: User, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.user = user
        self.auth = auth
        self.outputHandler = outputHander
    }

    func inviteGroup() {
        let request = Empty()
        var uri = Endpoint.GetMemberships.URI()
        uri.artistId = self.user.id
        do {
            try apiClient.request(GetMemberships.self, request: request, uri: uri) { result in
                switch result {
                case .success(let res):
                    let groupId = res[0].id
                    self.inviteGroup(groupId: groupId)
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }

    func inviteGroup(groupId: Group.ID) {

        let request = InviteGroup.Request(groupId: groupId)
        do {
            try apiClient.request(InviteGroup.self, request: request) { result in
                switch result {
                case .success(let invitation):
                    self.outputHandler(.inviteGroup(invitation))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }
}

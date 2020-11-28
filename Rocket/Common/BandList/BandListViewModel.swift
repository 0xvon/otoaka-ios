//
//  BandListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/28.
//

import UIKit
import AWSCognitoAuth
import Endpoint

class BandListViewModel {
    enum Output {
        case memberships([Group])
        case followingGroups([Group])
        case searchGroups([Group])
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.auth = auth
        self.outputHandler = outputHander
    }
    
    func getMemberships(userId: User.ID) {
        let request = Empty()
        var uri = Endpoint.GetMemberships.URI()
        uri.artistId = userId
        apiClient.request(GetMemberships.self, request: request, uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.memberships(res))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
    
    func getFollowingGroups() {
        
    }
    
    func searchGroups(query: String) {
        
    }

}

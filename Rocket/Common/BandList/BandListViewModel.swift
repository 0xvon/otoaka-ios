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
    let userId: User.ID
    let apiClient: APIClient
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, userId: User.ID, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.userId = userId
        self.auth = auth
        self.outputHandler = outputHander
    }
    
    func getMemberships() {
        let request = Empty()
        var uri = Endpoint.GetMemberships.URI()
        uri.artistId = self.userId
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
        let request = Empty()
        var uri = Endpoint.FollowingGroups.URI()
        uri.page = 1
        uri.per = 100
        uri.id = self.userId
        apiClient.request(FollowingGroups.self, request: request, uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.followingGroups(res.items))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
    
    func searchGroups(query: String) {
        let req = Empty()
        var uri = SearchGroup.URI()
        uri.page = 1
        uri.per = 100
        uri.term = query
        apiClient.request(SearchGroup.self, request: req, uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.searchGroups(res.items))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }

}

//
//  LiveDetailViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/24.
//

import AWSCognitoAuth
import Endpoint
import Foundation

class LiveDetailViewModel {
    enum Output {
        case getLive(Live)
        case toggleFollow(Int)
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let outputHandler: (Output) -> Void

    init(apiClient: APIClient, auth: AWSCognitoAuth, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.auth = auth
        self.outputHandler = outputHander
    }

    func getLive(liveId: Live.ID) {
        var uri = GetLive.URI()
        uri.liveId = liveId
        let req = Empty()
        apiClient.request(GetLive.self, request: req, uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.getLive(res))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
    
    func followGroup(groupId: Group.ID, cellIndex: Int) {
        let req = FollowGroup.Request(groupId: groupId)
        apiClient.request(FollowGroup.self, request: req) { result in
            switch result {
            case .success(_):
                self.outputHandler(.toggleFollow(cellIndex))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }

    func unfollowGroup(groupId: Group.ID, cellIndex: Int) {
        let req = UnfollowGroup.Request(groupId: groupId)
        apiClient.request(UnfollowGroup.self, request: req) { result in
            switch result {
            case .success(_):
                self.outputHandler(.toggleFollow(cellIndex))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
}

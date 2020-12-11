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
        case getLive(LiveDetail)
        case toggleFollow(Int)
        case reserveTicket(Ticket)
        case likeLive
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let live: Live
    let apiClient: APIClient
    let outputHandler: (Output) -> Void

    init(apiClient: APIClient, auth: AWSCognitoAuth, live: Live, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.auth = auth
        self.live = live
        self.outputHandler = outputHander
    }

    func getLive() {
        var uri = GetLive.URI()
        uri.liveId = self.live.id
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
    
    func likeLive() {
        let request = LikeLive.Request(liveId: self.live.id)
        apiClient.request(LikeLive.self, request: request) { result in
            switch result {
            case .success(_):
                self.outputHandler(.likeLive)
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
    
    func reserveTicket() {
        let request = ReserveTicket.Request(liveId: live.id)
        apiClient.request(ReserveTicket.self, request: request) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.reserveTicket(res))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
}

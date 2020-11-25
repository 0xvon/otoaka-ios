//
//  BandDetailViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import AWSCognitoAuth
import Endpoint
import Foundation

class BandDetailViewModel {
    enum Output {
        case follow
        case unfollow
        case error(Error)
    }
    
    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let group: Group
    let outputHandler: (Output) -> Void
    
    init(apiClient: APIClient, auth: AWSCognitoAuth, group: Group, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.auth = auth
        self.group = group
        self.outputHandler = outputHander
    }
    
    func followGroup() {
        let req = FollowGroup.Request(groupId: self.group.id)
        do {
            try apiClient.request(FollowGroup.self, request: req) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.follow)
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }
    
    func unfollowGroup() {
        let req = UnfollowGroup.Request(groupId: self.group.id)
        do {
            try apiClient.request(UnfollowGroup.self, request: req) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.follow)
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }
}

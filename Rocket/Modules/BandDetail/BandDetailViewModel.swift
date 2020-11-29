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
        case getGroup(Group)
        case getGroupLives([Live])
        case getFollowers([User])
        case follow
        case unfollow
        case inviteGroup(InviteGroup.Invitation)
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let group: Group
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, auth: AWSCognitoAuth, group: Group,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.auth = auth
        self.group = group
        self.outputHandler = outputHander
    }

    func followGroup() {
        let req = FollowGroup.Request(groupId: self.group.id)
        apiClient.request(FollowGroup.self, request: req) { result in
            switch result {
            case .success(_):
                self.outputHandler(.follow)
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }

    func unfollowGroup() {
        let req = UnfollowGroup.Request(groupId: self.group.id)
        apiClient.request(UnfollowGroup.self, request: req) { result in
            switch result {
            case .success(_):
                self.outputHandler(.unfollow)
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }

    func getGroup() {
        var uri = GetGroup.URI()
        uri.groupId = self.group.id
        apiClient.request(GetGroup.self, request: Empty(), uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.getGroup(res))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
    
    func inviteGroup(groupId: Group.ID) {
        let request = InviteGroup.Request(groupId: groupId)
        apiClient.request(InviteGroup.self, request: request) { result in
            switch result {
            case .success(let invitation):
                self.outputHandler(.inviteGroup(invitation))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
    
    func getGroupLives() {
        let request = Empty()
        var uri = Endpoint.GetGroupLives.URI()
        uri.page = 1
        uri.per = 100
        uri.groupId = self.group.id
        apiClient.request(GetGroupLives.self, request: request, uri: uri) { result in
            switch result {
            case .success(let lives):
                self.outputHandler(.getGroupLives(lives.items))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
    
    func getFollowers() {
        let request = Empty()
        var uri = GroupFollowers.URI()
        uri.page = 1
        uri.per = 100
        uri.id = self.group.id
        apiClient.request(GroupFollowers.self, request: request, uri: uri) { result in
            switch result {
            case .success(let users):
                self.outputHandler(.getFollowers(users.items))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
}

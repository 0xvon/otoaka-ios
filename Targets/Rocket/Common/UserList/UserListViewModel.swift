//
//  FanListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/08.
//

import UIKit
import Endpoint
import AWSCognitoAuth

class UserListViewModel {
    enum Output {
        case getFollowers([User])
        case refreshFollowers([User])
        case getParticipants([User])
        case refreshParticipants([User])
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let input: UserListViewController.InputType
    let apiClient: APIClient
    let outputHandler: (Output) -> Void
    
    var groupFollowersPaginationRequest: PaginationRequest<GroupFollowers>? = nil
    var liveParticipantsPaginationRequest: PaginationRequest<GetLiveParticipants>? = nil

    init(
        apiClient: APIClient, input: UserListViewController.InputType, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.input = input
        self.auth = auth
        self.outputHandler = outputHander
        
        switch input {
        case .followers(let groupId):
            var uri = GroupFollowers.URI()
            uri.id = groupId
            self.groupFollowersPaginationRequest = PaginationRequest<GroupFollowers>(apiClient: apiClient, uri: uri)
        case .tickets(let liveId):
            var uri = GetLiveParticipants.URI()
            uri.liveId = liveId
            self.liveParticipantsPaginationRequest = PaginationRequest<GetLiveParticipants>(apiClient: apiClient, uri: uri)
        }
        
        self.groupFollowersPaginationRequest?.subscribe { [unowned self] result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshFollowers(res.items))
            case .next(let res):
                self.outputHandler(.getFollowers(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
        
        self.liveParticipantsPaginationRequest?.subscribe { [unowned self] result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshParticipants(res.items))
            case .next(let res):
                self.outputHandler(.getParticipants(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
    }
    
    func getFollowers() {
        groupFollowersPaginationRequest?.next()
    }
    
    func refreshFollowers() {
        groupFollowersPaginationRequest?.refresh()
    }
    
    func getParticipants() {
        liveParticipantsPaginationRequest?.next()
    }
    
    func refreshParticipants() {
        liveParticipantsPaginationRequest?.refresh()
    }
}

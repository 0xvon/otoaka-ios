//
//  BandContentsListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import AWSCognitoAuth
import Endpoint

class GroupFeedListViewModel {
    enum Output {
        case getGroupFeeds([ArtistFeedSummary])
        case refreshGroupFeeds([ArtistFeedSummary])
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let group: Group
    let apiClient: APIClient
    let outputHandler: (Output) -> Void
    
    let groupFeedsPaginationRequest: PaginationRequest<GetGroupFeed>

    init(
        apiClient: APIClient, group: Group, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.group = group
        self.auth = auth
        self.outputHandler = outputHander
        
        var uri = GetGroupFeed.URI()
        uri.groupId = group.id
        self.groupFeedsPaginationRequest = PaginationRequest<GetGroupFeed>(apiClient: apiClient, uri: uri)
        
        self.groupFeedsPaginationRequest.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshGroupFeeds(res.items))
            case .next(let res):
                self.outputHandler(.getGroupFeeds(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
    }
    
    func getGroupFeeds() {
        groupFeedsPaginationRequest.next()
    }
    
    func refreshGroupFeeds() {
        groupFeedsPaginationRequest.refresh()
    }
}


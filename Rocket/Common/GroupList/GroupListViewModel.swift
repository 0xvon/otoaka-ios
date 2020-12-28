//
//  BandListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/28.
//

import UIKit
import AWSCognitoAuth
import Endpoint

class GroupListViewModel {
    enum Output {
        case memberships([Group])
        case followingGroups([Group])
        case refreshFollowingGroups([Group])
        case searchGroups([Group])
        case refreshSearchGroups([Group])
        case error(Error)
    }

    let listType: GroupListViewController.BandListType
    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let outputHandler: (Output) -> Void
    
    var followingGroupsPaginationRequest: PaginationRequest<FollowingGroups>? = nil
    var searchGroupPaginationRequest: PaginationRequest<SearchGroup>? = nil

    init(
        apiClient: APIClient, type: GroupListViewController.BandListType, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.auth = auth
        self.outputHandler = outputHander
        self.listType = type
        
        switch type {
        case .followingGroups(let userId):
            var followingGroupsUri = FollowingGroups.URI()
            followingGroupsUri.id = userId
            followingGroupsPaginationRequest = PaginationRequest<FollowingGroups>(apiClient: apiClient, uri: followingGroupsUri)
        case .searchResults(let query):
            var searchGroupUri = SearchGroup.URI()
            searchGroupUri.term = query
            searchGroupPaginationRequest = PaginationRequest<SearchGroup>(apiClient: apiClient, uri: searchGroupUri)
        case .memberships(_):
            break
        }
        
        followingGroupsPaginationRequest?.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshFollowingGroups(res.items))
            case .next(let res):
                self.outputHandler(.followingGroups(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
        
        searchGroupPaginationRequest?.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshSearchGroups(res.items))
            case .next(let res):
                self.outputHandler(.searchGroups(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
    }
    
    func getMemberships() {
        switch self.listType {
        case .memberships(let userId):
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
        default:
            break
        }
    }
    
    func getFollowingGroups() {
        self.followingGroupsPaginationRequest?.next()
    }
    
    func refreshFollowingGroups() {
        self.followingGroupsPaginationRequest?.refresh()
    }
    
    func searchGroups() {
        self.searchGroupPaginationRequest?.next()
    }
    
    func refreshSearchGroups() {
        self.searchGroupPaginationRequest?.refresh()
    }

}

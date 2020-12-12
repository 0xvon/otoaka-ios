//
//  LiveListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import AWSCognitoAuth
import Endpoint

class LiveListViewModel {
    enum Output {
        case getGroupLives([Live])
        case refreshGroupLives([Live])
        case searchLive([Live])
        case refreshSearchLive([Live])
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let type: LiveListViewController.ListType
    let apiClient: APIClient
    let outputHandler: (Output) -> Void
    
    var getGroupLivesPaginationRequest: PaginationRequest<GetGroupLives>? = nil
    var searchLivePaginationRequest: PaginationRequest<SearchLive>? = nil

    init(
        apiClient: APIClient, type: LiveListViewController.ListType, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.type = type
        self.auth = auth
        self.outputHandler = outputHander
        
        switch type {
        case .groupLive(let group):
            var uri = GetGroupLives.URI()
            uri.groupId = group.id
            getGroupLivesPaginationRequest = PaginationRequest<GetGroupLives>(apiClient: apiClient, uri: uri)
        case .searchResult(let query):
            var uri = SearchLive.URI()
            uri.term = query
            searchLivePaginationRequest = PaginationRequest<SearchLive>(apiClient: apiClient, uri: uri)
        }
        
        getGroupLivesPaginationRequest?.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshGroupLives(res.items))
            case .next(let res):
                self.outputHandler(.getGroupLives(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
        
        searchLivePaginationRequest?.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshSearchLive(res.items))
            case .next(let res):
                self.outputHandler(.searchLive(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
    }
    
    func getGroupLives() {
        getGroupLivesPaginationRequest?.next()
    }
    
    func refreshGroupLives() {
        getGroupLivesPaginationRequest?.next(isNext: false)
    }
    
    func searchLive() {
        searchLivePaginationRequest?.next()
    }
    
    func refreshSearchLive() {
        searchLivePaginationRequest?.next(isNext: false)
    }
}



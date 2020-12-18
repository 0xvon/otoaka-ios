//
//  CommentListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/18.
//

import UIKit
import AWSCognitoAuth
import Endpoint

class CommentListViewModel {
    enum Output {
        case getFeedComments([String])
        case refreshFeedComments([String])
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let type: CommentListViewController.ListType
    let apiClient: APIClient
    let outputHandler: (Output) -> Void
    
    var getFeedCommentsPaginationRequest: PaginationRequest<GetGroupLives>? = nil

    init(
        apiClient: APIClient, type: CommentListViewController.ListType, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.type = type
        self.auth = auth
        self.outputHandler = outputHander
        
        switch type {
        case .feedComment(let feed):
            var uri = GetGroupLives.URI()
//            uri.groupId = feed.id
            getFeedCommentsPaginationRequest = PaginationRequest<GetGroupLives>(apiClient: apiClient, uri: uri)
        }
        
        getFeedCommentsPaginationRequest?.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshFeedComments(["hello"]))
            case .next(let res):
                self.outputHandler(.getFeedComments(["hello"]))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
    }
    
    func getFeedComments() {
        getFeedCommentsPaginationRequest?.next()
    }
    
    func refreshFeedComments() {
        getFeedCommentsPaginationRequest?.next(isNext: false)
    }
}

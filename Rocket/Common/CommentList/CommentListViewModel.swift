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
        case getFeedComments([ArtistFeedComment])
        case refreshFeedComments([ArtistFeedComment])
        case postComment(ArtistFeedComment)
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let type: CommentListViewController.ListType
    let apiClient: APIClient
    let outputHandler: (Output) -> Void
    
    var getFeedCommentsPaginationRequest: PaginationRequest<GetFeedComments>? = nil

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
            var uri = GetFeedComments.URI()
            uri.feedId = feed.id
            getFeedCommentsPaginationRequest = PaginationRequest<GetFeedComments>(apiClient: apiClient, uri: uri)
        }
        
        getFeedCommentsPaginationRequest?.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.refreshFeedComments(res.items))
            case .next(let res):
                self.outputHandler(.getFeedComments(res.items))
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
    
    func postFeedComment(text: String) {
        switch self.type {
        case .feedComment(let feed):
            let request = PostFeedComment.Request(feedId: feed.id, text: text)
            apiClient.request(PostFeedComment.self, request: request) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.postComment(res))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        }
    }
}

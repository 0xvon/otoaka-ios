//
//  CommentListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/18.
//

import UIKit
import AWSCognitoAuth
import Endpoint
import Combine

class CommentListViewModel {
    struct State {
        var comments: [ArtistFeedComment] = []
        let type: CommentListViewController.ListType
    }
    
    enum Output {
        case didGetFeedComments([ArtistFeedComment])
        case didRefreshFeedComments([ArtistFeedComment])
        case didPostComment(ArtistFeedComment)
        case reportError(Error)
    }

    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var postFeedCommentAction = Action(PostFeedComment.self, httpClient: self.apiClient)
    
    var getFeedCommentsPaginationRequest: PaginationRequest<GetFeedComments>? = nil

    init(
        dependencyProvider: LoggedInDependencyProvider, type: CommentListViewController.ListType
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(type: type)
        
        switch type {
        case .feedComment(let feed):
            var uri = GetFeedComments.URI()
            uri.feedId = feed.id
            getFeedCommentsPaginationRequest = PaginationRequest<GetFeedComments>(apiClient: apiClient, uri: uri)
        }
        
        getFeedCommentsPaginationRequest?.subscribe { [unowned self] result in
            switch result {
            case .initial(let res):
                state.comments = res.items
                outputSubject.send(.didRefreshFeedComments(res.items))
            case .next(let res):
                state.comments += res.items
                outputSubject.send(.didGetFeedComments(res.items))
            case .error(let err):
                outputSubject.send(.reportError(err))
            }
        }
        
        let errors = Publishers.MergeMany(
            postFeedCommentAction.errors
        )
        
        Publishers.MergeMany(
            postFeedCommentAction.elements.map(Output.didPostComment).eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        postFeedCommentAction.elements
            .sink(receiveValue: { [unowned self] comment in
                state.comments = [comment] + state.comments
            })
            .store(in: &cancellables)
    }
    
    func getFeedComments() {
        getFeedCommentsPaginationRequest?.next()
    }
    
    func refreshFeedComments() {
        getFeedCommentsPaginationRequest?.refresh()
    }
    
    func postFeedComment(comment: String?) {
        guard let comment = comment else { return }
        switch state.type {
        case .feedComment(let feed):
            let request = PostFeedComment.Request(feedId: feed.id, text: comment)
            postFeedCommentAction.input((request: request, uri: PostFeedComment.URI()))
        }
    }
}

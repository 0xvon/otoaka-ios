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

struct Comment {
    var text: String
    var author: User
    var createdAt: Date
}

class CommentListViewModel {
    typealias Input = DataSource
    
    enum DataSource {
        case feedComment(UserFeedSummary)
        case postComment(PostSummary)
        case none
    }
    
    enum DataSourceStorage {
        case feedComment(PaginationRequest<GetUserFeedComments>, UserFeedSummary)
        case postComment(PaginationRequest<GetPostComments>, PostSummary)
        case none
        
        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .feedComment(let feed):
                var uri = GetUserFeedComments.URI()
                uri.feedId = feed.id
                let request = PaginationRequest<GetUserFeedComments>(apiClient: apiClient, uri: uri)
                self = .feedComment(request, feed)
            case .postComment(let post):
                var uri = GetPostComments.URI()
                uri.postId = post.id
                let request = PaginationRequest<GetPostComments>(apiClient: apiClient, uri: uri)
                self = .postComment(request, post)
            case .none:
                self = .none
            }
        }
    }
    
    enum Output {
        case reloadTableView
        case didPostComment
        case reportError(Error)
    }
    
    struct State {
        var comments: [Comment] = []
    }

    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private var storage: DataSourceStorage
    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var postFeedCommentAction = Action(PostUserFeedComment.self, httpClient: self.apiClient)
    private lazy var addPostCommentAction = Action(AddPostComment.self, httpClient: apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider, input: DataSource
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        self.storage = DataSourceStorage(dataSource: input, apiClient: dependencyProvider.apiClient)
        
        subscribe(storage: storage)
        
        let errors = Publishers.MergeMany(
            postFeedCommentAction.errors,
            addPostCommentAction.errors
        )
        
        Publishers.MergeMany(
            postFeedCommentAction.elements.map {_ in .didPostComment }.eraseToAnyPublisher(),
            addPostCommentAction.elements.map {_ in .didPostComment }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    private func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .feedComment(pagination, _):
            pagination.subscribe { [ weak self] in
                self?.updateState(with: $0)
            }
        case let .postComment(pagination, _):
            pagination.subscribe { [ weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<UserFeedComment>>) {
        switch result {
        case .initial(let res):
            state.comments = res.items.map { Comment(text: $0.text, author: $0.author, createdAt: $0.createdAt) }
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.comments += res.items.map { Comment(text: $0.text, author: $0.author, createdAt: $0.createdAt) }
            self.outputSubject.send(.reloadTableView)
        case .error(let err):
            self.outputSubject.send(.reportError(err))
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<PostComment>>) {
        switch result {
        case .initial(let res):
            state.comments = res.items.map { Comment(text: $0.text, author: $0.author, createdAt: $0.createdAt) }
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.comments += res.items.map { Comment(text: $0.text, author: $0.author, createdAt: $0.createdAt) }
            self.outputSubject.send(.reloadTableView)
        case .error(let err):
            self.outputSubject.send(.reportError(err))
        }
    }
    
    func inject(_ input: Input)  {
        self.storage = DataSourceStorage(dataSource: input, apiClient: apiClient)
        subscribe(storage: storage)
        refresh()
    }
    
    func refresh() {
        switch storage {
        case let .feedComment(pagination, _):
            pagination.refresh()
        case let .postComment(pagination, _):
            pagination.refresh()
        case .none:
            break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.comments.count else { return }
        switch storage {
        case let .feedComment(pagination, _):
            pagination.next()
        case let .postComment(pagination, _):
            pagination.next()
        case .none: break
        }
    }
    
    func postFeedComment(comment: String?) {
        guard let comment = comment else { return }
        switch storage {
        case let .feedComment(_, feed):
            let request = PostUserFeedComment.Request(feedId: feed.id, text: comment)
            postFeedCommentAction.input((request: request, uri: PostUserFeedComment.URI()))
        case let .postComment(_, post):
            let request = AddPostComment.Request(postId: post.id, text: comment)
            addPostCommentAction.input((request: request, uri: AddPostComment.URI()))
        case .none:
            break
        }
    }
}

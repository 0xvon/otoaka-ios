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
    typealias Input = DataSource
    
    enum DataSource {
        case feedComment(UserFeedSummary)
        case none
    }
    
    enum DataSourceStorage {
        case feedComment(PaginationRequest<GetUserFeedComments>, UserFeedSummary)
        case none
        
        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .feedComment(let feed):
                var uri = GetUserFeedComments.URI()
                uri.feedId = feed.id
                let request = PaginationRequest<GetUserFeedComments>(apiClient: apiClient, uri: uri)
                self = .feedComment(request, feed)
            case .none:
                self = .none
            }
        }
    }
    
    enum Output {
        case reloadTableView
        case didPostComment(UserFeedComment)
        case reportError(Error)
    }
    
    struct State {
        var comments: [UserFeedComment] = []
    }

    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private var storage: DataSourceStorage
    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var postFeedCommentAction = Action(PostUserFeedComment.self, httpClient: self.apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider, input: DataSource
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        self.storage = DataSourceStorage(dataSource: input, apiClient: dependencyProvider.apiClient)
        
        subscribe(storage: storage)
        
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
    
    private func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .feedComment(pagination, _):
            pagination.subscribe { [ weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<UserFeedComment>>) {
        switch result {
        case .initial(let res):
            state.comments = res.items
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.comments += res.items
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
        case .none:
            break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.comments.count else { return }
        switch storage {
        case let .feedComment(pagination, _):
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
        case .none:
            break
        }
    }
}

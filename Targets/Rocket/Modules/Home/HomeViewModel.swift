//
//  HomeViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/23.
//

import Foundation
import Combine
import Endpoint

final class HomeViewModel {
    enum Output {
        case reloadData
        case isRefreshing(Bool)
        case didDeletePost
        case didToggleLikePost
        case reportError(Error)
    }
    
    struct State {
        var posts: [PostSummary] = []
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private(set) var state: State
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var pagination = PaginationRequest<GetFollowingPosts>(apiClient: apiClient)
    private lazy var deletePostAction = Action(DeletePost.self, httpClient: apiClient)
    private lazy var likePostAction = Action(LikePost.self, httpClient: apiClient)
    private lazy var unlikePostAction = Action(UnlikePost.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        subscribe()
        
        let errors = Publishers.MergeMany(
            deletePostAction.errors,
            likePostAction.errors,
            unlikePostAction.errors
        )
        
        Publishers.MergeMany(
            deletePostAction.elements.map { _ in .didDeletePost }.eraseToAnyPublisher(),
            likePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            unlikePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    private func subscribe() {
        pagination.subscribe { [weak self] in
            self?.updateState(with: $0)
            self?.outputSubject.send(.isRefreshing(false))
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<PostSummary>>) {
        switch result {
        case .initial(let res):
            self.state.posts = res.items
            self.outputSubject.send(.reloadData)
        case .next(let res):
            self.state.posts += res.items
            self.outputSubject.send(.reloadData)
        case .error(let err):
            self.outputSubject.send(.reportError(err))
        }
    }
    
    func refresh() {
        outputSubject.send(.isRefreshing(true))
        pagination.refresh()
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.posts.count else { return }
        pagination.next()
    }
    
    func deletePost(post: PostSummary) {
        let request = DeletePost.Request(postId: post.id)
        let uri = DeletePost.URI()
        deletePostAction.input((request: request, uri: uri))
    }
    
    func likePost(post: PostSummary) {
        let request = LikePost.Request(postId: post.id)
        let uri = LikePost.URI()
        likePostAction.input((request: request, uri: uri))
    }
    
    func unlikePost(post: PostSummary) {
        let request = UnlikePost.Request(postId: post.id)
        let uri = UnlikePost.URI()
        unlikePostAction.input((request: request, uri: uri))
    }
}

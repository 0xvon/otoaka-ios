//
//  PostListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/24.
//

import UIKit
import Endpoint
import Combine

class PostListViewModel {
    typealias Input = DataSource
    enum DataSource {
        case groupPost(Group)
        case livePost(Live)
        case userPost(User)
        case likedPost(User)
        case none
    }
    
    enum DataSourceStorage {
        case groupPost(PaginationRequest<GetGroupPosts>)
        case livePost(PaginationRequest<GetLivePosts>)
        case userPost(PaginationRequest<GetPosts>)
        case likedPost(PaginationRequest<GetLikedPosts>)
        case none
        
        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .groupPost(let group):
                var uri = GetGroupPosts.URI()
                uri.groupId = group.id
                let request = PaginationRequest<GetGroupPosts>(apiClient: apiClient, uri: uri)
                self = .groupPost(request)
            case .livePost(let live):
                var uri = GetLivePosts.URI()
                uri.liveId = live.id
                let request = PaginationRequest<GetLivePosts>(apiClient: apiClient, uri: uri)
                self = .livePost(request)
            case .userPost(let user):
                var uri = GetPosts.URI()
                uri.userId = user.id
                let request = PaginationRequest<GetPosts>(apiClient: apiClient, uri: uri)
                self = .userPost(request)
            case .likedPost(let user):
                var uri = GetLikedPosts.URI()
                uri.userId = user.id
                let request = PaginationRequest<GetLikedPosts>(apiClient: apiClient, uri: uri)
                self = .likedPost(request)
            case .none:
                self = .none
            }
        }
    }
    
    struct State {
        var posts: [PostSummary] = []
    }
    
    enum Output {
        case reloadData
        case didDeletePost
        case didToggleLikePost
        case error(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    var cancellables: Set<AnyCancellable> = []

    private var storage: DataSourceStorage
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    private lazy var deletePostAction = Action(DeletePost.self, httpClient: apiClient)
    private lazy var likePostAction = Action(LikePost.self, httpClient: apiClient)
    private lazy var unlikePostAction = Action(UnlikePost.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: DataSource
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        self.storage = DataSourceStorage(dataSource: input, apiClient: dependencyProvider.apiClient)
        subscribe(storage: storage)
        
        let errors = Publishers.MergeMany(
            deletePostAction.errors,
            likePostAction.errors,
            unlikePostAction.errors
        )
        
        Publishers.MergeMany(
            deletePostAction.elements.map { _ in .didDeletePost }.eraseToAnyPublisher(),
            likePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            unlikePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    private func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .groupPost(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .livePost(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .userPost(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .likedPost(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
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
            self.outputSubject.send(.error(err))
        }
    }
    
    func inject(_ input: Input) {
        self.storage = DataSourceStorage(dataSource: input, apiClient: apiClient)
        subscribe(storage: storage)
        refresh()
    }
    
    func refresh() {
        switch storage {
        case let .groupPost(pagination):
            pagination.refresh()
        case let .livePost(pagination):
            pagination.refresh()
        case let .userPost(pagination):
            pagination.refresh()
        case let .likedPost(pagination):
            pagination.refresh()
        case .none:
            break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.posts.count else { return }
        switch storage {
        case let .groupPost(pagination):
            pagination.next()
        case let .livePost(pagination):
            pagination.next()
        case let .userPost(pagination):
            pagination.next()
        case let .likedPost(pagination):
            pagination.next()
        case .none: break
        }
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

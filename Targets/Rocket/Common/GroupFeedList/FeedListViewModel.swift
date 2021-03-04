//
//  BandContentsListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import Endpoint
import Combine

class FeedListViewModel {
    typealias Input = DataSource
    enum DataSource {
        case groupFeed(Group)
//        case uesrsFeed(User)
        case none
    }
    
    enum DataSourceStorage {
        case groupFeed(PaginationRequest<GetGroupsUserFeeds>)
        case none
        
        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .groupFeed(let group):
                var uri = GetGroupsUserFeeds.URI()
                uri.groupId = group.id
                let request = PaginationRequest<GetGroupsUserFeeds>(apiClient: apiClient, uri: uri)
                self = .groupFeed(request)
            case .none: self = .none
            }
        }
    }
    
    struct State {
        var feeds: [UserFeedSummary] = []
    }
    
    enum Output {
        case reloadData
        case didDeleteFeed
        case didToggleLikeFeed
        case error(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    var cancellables: Set<AnyCancellable> = []

    private var storage: DataSourceStorage
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    private lazy var deleteFeedAction = Action(DeleteUserFeed.self, httpClient: self.apiClient)
    private lazy var likeFeedAction = Action(LikeUserFeed.self, httpClient: apiClient)
    private lazy var unlikeFeedAction = Action(UnlikeUserFeed.self, httpClient: apiClient)


    init(
        dependencyProvider: LoggedInDependencyProvider, input: DataSource
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        self.storage = DataSourceStorage(dataSource: input, apiClient: dependencyProvider.apiClient)
        subscribe(storage: storage)
        
        let errors = Publishers.MergeMany(
            deleteFeedAction.errors,
            likeFeedAction.errors,
            unlikeFeedAction.errors
        )
        
        Publishers.MergeMany(
            deleteFeedAction.elements.map {_ in .didDeleteFeed }.eraseToAnyPublisher(),
            likeFeedAction.elements.map { _ in .didToggleLikeFeed }.eraseToAnyPublisher(),
            unlikeFeedAction.elements.map { _ in .didToggleLikeFeed }.eraseToAnyPublisher(),
            errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    private func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .groupFeed(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<UserFeedSummary>>) {
        switch result {
        case .initial(let res):
            self.state.feeds = res.items
            self.outputSubject.send(.reloadData)
        case .next(let res):
            self.state.feeds += res.items
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
        case let .groupFeed(pagination):
            pagination.refresh()
        case .none:
            break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.feeds.count else { return }
        switch storage {
        case let .groupFeed(pagination):
            pagination.next()
        case .none: break
        }
    }
    
    func deleteFeed(cellIndex: Int) {
        let feed = state.feeds[cellIndex]
        let request = DeleteUserFeed.Request(id: feed.id)
        let uri = DeleteUserFeed.URI()
        deleteFeedAction.input((request: request, uri: uri))
    }
    
    func likeFeed(cellIndex: Int) {
        let feed = state.feeds[cellIndex]
        let request = LikeUserFeed.Request(feedId: feed.id)
        let uri = LikeUserFeed.URI()
        likeFeedAction.input((request: request, uri: uri))
    }
    
    func unlikeFeed(cellIndex: Int) {
        let feed = state.feeds[cellIndex]
        let request = UnlikeUserFeed.Request(feedId: feed.id)
        let uri = UnlikeUserFeed.URI()
        unlikeFeedAction.input((request: request, uri: uri))
    }
}


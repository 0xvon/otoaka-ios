//
//  LiveListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import AWSCognitoAuth
import Endpoint
import Combine

class LiveListViewModel {
    typealias Input = DataSource
    enum Output {
        case reloadTableView
        case didToggleLikeLive
        case error(Error)
    }

    enum DataSource {
        case groupLive(Group)
        case likedLive(User.ID)
        case likedFutureLive(User.ID)
        case searchResult(String?, Group.ID?, Date?, Date?)
        case searchResultToSelect(String)
        case upcoming(User)
        case none
    }

    enum DataSourceStorage {
        case groupLive(PaginationRequest<GetGroupLives>)
        case searchResult(PaginationRequest<SearchLive>)
        case searchResultToSelect(String, PaginationRequest<SearchLive>)
        case likedLive(PaginationRequest<GetLikedLive>)
        case likedFutureLive(PaginationRequest<GetLikedFutureLive>)
        case upcoming(PaginationRequest<GetUpcomingLives>)
        case none

        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .groupLive(let group):
                var uri = GetGroupLives.URI()
                uri.groupId = group.id
                let request = PaginationRequest<GetGroupLives>(apiClient: apiClient, uri: uri)
                self = .groupLive(request)
            case .likedLive(let userId):
                var uri = GetLikedLive.URI()
                uri.userId = userId
                let request = PaginationRequest<GetLikedLive>(apiClient: apiClient, uri: uri)
                self = .likedLive(request)
            case .likedFutureLive(let userId):
                var uri = GetLikedFutureLive.URI()
                uri.userId = userId
                let request = PaginationRequest<GetLikedFutureLive>(apiClient: apiClient, uri: uri)
                self = .likedFutureLive(request)
            case .searchResult(let query, let groupId, let fromDate, let toDate):
                let dateFormatter: DateFormatter = {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "YYYYMMdd"
                    return dateFormatter
                }()
                var uri = SearchLive.URI()
                uri.term = query
                uri.groupId = groupId
                uri.fromDate = fromDate.map { dateFormatter.string(from: $0) }
                uri.toDate = toDate.map { dateFormatter.string(from: $0) }
                let request = PaginationRequest<SearchLive>(apiClient: apiClient, uri: uri)
                self = .searchResult(request)
            case .searchResultToSelect(let query):
                var uri = SearchLive.URI()
                uri.term = query
                let request = PaginationRequest<SearchLive>(apiClient: apiClient, uri: uri)
                self = .searchResultToSelect(query, request)
            case .upcoming(let user):
                var uri = GetUpcomingLives.URI()
                uri.userId = user.id
                let request = PaginationRequest<GetUpcomingLives>(apiClient: apiClient, uri: uri)
                self = .upcoming(request)
            case .none:
                self = .none
            }
        }
    }

    struct State {
        var lives: [LiveFeed] = []
    }

    private var storage: DataSourceStorage
    private(set) var state: State
    private(set) var dataSource: DataSource
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    
    private lazy var likeLiveAction = Action(LikeLive.self, httpClient: apiClient)
    private lazy var unlikeLiveAction = Action(UnlikeLive.self, httpClient: apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider, input: DataSource
    ) {
        self.dependencyProvider = dependencyProvider
        self.storage = DataSourceStorage(dataSource: input, apiClient: dependencyProvider.apiClient)
        self.dataSource = input
        self.state = State()

        subscribe(storage: storage)
        
        likeLiveAction.elements.map { _ in .didToggleLikeLive }.eraseToAnyPublisher()
            .merge(with: unlikeLiveAction.elements.map { _ in .didToggleLikeLive }.eraseToAnyPublisher())
            .merge(with: likeLiveAction.errors.map(Output.error)).eraseToAnyPublisher()
            .merge(with: unlikeLiveAction.errors.map(Output.error)).eraseToAnyPublisher()
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }

    private func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .groupLive(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .likedLive(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .likedFutureLive(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .searchResult(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .searchResultToSelect(_, pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .upcoming(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
        }
    }

    private func updateState(with result: PaginationEvent<Page<LiveFeed>>) {
        switch result {
        case .initial(let res):
            state.lives = res.items
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.lives += res.items
            self.outputSubject.send(.reloadTableView)
        case .error(let err):
            self.outputSubject.send(.error(err))
        }
    }
    
    func inject(_ input: Input) {
        self.storage = DataSourceStorage(dataSource: input, apiClient: apiClient)
        self.dataSource = input
        subscribe(storage: storage)
        refresh()
    }

    func refresh() {
        switch storage {
        case let .groupLive(pagination):
            pagination.refresh()
        case let .likedLive(pagination):
            pagination.refresh()
        case let .likedFutureLive(pagination):
            pagination.refresh()
        case let .searchResult(pagination):
            pagination.refresh()
        case let .searchResultToSelect(_, pagination):
            pagination.refresh()
        case let .upcoming(pagination):
            pagination.refresh()
        case .none: break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.lives.count else { return }
        switch storage {
        case let .groupLive(pagination):
            pagination.next()
        case let .likedLive(pagination):
            pagination.next()
        case let .likedFutureLive(pagination):
            pagination.next()
        case let .searchResult(pagination):
            pagination.next()
        case let .searchResultToSelect(_, pagination):
            pagination.next()
        case let .upcoming(pagination):
            pagination.next()
        case .none: break
        }
    }
    
    func likeLiveButtonTapped(liveFeed: LiveFeed) {
        liveFeed.isLiked ? unlikeLive(live: liveFeed.live) : likeLive(live: liveFeed.live)
    }
    
    func likeLive(live: Live) {
        let request = LikeLive.Request(liveId: live.id)
        let uri = LikeLive.URI()
        likeLiveAction.input((request: request, uri: uri))
    }
    
    func unlikeLive(live: Live) {
        let request = UnlikeLive.Request(liveId: live.id)
        let uri = UnlikeLive.URI()
        unlikeLiveAction.input((request: request, uri: uri))
    }
}

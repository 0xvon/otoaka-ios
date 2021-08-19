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
        case likedLive(User)
        case searchResult(String)
        case searchResultToSelect(String)
        case none
    }

    enum DataSourceStorage {
        case groupLive(PaginationRequest<GetGroupLives>)
        case searchResult(PaginationRequest<SearchLive>)
        case searchResultToSelect(String, PaginationRequest<SearchLive>)
        case likedLive(PaginationRequest<GetLikedLive>)
        case none

        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .groupLive(let group):
                var uri = GetGroupLives.URI()
                uri.groupId = group.id
                let request = PaginationRequest<GetGroupLives>(apiClient: apiClient, uri: uri)
                self = .groupLive(request)
            case .likedLive(let user):
                var uri = GetLikedLive.URI()
                uri.userId = user.id
                let request = PaginationRequest<GetLikedLive>(apiClient: apiClient, uri: uri)
                self = .likedLive(request)
            case .searchResult(let query):
                var uri = SearchLive.URI()
                uri.term = query
                print(query)
                let request = PaginationRequest<SearchLive>(apiClient: apiClient, uri: uri)
                self = .searchResult(request)
            case .searchResultToSelect(let query):
                var uri = SearchLive.URI()
                uri.term = query
                let request = PaginationRequest<SearchLive>(apiClient: apiClient, uri: uri)
                self = .searchResultToSelect(query, request)
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
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    
    private lazy var likeLiveAction = Action(LikeLive.self, httpClient: apiClient)
    private lazy var unlikeLiveAction = Action(UnlikeLive.self, httpClient: apiClient)

    let auth: AWSCognitoAuth
    let apiClient: APIClient

    init(
        apiClient: APIClient, input: DataSource, auth: AWSCognitoAuth
    ) {
        self.apiClient = apiClient
        self.auth = auth
        self.storage = DataSourceStorage(dataSource: input, apiClient: apiClient)
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
        case let .searchResult(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .searchResultToSelect(_, pagination):
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
        case let .searchResult(pagination):
            pagination.refresh()
        case let .searchResultToSelect(_, pagination):
            pagination.refresh()
        case .none: break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.lives.count else { return }
        switch storage {
        case let .groupLive(pagination):
            pagination.next()
        case let .likedLive(pagination):
            pagination.next()
        case let .searchResult(pagination):
            pagination.next()
        case let .searchResultToSelect(_, pagination):
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

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
        case error(Error)
    }

    enum DataSource {
        case groupLive(Group)
        case likedLive(User)
        case searchResult(String)
        case none
    }

    enum DataSourceStorage {
        case groupLive(PaginationRequest<GetGroupLives>)
        case searchResult(PaginationRequest<SearchLive>)
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
                let request = PaginationRequest<SearchLive>(apiClient: apiClient, uri: uri)
                self = .searchResult(request)
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
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    let auth: AWSCognitoAuth
    let apiClient: APIClient

    init(
        apiClient: APIClient, input: DataSource, auth: AWSCognitoAuth
    ) {
        self.apiClient = apiClient
        self.auth = auth
        self.storage = DataSourceStorage(dataSource: input, apiClient: apiClient)
        self.state = State()

        subscribe(storage: storage)
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
        case .none: break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.lives.count else { return }
        switch storage {
        case let .groupLive(pagination):
            pagination.next()
        case let .likedLive(pagination):
            pagination.refresh()
        case let .searchResult(pagination):
            pagination.next()
        case .none: break
        }
    }
}

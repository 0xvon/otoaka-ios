//
//  BandListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/28.
//

import UIKit
import AWSCognitoAuth
import Endpoint
import Combine

class GroupListViewModel {
    typealias Input = DataSource
    enum Output {
        case reloadTableView
        case error(Error)
    }

    enum DataSource {
        case memberships(User.ID)
        case followingGroups(User.ID)
        case searchResults(String)
        case none
    }

    enum DataSourceStorage {
        case followingGroups(User.ID, PaginationRequest<FollowingGroups>)
        case searchResults(String, PaginationRequest<SearchGroup>)
        case memberships(User.ID)
        case none

        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .followingGroups(let userId):
                var followingGroupsUri = FollowingGroups.URI()
                followingGroupsUri.id = userId
                let request = PaginationRequest<FollowingGroups>(apiClient: apiClient, uri: followingGroupsUri)
                self = .followingGroups(userId, request)
            case .searchResults(let query):
                var searchGroupUri = SearchGroup.URI()
                searchGroupUri.term = query
                let request = PaginationRequest<SearchGroup>(apiClient: apiClient, uri: searchGroupUri)
                self = .searchResults(query, request)
            case .memberships(let userId):
                self = .memberships(userId)
            case .none:
                self = .none
            }
        }
    }

    struct State {
        var groups: [Group] = []
    }

    private var storage: DataSourceStorage
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    
    private lazy var getMemberShipsAction = Action(GetMemberships.self, httpClient: self.apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider, input: DataSource
    ) {
        self.dependencyProvider = dependencyProvider
        self.storage = DataSourceStorage(dataSource: input, apiClient: dependencyProvider.apiClient)
        self.state = State()

        subscribe(storage: storage)
        
        getMemberShipsAction.elements
            .map { _ in .reloadTableView }.eraseToAnyPublisher()
            .merge(with: getMemberShipsAction.errors.map(Output.error)).eraseToAnyPublisher()
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
        
        getMemberShipsAction.elements
            .sink(receiveValue: { [unowned self] groups in
                state.groups = groups
            })
            .store(in: &cancellables)
    }

    private func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .followingGroups(_, pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .searchResults(_, pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .memberships, .none: break
        }
    }

    private func updateState(with result: PaginationEvent<Page<Group>>) {
        switch result {
        case .initial(let res):
            state.groups = res.items
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.groups += res.items
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
        case let .followingGroups(_, pagination):
            pagination.refresh()
        case let .searchResults(_, pagination):
            pagination.refresh()
        case .memberships(let userId):
            let request = Empty()
            var uri = Endpoint.GetMemberships.URI()
            uri.artistId = userId
            getMemberShipsAction.input((request: request, uri: uri))
        case .none: break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.groups.count else { return }
        switch storage {
        case let .followingGroups(_, pagination):
            pagination.next()
        case let .searchResults(_, pagination):
            pagination.next()
        case .memberships: break
        case .none: break
        }
    }
}

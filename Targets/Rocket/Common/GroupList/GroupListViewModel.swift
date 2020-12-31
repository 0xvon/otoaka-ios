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
    }

    enum DataSourceStorage {
        case followingGroups(User.ID, PaginationRequest<FollowingGroups>)
        case searchResults(String, PaginationRequest<SearchGroup>)
        case memberships(User.ID)

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
        case let .followingGroups(_, pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .searchResults(_, pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .memberships: break
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
            apiClient.request(GetMemberships.self, request: request, uri: uri) { [weak self] result in
                switch result {
                case .success(let res):
                    self?.state.groups = res
                    self?.outputSubject.send(.reloadTableView)
                case .failure(let error):
                    self?.outputSubject.send(.error(error))
                }
            }
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
        }
    }
}

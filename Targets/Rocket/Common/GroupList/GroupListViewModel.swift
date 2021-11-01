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
        case updateFollowing
        case error(Error)
    }

    enum DataSource {
        case followingGroups(User.ID)
        case searchResults(String)
        case searchResultsToSelect(String)
        case allGroup
        case group([GroupFeed])
        case none
    }

    enum DataSourceStorage {
        case followingGroups(User.ID, PaginationRequest<FollowingGroups>)
        case searchResults(String, PaginationRequest<SearchGroup>)
        case searchResultsToSelect(String, PaginationRequest<SearchGroup>)
        case allGroup(PaginationRequest<GetAllGroups>)
        case group([GroupFeed])
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
            case .searchResultsToSelect(let query):
                var searchGroupUri = SearchGroup.URI()
                searchGroupUri.term = query
                let request = PaginationRequest<SearchGroup>(apiClient: apiClient, uri: searchGroupUri)
                self = .searchResults(query, request)
            case .allGroup:
                let request = PaginationRequest<GetAllGroups>(apiClient: apiClient, uri: GetAllGroups.URI())
                self = .allGroup(request)
            case .group(let groups):
                self = .group(groups)
            case .none:
                self = .none
            }
        }
    }

    struct State {
        var groups: [GroupFeed] = []
    }

    private var storage: DataSourceStorage
    private(set) var state: State
    private(set) var dataSource: DataSource
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private lazy var unfollowGroupAction = Action(UnfollowGroup.self, httpClient: self.apiClient)
    private lazy var followGroupAction = Action(FollowGroup.self, httpClient: self.apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider, input: DataSource
    ) {
        self.dependencyProvider = dependencyProvider
        self.storage = DataSourceStorage(dataSource: input, apiClient: dependencyProvider.apiClient)
        self.dataSource = input
        self.state = State()
        
        let errors = Publishers.MergeMany(
            followGroupAction.errors,
            unfollowGroupAction.errors
        )
        
        Publishers.MergeMany(
            followGroupAction.elements.map { _ in .updateFollowing }.eraseToAnyPublisher(),
            unfollowGroupAction.elements.map { _ in .updateFollowing }.eraseToAnyPublisher(),
            errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)

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
        case let .searchResultsToSelect(_, pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .allGroup(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .group(groups):
            state.groups = groups
        case .none: break
        }
    }

    private func updateState(with result: PaginationEvent<Page<GroupFeed>>) {
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
        self.dataSource = input
        subscribe(storage: storage)
        refresh()
    }

    func refresh() {
        switch storage {
        case let .followingGroups(_, pagination):
            pagination.refresh()
        case let .searchResults(_, pagination):
            pagination.refresh()
        case let .searchResultsToSelect(_, pagination):
            pagination.refresh()
        case let .allGroup(pagination):
            pagination.refresh()
        case .group(_):
            outputSubject.send(.reloadTableView)
        case .none: break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.groups.count else { return }
        switch storage {
        case let .followingGroups(_, pagination):
            pagination.next()
        case let .searchResults(_, pagination):
            pagination.next()
        case let .searchResultsToSelect(_, pagination):
            pagination.next()
        case let .allGroup(pagination):
            pagination.refresh()
        case .group(_), .none: break
        }
    }
    
    func followButtonTapped(group: GroupFeed) {
        if group.isFollowing {
            let req = UnfollowGroup.Request(groupId: group.group.id)
            unfollowGroupAction.input((request: req, uri: UnfollowGroup.URI()))
        } else {
            let req = FollowGroup.Request(groupId: group.group.id)
            followGroupAction.input((request: req, uri: FollowGroup.URI()))
        }
    }
}

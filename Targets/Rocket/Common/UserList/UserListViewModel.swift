//
//  FanListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/08.
//

import UIKit
import Endpoint
import Combine

class UserListViewModel {
    typealias Input = DataSource
    
    enum DataSource {
        case followers(Group.ID)
        case userFollowers(User.ID)
        case followingUsers(User.ID)
        case liveParticipants(Live.ID)
        case searchResults(String)
        case none
    }
    
    enum DataSourceStorage {
        case followers(PaginationRequest<GroupFollowers>)
        case userFollowers(PaginationRequest<UserFollowers>)
        case followingUsers(PaginationRequest<FollowingUsers>)
        case liveParticipants(PaginationRequest<GetLiveParticipants>)
        case searchResults(PaginationRequest<SearchUser>)
        case none
        
        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .followers(let groupId):
                var uri = GroupFollowers.URI()
                uri.id = groupId
                let request = PaginationRequest<GroupFollowers>(apiClient: apiClient, uri: uri)
                self = .followers(request)
            case .userFollowers(let userId):
                var uri = UserFollowers.URI()
                uri.id = userId
                let request = PaginationRequest<UserFollowers>(apiClient: apiClient, uri: uri)
                self = .userFollowers(request)
            case .followingUsers(let userId):
                var uri = FollowingUsers.URI()
                uri.id = userId
                let request = PaginationRequest<FollowingUsers>(apiClient: apiClient, uri: uri)
                self = .followingUsers(request)
            case .liveParticipants(let liveId):
                var uri = GetLiveParticipants.URI()
                uri.liveId = liveId
                let request = PaginationRequest<GetLiveParticipants>(apiClient: apiClient, uri: uri)
                self = .liveParticipants(request)
            case .searchResults(let query):
                var uri = SearchUser.URI()
                uri.term = query
                let request = PaginationRequest<SearchUser>(apiClient: apiClient, uri: uri)
                self = .searchResults(request)
            case .none:
                self = .none
            }
        }
    }
    
    struct State {
        var users: [User] = []
    }
    
    enum Output {
        case reloadTableView
        case error(Error)
    }

    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private var storage: DataSourceStorage
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.storage = DataSourceStorage(dataSource: input, apiClient: dependencyProvider.apiClient)
        self.state = State()
                
        subscribe(storage: storage)
    }
    
    private func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .followers(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .userFollowers(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .followingUsers(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .liveParticipants(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .searchResults(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<User>>) {
        switch result {
        case .initial(let res):
            state.users = res.items
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.users += res.items
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
        case let .followers(pagination):
            pagination.refresh()
        case let .userFollowers(pagination):
            pagination.refresh()
        case let .followingUsers(pagination):
            pagination.refresh()
        case let .liveParticipants(pagination):
            pagination.refresh()
        case let .searchResults(pagination):
            pagination.refresh()
        case .none: break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.users.count else { return }
        switch storage {
        case let .followers(pagination):
            pagination.next()
        case let .userFollowers(pagination):
            pagination.next()
        case let .followingUsers(pagination):
            pagination.next()
        case let .liveParticipants(pagination):
            pagination.next()
        case let .searchResults(pagination):
            pagination.next()
        case .none: break
        }
    }
}

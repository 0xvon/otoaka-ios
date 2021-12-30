//
//  GroupRankingListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/29.
//

import UIKit
import Endpoint
import Combine

class GroupRankingListViewModel {
    typealias Input = DataSource
    enum Output {
        case reloadTableView
        case error(Error)
    }
    enum DataSource {
        case frequentlyWatching(User.ID)
        case socialTip(User.ID)
        case entriedGroup
        case none
    }
    
    struct GroupRanking {
        let group: Group
        let count: Int
        let unit: String
        
        init(group: Group, count: Int, unit: String) {
            self.group = group
            self.count = count
            self.unit = unit
        }
    }
    
    enum DataSourceStorage {
        case frequentlyWatching(PaginationRequest<FrequentlyWatchingGroups>)
        case socialTip(PaginationRequest<GetUserTipToGroupRanking>)
        case entriedGroup(PaginationRequest<GetEntriedGroups>)
        case none
        
        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .frequentlyWatching(let userId):
                var uri = FrequentlyWatchingGroups.URI()
                uri.userId = userId
                let request = PaginationRequest<FrequentlyWatchingGroups>(apiClient: apiClient, uri: uri)
                self = .frequentlyWatching(request)
            case .socialTip(let userId):
                var uri = GetUserTipToGroupRanking.URI()
                uri.userId = userId
                let request = PaginationRequest<GetUserTipToGroupRanking>(apiClient: apiClient, uri: uri)
                self = .socialTip(request)
            case .entriedGroup:
                let uri = GetEntriedGroups.URI()
                let request = PaginationRequest<GetEntriedGroups>(apiClient: apiClient, uri: uri)
                self = .entriedGroup(request)
            case .none:
                self = .none
            }
        }
    }
    
    struct State {
        var groups: [GroupRanking] = []
    }
    
    private var storage: DataSourceStorage
    private(set) var state: State
    private(set) var dataSource: DataSource
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: DataSource
    ) {
        self.dependencyProvider = dependencyProvider
        self.storage = DataSourceStorage(dataSource: input, apiClient: dependencyProvider.apiClient)
        self.dataSource = input
        self.state = State()

        subscribe(storage: storage)
    }
    
    private func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .frequentlyWatching(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .socialTip(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .entriedGroup(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<GroupFeed>>) {
        switch result {
        case .initial(let res):
            state.groups = res.items.map {
                GroupRanking(
                    group: $0.group,
                    count: $0.watchingCount,
                    unit: "回")
            }
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.groups += res.items.map {
                GroupRanking(
                    group: $0.group,
                    count: $0.watchingCount,
                    unit: "回")
            }
            self.outputSubject.send(.reloadTableView)
        case .error(let err):
            self.outputSubject.send(.error(err))
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<GroupTip>>) {
        switch result {
        case .initial(let res):
            state.groups = res.items.map {
                GroupRanking(
                    group: $0.group,
                    count: $0.tip,
                    unit: "円")
            }
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.groups += res.items.map {
                GroupRanking(
                    group: $0.group,
                    count: $0.tip,
                    unit: "円")
            }
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
        case let .frequentlyWatching(pagination):
            pagination.refresh()
        case let .socialTip(pagination):
            pagination.refresh()
        case let .entriedGroup(pagination):
            pagination.refresh()
        case .none: break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.groups.count else { return }
        switch storage {
        case let .frequentlyWatching(pagination):
            pagination.next()
        case let .socialTip(pagination):
            pagination.next()
        case let .entriedGroup(pagination):
            pagination.next()
        case .none: break
        }
    }
}

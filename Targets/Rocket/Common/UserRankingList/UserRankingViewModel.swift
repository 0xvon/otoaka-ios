//
//  UserRankingViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/29.
//

import UIKit
import Endpoint
import Combine

class UserRankingListViewModel {
    typealias Input = DataSource
    enum Output {
        case reloadTableView
        case error(Error)
    }
    enum DataSource {
        case groupTip(Group.ID)
        case none
    }
    
    struct UserRanking {
        let user: User
        let count: Int
        let unit: String
        
        init(user: User, count: Int, unit: String) {
            self.user = user
            self.count = count
            self.unit = unit
        }
    }
    
    enum DataSourceStorage {
        case groupTip(PaginationRequest<GetGroupTipFromUserRanking>)
        case none
        
        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .groupTip(let groupId):
                var uri = GetGroupTipFromUserRanking.URI()
                uri.groupId = groupId
                let request = PaginationRequest<GetGroupTipFromUserRanking>(apiClient: apiClient, uri: uri)
                self = .groupTip(request)
            case .none:
                self = .none
            }
        }
    }
    
    struct State {
        var users: [UserRanking] = []
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
        case let .groupTip(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<UserTip>>) {
        switch result {
        case .initial(let res):
            state.users = res.items.map {
                UserRanking(
                    user: $0.user,
                    count: $0.tip,
                    unit: "円")
            }
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.users += res.items.map {
                UserRanking(
                    user: $0.user,
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
        case let .groupTip(pagination):
            pagination.refresh()
        case .none: break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.users.count else { return }
        switch storage {
        case let .groupTip(pagination):
            pagination.next()
        case .none: break
        }
    }
}

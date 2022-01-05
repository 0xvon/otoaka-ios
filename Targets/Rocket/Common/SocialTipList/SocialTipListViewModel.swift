//
//  SocialTipListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/29.
//

import UIKit
import Endpoint
import Combine

class SocialTipListViewModel {
    typealias Input = DataSource
    enum Output {
        case reloadTableView
        case error(Error)
    }
    enum DataSource {
        case allTip
        case myTip(User.ID)
        case groupTip(Group.ID)
        case none
    }
    
    enum DataSourceStorage {
        case allTip(PaginationRequest<GetAllTips>)
        case myTip(PaginationRequest<GetUserTips>)
        case groupTip(PaginationRequest<GetGroupTips>)
        case none
        
        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .allTip:
                let uri = GetAllTips.URI()
                let request = PaginationRequest<GetAllTips>(apiClient: apiClient, uri: uri)
                self = .allTip(request)
            case .myTip(let userId):
                var uri = GetUserTips.URI()
                uri.userId = userId
                let request = PaginationRequest<GetUserTips>(apiClient: apiClient, uri: uri)
                self = .myTip(request)
            case .groupTip(let groupId):
                var uri = GetGroupTips.URI()
                uri.groupId = groupId
                let request = PaginationRequest<GetGroupTips>(apiClient: apiClient, uri: uri)
                self = .groupTip(request)
            case .none:
                self = .none
            }
        }
    }
    
    struct State {
        var tips: [SocialTip] = []
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
        case let .allTip(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .myTip(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .groupTip(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<SocialTip>>) {
        switch result {
        case .initial(let res):
            state.tips = res.items
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.tips += res.items
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
        case let .allTip(pagination):
            pagination.refresh()
        case let .myTip(pagination):
            pagination.refresh()
        case let .groupTip(pagination):
            pagination.refresh()
        case .none: break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.tips.count else { return }
        switch storage {
        case let .allTip(pagination):
            pagination.next()
        case let .myTip(pagination):
            pagination.next()
        case let .groupTip(pagination):
            pagination.next()
        case .none: break
        }
    }
}

//
//  GroupCollectionListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/03/16.
//

import UIKit
import Endpoint
import Combine

class GroupCollectionViewModel {
    typealias Input = DataSource
    enum DataSource {
        case all
        case none
    }
    enum Output {
        case reload
        case error(Error)
    }
    enum DataSourceStorage {
        case all(PaginationRequest<GetAllGroups>)
        case none
        
        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .all:
                let uri = GetAllGroups.URI()
                let request = PaginationRequest<GetAllGroups>(apiClient: apiClient, uri: uri)
                self = .all(request)
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
        case let .all(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<GroupFeed>>) {
        switch result {
        case .initial(let res):
            state.groups = res.items
            self.outputSubject.send(.reload)
        case .next(let res):
            state.groups += res.items
            self.outputSubject.send(.reload)
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
        case let .all(pagination):
            pagination.refresh()
        case .none: break
        }
    }
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.groups.count else { return }
        switch storage {
        case let .all(pagination):
            pagination.next()
        case .none: break
        }
    }
}

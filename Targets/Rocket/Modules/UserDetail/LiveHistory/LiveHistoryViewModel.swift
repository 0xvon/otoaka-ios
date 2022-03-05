//
//  LiveHistoryViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/03/03.
//

import UIKit
import Endpoint
import Combine

class LiveHistoryViewModel {
    typealias Input = User
    enum Output {
        case reload
        case error(Error)
    }
    struct State {
        var lives: [LiveFeed] = []
        var sections: [String] = []
        var user: User
        var sequence: Sequence = .year
    }
    enum Sequence {
        case year, group
    }
    
    enum DataSourceStorage {
        case year(PaginationRequest<GetLikedLive>)
        case group(PaginationRequest<GetLikedLive>)
        
        init(sequence: Sequence, userId: User.ID, apiClient: APIClient) {
            switch sequence {
            case .year:
                var uri = GetLikedLive.URI()
                uri.userId = userId
                uri.sort = "year"
                let request = PaginationRequest<GetLikedLive>(apiClient: apiClient, uri: uri)
                self = .year(request)
            case .group:
                var uri = GetLikedLive.URI()
                uri.userId = userId
                uri.sort = "group"
                let request = PaginationRequest<GetLikedLive>(apiClient: apiClient, uri: uri)
                self = .group(request)
            }
        }
    }
    
    private var storage: DataSourceStorage
    private(set) var state: State
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    
    private lazy var pagination: PaginationRequest<GetLikedLive> = {
        var uri = GetLikedLive.URI()
        uri.userId = state.user.id
        return PaginationRequest<GetLikedLive>(apiClient: apiClient, uri: uri)
    }()
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(user: input)
        self.storage = DataSourceStorage(sequence: .year, userId: input.id, apiClient: dependencyProvider.apiClient)
        
        subscribe(storage: storage)
    }
    
    private func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .year(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case let .group(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<LiveFeed>>) {
        switch result {
        case .initial(let res):
            updateSections(with: res.items)
            state.lives = res.items
            self.outputSubject.send(.reload)
        case .next(let res):
            updateSections(with: res.items)
            state.lives += res.items
            self.outputSubject.send(.reload)
        case .error(let err):
            self.outputSubject.send(.error(err))
        }
    }
    
    private func updateSections(with items: [LiveFeed]) {
        switch state.sequence {
        case .year:
            items.forEach {
                let item = String($0.live.date?.prefix(4) ?? "未定")
                if !state.sections.contains(item) {
                    state.sections.append(item)
                }
            }
        case .group:
            items.forEach {
                let item = $0.live.hostGroup.name
                if !state.sections.contains(item) {
                    state.sections.append(item)
                }
            }
        }
    }
    
    func sectionItems(section: String) -> [LiveFeed] {
        switch state.sequence {
        case .year:
            return state.lives.filter { String($0.live.date?.prefix(4) ?? "未定") == section }
        case .group:
            return state.lives.filter { $0.live.hostGroup.name == section }
        }
    }
    
    func inject() {
        switch state.sequence {
        case .group:
            state.sequence = .year
        case .year:
            state.sequence = .group
        }
        state.sections = []
        self.storage = DataSourceStorage(sequence: state.sequence, userId: state.user.id, apiClient: apiClient)
        subscribe(storage: storage)
        refresh()
        
    }
    
    func refresh() {
        switch storage {
        case let .year(pagination):
            pagination.refresh()
        case let .group(pagination):
            pagination.refresh()
        }
    }
    
    func willDisplay(itemAt indexPath: IndexPath) {
        guard indexPath.item + 25 > state.lives.count else { return }
        switch storage {
        case let .year(pagination):
            pagination.next()
        case let .group(pagination):
            pagination.next()
        }
    }
}

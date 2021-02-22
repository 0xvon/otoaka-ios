//
//  BandContentsListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import Endpoint
import Combine

class FeedListViewModel {
    typealias Input = DataSource
    enum DataSource {
        case groupFeed(Group)
        case none
    }
    
    enum DataSourceStorage {
        case groupFeed(PaginationRequest<GetGroupFeed>)
        case none
        
        init(dataSource: DataSource, apiClient: APIClient) {
            switch dataSource {
            case .groupFeed(let group):
                var uri = GetGroupFeed.URI()
                uri.groupId = group.id
                let request = PaginationRequest<GetGroupFeed>(apiClient: apiClient, uri: uri)
                self = .groupFeed(request)
            case .none: self = .none
            }
        }
    }
    
    struct State {
        var feeds: [ArtistFeedSummary] = []
    }
    
    enum Output {
        case reloadData
        case didDeleteFeed
        case error(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    var cancellables: Set<AnyCancellable> = []

    private var storage: DataSourceStorage
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    private lazy var deleteFeedAction = Action(DeleteArtistFeed.self, httpClient: self.apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider, input: DataSource
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        self.storage = DataSourceStorage(dataSource: input, apiClient: dependencyProvider.apiClient)
        subscribe(storage: storage)
        
        let errors = Publishers.MergeMany(
            deleteFeedAction.errors
        )
        
        Publishers.MergeMany(
            deleteFeedAction.elements.map {_ in .didDeleteFeed }.eraseToAnyPublisher(),
            errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    private func subscribe(storage: DataSourceStorage) {
        switch storage {
        case let .groupFeed(pagination):
            pagination.subscribe { [weak self] in
                self?.updateState(with: $0)
            }
        case .none: break
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<ArtistFeedSummary>>) {
        switch result {
        case .initial(let res):
            self.state.feeds = res.items
            self.outputSubject.send(.reloadData)
        case .next(let res):
            self.state.feeds += res.items
            self.outputSubject.send(.reloadData)
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
        case let .groupFeed(pagination):
            pagination.refresh()
        case .none:
            break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.feeds.count else { return }
        switch storage {
        case let .groupFeed(pagination):
            pagination.next()
        case .none: break
        }
    }
    
    func deleteFeed(cellIndex: Int) {
        let feed = state.feeds[cellIndex]
        let request = DeleteArtistFeed.Request(id: feed.id)
        let uri = DeleteArtistFeed.URI()
        deleteFeedAction.input((request: request, uri: uri))
    }
}

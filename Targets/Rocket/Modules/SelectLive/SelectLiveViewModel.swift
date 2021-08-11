//
//  SelectLiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/08/11.
//

import Foundation
import Combine
import Endpoint
import InternalDomain

final class SelectLiveViewModel {
    enum Input {
        case updateSearchQuery(String?)
    }
    
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case selectLive(Live)
        case reloadData
        case isRefreshing(Bool)
        case reportError(Error)
    }
    
    struct State {
        var lives: [LiveFeed] = []
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    
    private lazy var getUpcomingLiveAction = PaginationRequest<GetUpcomingLives>(apiClient: apiClient, uri: {
        var uri = GetUpcomingLives.URI()
        uri.userId = dependencyProvider.user.id
        return uri
    }())
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        self.getUpcomingLiveAction.subscribe { [weak self] in
            self?.outputSubject.send(.isRefreshing(false))
            self?.updateState(with: $0)
        }
    }
    
    func didSelectLive(at section: LiveFeed) {
        outputSubject.send(.selectLive(section.live))
    }
    
    private func updateState(with result: PaginationEvent<Page<LiveFeed>>) {
        switch result {
        case .initial(let res):
            state.lives = res.items
            self.outputSubject.send(.reloadData)
        case .next(let res):
            state.lives += res.items
            self.outputSubject.send(.reloadData)
        case .error(let err):
            self.outputSubject.send(.reportError(err))
        }
    }
    
    func refresh() {
        outputSubject.send(.isRefreshing(true))
        getUpcomingLiveAction.refresh()
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.lives.count else { return }
        getUpcomingLiveAction.next()
    }
    
    func updateSearchQuery(query: String?) {
        guard let query = query else { return }
        outputSubject.send(.updateSearchResult(.liveToSelect(query)))
    }
    
}

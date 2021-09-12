//
//  FilterLiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/09/12.
//

import Foundation
import Combine
import Endpoint

final class FilterLiveViewModel {
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYYMMdd"
        return dateFormatter
    }()
    
    enum Input {
        case updateSearchQuery(String?)
    }
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case reloadData
        case isRefreshing(Bool)
        case didToggleLikeLive
        case reportError(Error)
    }
    struct State {
        var lives: [LiveFeed] = []
        var groupId: Group.ID? = nil
        var fromDate: Date? = nil
        var toDate: Date? = nil
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    private lazy var searchLivePagination: PaginationRequest<SearchLive> = PaginationRequest<SearchLive>(apiClient: apiClient, uri: {
        var uri = SearchLive.URI()
        uri.groupId = state.groupId
        uri.fromDate = state.fromDate.map { dateFormatter.string(from: $0) }
        uri.toDate = state.toDate.map { dateFormatter.string(from: $0) }
        return uri
    }())
    
    private lazy var likeLiveAction = Action(LikeLive.self, httpClient: apiClient)
    private lazy var unlikeLiveAction = Action(UnlikeLive.self, httpClient: apiClient)

    init(dependencyProvider: LoggedInDependencyProvider, groupId: Group.ID?, fromDate: Date?, toDate: Date?) {
        self.dependencyProvider = dependencyProvider
        self.state = State(lives: [], groupId: groupId, fromDate: fromDate, toDate: toDate)
        
        subscribe()
        
        likeLiveAction.elements.map { _ in .didToggleLikeLive }.eraseToAnyPublisher()
            .merge(with: unlikeLiveAction.elements.map { _ in .didToggleLikeLive }.eraseToAnyPublisher())
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }
    
    func subscribe() {
        searchLivePagination.subscribe { [weak self] in
            self?.updateState(with: $0)
            self?.outputSubject.send(.isRefreshing(false))
        }
    }
    
    func updateState(with result: PaginationEvent<Page<LiveFeed>>) {
        switch result {
        case .initial(let res):
            state.lives = res.items
            outputSubject.send(.reloadData)
        case .next(let res):
            state.lives += res.items
            outputSubject.send(.reloadData)
        case .error(let err):
            outputSubject.send(.reportError(err))
        }
    }
    
    func refresh() {
        searchLivePagination.refresh()
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.lives.count else { return }
        self.outputSubject.send(.isRefreshing(true))
        searchLivePagination.next()
    }
    
    func updateSearchQuery(query: String?) {
        guard let query = query, !query.isEmpty else {
            return outputSubject.send(.updateSearchResult(.none))
        }
        outputSubject.send(.updateSearchResult(.live(query, state.groupId, state.fromDate, state.toDate)))
    }
    
    func likeLiveButtonTapped(liveFeed: LiveFeed) {
        liveFeed.isLiked ? unlikeLive(live: liveFeed.live) : likeLive(live: liveFeed.live)
    }
    
    func likeLive(live: Live) {
        let request = LikeLive.Request(liveId: live.id)
        let uri = LikeLive.URI()
        likeLiveAction.input((request: request, uri: uri))
    }
    
    func unlikeLive(live: Live) {
        let request = UnlikeLive.Request(liveId: live.id)
        let uri = UnlikeLive.URI()
        unlikeLiveAction.input((request: request, uri: uri))
    }
}


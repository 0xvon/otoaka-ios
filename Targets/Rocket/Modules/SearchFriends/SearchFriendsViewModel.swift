//
//  SearchFriendsViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/05/08.
//

import Foundation
import Combine
import Endpoint

final class SearchFriendsViewModel {
    enum Input {
        case updateSearchQuery(String?)
    }
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case reloadData
        case jumpToMessageRoom(MessageRoom)
        case isRefreshing(Bool)
        case reportError(Error)
    }
    enum Scope: Int, CaseIterable {
        case fan, live, group
        var description: String {
            switch self {
            case .fan: return "ファン"
            case .live: return "ライブ"
            case .group: return "バンド"
            }
        }
    }
    
    struct State {
        var fans: [User] = []
        var lives: [LiveFeed] = []
        var groups: [Group] = []
        var scope: Scope = .fan
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var scopes: [Scope] { Scope.allCases }
    private var cancellables: [AnyCancellable] = []
    
    private lazy var allGroupPagination: PaginationRequest<GetAllGroups> = PaginationRequest<GetAllGroups>(apiClient: apiClient, uri: GetAllGroups.URI())
    
    private lazy var upcomingLivePagination: PaginationRequest<GetUpcomingLives> = PaginationRequest<GetUpcomingLives>(apiClient: apiClient, uri: {
        var uri = GetUpcomingLives.URI()
        uri.userId = dependencyProvider.user.id
        return uri
    }())
    
    private lazy var recommendedUserPagination: PaginationRequest<RecommendedUsers> = PaginationRequest<RecommendedUsers>(apiClient: apiClient, uri: {
        var uri = RecommendedUsers.URI()
        uri.id = dependencyProvider.user.id
        return uri
    }())
    
    private lazy var createMessageRoomAction = Action(CreateMessageRoom.self, httpClient: apiClient)
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        subscribe()
        
        createMessageRoomAction.elements
            .map { .jumpToMessageRoom($0) }.eraseToAnyPublisher()
            .merge(with: createMessageRoomAction.errors.map(Output.reportError)).eraseToAnyPublisher()
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }
    
    func subscribe() {
        recommendedUserPagination.subscribe { [weak self] in
            self?.updateState(with: $0)
            self?.outputSubject.send(.isRefreshing(false))
        }
        
        upcomingLivePagination.subscribe { [weak self] in
            self?.updateState(with: $0)
            self?.outputSubject.send(.isRefreshing(false))
        }
        
        allGroupPagination.subscribe { [weak self] in
            self?.updateState(with: $0)
            self?.outputSubject.send(.isRefreshing(false))
        }
    }
    
    func updateState(with result: PaginationEvent<Page<User>>) {
        switch result {
        case .initial(let res):
            state.fans = res.items
            outputSubject.send(.reloadData)
        case .next(let res):
            state.fans += res.items
            outputSubject.send(.reloadData)
        case .error(let err):
            outputSubject.send(.reportError(err))
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
    
    func updateState(with result: PaginationEvent<Page<Group>>) {
        switch result {
        case .initial(let res):
            state.groups = res.items
            outputSubject.send(.reloadData)
        case .next(let res):
            state.groups += res.items
            outputSubject.send(.reloadData)
        case .error(let err):
            outputSubject.send(.reportError(err))
        }
    }
    
    func refresh() {
        self.outputSubject.send(.isRefreshing(true))
        
        switch state.scope {
        case .fan: recommendedUserPagination.refresh()
        case .live: upcomingLivePagination.refresh()
        case .group: allGroupPagination.refresh()
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.groups.count else { return }
        self.outputSubject.send(.isRefreshing(true))
        
        switch state.scope {
        case .fan: recommendedUserPagination.next()
        case .live: upcomingLivePagination.next()
        case .group: allGroupPagination.next()
        }
    }
    
    func updateSearchQuery(query: String?) {
        guard let query = query, query != "", query != " " else { return }
        switch state.scope {
        case .fan:
            outputSubject.send(.updateSearchResult(.user(query)))
        case .live:
            outputSubject.send(.updateSearchResult(.live(query)))
        case .group:
            outputSubject.send(.updateSearchResult(.group(query)))
        }
    }
    
    func updateScope(_ scope: Int) {
        state.scope = Scope.allCases[scope]
        refresh()
    }
    
    func createMessageRoom(partner: User) {
        let request = CreateMessageRoom.Request(members: [partner.id], name: partner.name)
        let uri = CreateMessageRoom.URI()
        createMessageRoomAction.input((request: request, uri: uri))
    }
}

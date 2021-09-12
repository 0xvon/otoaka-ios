//
//  UserViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import Foundation
import Combine
import Endpoint

final class SearchUserViewModel {
    enum Input {
        case updateSearchQuery(String?)
    }
    
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case reloadData
        case isRefreshing(Bool)
        case reportError(Error)
    }
    struct State {
        var users: [User] = []
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    private lazy var recommendedUserPagination: PaginationRequest<RecommendedUsers> = PaginationRequest<RecommendedUsers>(apiClient: apiClient, uri: {
        var uri = RecommendedUsers.URI()
        uri.id = dependencyProvider.user.id
        return uri
    }())
    
    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        subscribe()
    }
    
    func subscribe() {
        recommendedUserPagination.subscribe { [weak self] in
            self?.updateState(with: $0)
            self?.outputSubject.send(.isRefreshing(false))
        }
    }
    
    func updateState(with result: PaginationEvent<Page<User>>) {
        switch result {
        case .initial(let res):
            state.users = res.items
            outputSubject.send(.reloadData)
        case .next(let res):
            state.users += res.items
            outputSubject.send(.reloadData)
        case .error(let err):
            outputSubject.send(.reportError(err))
        }
    }
    
    func refresh() {
        recommendedUserPagination.refresh()
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.users.count else { return }
        self.outputSubject.send(.isRefreshing(true))
        recommendedUserPagination.next()
    }
    
    func updateSearchQuery(query: String?) {
        guard let query = query, !query.isEmpty else {
            return outputSubject.send(.updateSearchResult(.none))
        }
        outputSubject.send(.updateSearchResult(.user(query)))
    }
}

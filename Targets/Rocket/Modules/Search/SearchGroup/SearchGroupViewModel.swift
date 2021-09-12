//
//  GroupViewModel.swift
//  Rocket
//
//  Created by kateinoigakukun on 2021/01/05.
//

import Foundation
import Combine
import Endpoint

final class SearchGroupViewModel {

    enum Input {
        case updateSearchQuery(String?)
    }
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case reloadData
        case isRefreshing(Bool)
        case didToggleFollowGroup
        case reportError(Error)
    }
    struct State {
        var groups: [GroupFeed] = []
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    private lazy var allGroupPagination: PaginationRequest<GetAllGroups> = PaginationRequest<GetAllGroups>(apiClient: apiClient, uri: GetAllGroups.URI())
    
    private lazy var unfollowGroupAction = Action(UnfollowGroup.self, httpClient: self.apiClient)
    private lazy var followGroupAction = Action(FollowGroup.self, httpClient: self.apiClient)

    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        subscribe()
        
        followGroupAction.elements.map { _ in .didToggleFollowGroup }.eraseToAnyPublisher()
            .merge(with: unfollowGroupAction.elements.map { _ in .didToggleFollowGroup }.eraseToAnyPublisher())
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }
    
    func subscribe() {
        allGroupPagination.subscribe { [weak self] in
            self?.updateState(with: $0)
            self?.outputSubject.send(.isRefreshing(false))
        }
    }
    
    func updateState(with result: PaginationEvent<Page<GroupFeed>>) {
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
        allGroupPagination.refresh()
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.groups.count else { return }
        self.outputSubject.send(.isRefreshing(true))
        allGroupPagination.next()
    }
    
    func updateSearchQuery(query: String?) {
        guard let query = query, !query.isEmpty else {
            return outputSubject.send(.updateSearchResult(.none))
        }
        outputSubject.send(.updateSearchResult(.group(query)))
    }
    
    func followButtonTapped(group: GroupFeed) {
        if group.isFollowing {
            let req = UnfollowGroup.Request(groupId: group.group.id)
            unfollowGroupAction.input((request: req, uri: UnfollowGroup.URI()))
        } else {
            let req = FollowGroup.Request(groupId: group.group.id)
            followGroupAction.input((request: req, uri: FollowGroup.URI()))
        }
    }
}

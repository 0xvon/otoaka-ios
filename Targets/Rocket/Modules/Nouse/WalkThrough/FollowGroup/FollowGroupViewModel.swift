//
//  FollowGroupViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/07/04.
//

import Foundation
import Combine
import Endpoint

final class FollowGroupViewModel {

    enum Input {
        case updateSearchQuery(String?)
    }
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case reloadData
        case updateFollowing
        case isRefreshing(Bool)
        case error(Error)
    }
    
    struct State {
        var groups: [GroupFeed] = []
    }
    
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    
    let dependencyProvider: LoggedInDependencyProvider
    lazy var getAllPagination = PaginationRequest<Endpoint.GetAllGroups>(apiClient: dependencyProvider.apiClient)
    lazy var followGroupAction = Action(FollowGroup.self, httpClient: dependencyProvider.apiClient)
    lazy var unfollowGroupAction = Action(UnfollowGroup.self, httpClient: dependencyProvider.apiClient)

    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.state = State()

        self.subscribe()
        
        followGroupAction.elements.map {
            _ in .updateFollowing
        }.eraseToAnyPublisher()
        .merge(with: followGroupAction.errors.map(Output.error).eraseToAnyPublisher())
        .merge(with: unfollowGroupAction.elements.map {
            _ in .updateFollowing
        }.eraseToAnyPublisher())
        .merge(with: unfollowGroupAction.errors.map(Output.error).eraseToAnyPublisher())
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    private func subscribe() {
        getAllPagination.subscribe { [weak self] in
            self?.updateState(with: $0)
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<GroupFeed>>) {
        switch result {
        case .initial(let res):
            state.groups = res.items
            self.outputSubject.send(.reloadData)
        case .next(let res):
            state.groups += res.items
            self.outputSubject.send(.reloadData)
        case .error(let err):
            self.outputSubject.send(.error(err))
        }
    }
    
    func refresh() {
        getAllPagination.refresh()
    }
    
    func followGroup(index: Int) {
        var group = state.groups[index]
        if group.isFollowing {
            let req = UnfollowGroup.Request(groupId: group.group.id)
            unfollowGroupAction.input((request: req, uri: UnfollowGroup.URI()))
        } else {
            let req = FollowGroup.Request(groupId: group.group.id)
            followGroupAction.input((request: req, uri: FollowGroup.URI()))
        }
        
        group.isFollowing.toggle()
        updateGroup(group: group)
    }
    
    func updateGroup(group: GroupFeed) {
        if let idx = state.groups.firstIndex(where: { $0.group.id == group.group.id }) {
            state.groups[idx] = group
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.groups.count else { return }
        getAllPagination.next()
    }
}

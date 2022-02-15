//
//  OrganizeRecentlyFollowingViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/15.
//

import Endpoint
import UIKit
import Combine

class OrganizeRecentlyFollowingViewModel {
    typealias Input = [GroupFeed]
    enum Output {
        case reloadTableView
        case updateParty
        case completed
        case partyIsFull
        case error(Error)
    }
    
    struct State {
        var party: [GroupFeed]
        var followingGroups: [GroupFeed] = []
    }
    
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private lazy var followingGroupPagination = PaginationRequest<FollowingGroups>(apiClient: apiClient, uri: {
        var uri = FollowingGroups.URI()
        uri.id = dependencyProvider.user.id
        return uri
    }())
    private lazy var updateRecentlyFollowingAction = Action(UpdateRecentlyFollowing.self, httpClient: self.apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(party: input)
        
        subscribe()
        
        updateRecentlyFollowingAction.elements.map { _ in
            Output.completed
        }.eraseToAnyPublisher()
            .merge(with: updateRecentlyFollowingAction.errors.map(Output.error))
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }
    
    func subscribe() {
        followingGroupPagination.subscribe { [weak self] in
            self?.updateState(with: $0)
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<GroupFeed>>) {
        switch result {
        case .initial(let res):
            state.followingGroups = res.items
            self.outputSubject.send(.reloadTableView)
        case .next(let res):
            state.followingGroups += res.items
            self.outputSubject.send(.reloadTableView)
        case .error(let err):
            self.outputSubject.send(.error(err))
        }
    }
    
    func refresh() {
        followingGroupPagination.refresh()
        outputSubject.send(.updateParty)
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.followingGroups.count else { return }
        followingGroupPagination.next()
    }
    
    func groupTapped(_ group: GroupFeed) {
        if state.party.map({ $0.group.id }).contains(group.group.id) {
            removeFromParty(group)
        } else {
            addToParty(group)
        }
    }
    
    func addToParty(_ group: GroupFeed) {
        if state.party.count >= 5 {
            outputSubject.send(.partyIsFull)
        } else {
            self.state.party += [group]
            outputSubject.send(.updateParty)
        }
    }
    
    func removeFromParty(_ group: GroupFeed) {
        self.state.party = self.state.party.filter { $0.group.id != group.group.id }
        outputSubject.send(.updateParty)
    }
    
    func registerButtonTapped() {
        let request = UpdateRecentlyFollowing.Request(groups: state.party.map { $0.group.id })
        let uri = UpdateRecentlyFollowing.URI()
        updateRecentlyFollowingAction.input((request: request, uri: uri))
    }
}

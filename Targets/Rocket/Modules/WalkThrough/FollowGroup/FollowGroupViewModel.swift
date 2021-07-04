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
        case isRefreshing(Bool)
        case error(Error)
    }
    
    struct State {
        var groups: [Group] = []
    }
    
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    
    let dependencyProvider: LoggedInDependencyProvider
    lazy var getAllPagination = PaginationRequest<Endpoint.GetAllGroups>(apiClient: dependencyProvider.apiClient)
    lazy var followGroupAction = Action(FollowGroup.self, httpClient: dependencyProvider.apiClient)

    private var cancellables: [AnyCancellable] = []

    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.state = State()

        self.subscribe()
        
        followGroupAction.elements.map {
            _ in .reloadData
        }.eraseToAnyPublisher()
        .merge(with: followGroupAction.errors.map(Output.error).eraseToAnyPublisher())
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    private func subscribe() {
        getAllPagination.subscribe { [weak self] in
            self?.updateState(with: $0)
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<Group>>) {
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
        let group = state.groups[index]
        let request = FollowGroup.Request(groupId: group.id)
        let uri = FollowGroup.URI()
        followGroupAction.input((request: request, uri: uri))
        state.groups = state.groups.filter { $0.id != group.id }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.groups.count else { return }
        getAllPagination.next()
    }
}

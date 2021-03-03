//
//  SelectGroupViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/03.
//

import Foundation
import Combine
import Endpoint
import InternalDomain

final class SelectGroupViewModel {
    enum Input {
        case updateSearchQuery(String?)
    }
    
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case selectGroup(Group)
        case reloadData
        case isRefreshing(Bool)
        case reportError(Error)
    }
    
    struct State {
        var groups: [Group] = []
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []

    private var getAllGroupsAction: PaginationRequest<GetAllGroups>
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        self.getAllGroupsAction = PaginationRequest<GetAllGroups>(apiClient: dependencyProvider.apiClient)
        
        self.getAllGroupsAction.subscribe { [weak self] in
            self?.outputSubject.send(.isRefreshing(false))
            self?.updateState(with: $0)
        }
    }
    
    func didSelectGroup(at section: Group) {
        outputSubject.send(.selectGroup(section))
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
            self.outputSubject.send(.reportError(err))
        }
    }
    
    func refresh() {
        outputSubject.send(.isRefreshing(true))
        getAllGroupsAction.refresh()
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.groups.count else { return }
        getAllGroupsAction.next()
    }
    
    func updateSearchQuery(query: String?) {
        guard let query = query else { return }
        outputSubject.send(.updateSearchResult(.groupToSelect(query)))
    }
}

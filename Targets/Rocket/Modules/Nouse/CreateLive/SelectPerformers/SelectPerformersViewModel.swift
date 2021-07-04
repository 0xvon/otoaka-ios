//
//  SearchBandViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/01.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent
import UIKit

class SelectPerformersViewModel {
    struct State {
        var selected: [Group]
        var searchResult: [Group] = []
    }
    
    enum Output {
        case didPaginate([Group])
        case didSearch([Group])
        case didSelectPerformer(Group)
        case reportError(Error)
    }
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    var searchGroupPaginationRequest: PaginationRequest<SearchGroup>? = nil

    init(
        dependencyProvider: LoggedInDependencyProvider,
        selected: [Group]
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(selected: selected)
    }
    
    func didSelectPerformer(group: Group) {
        outputSubject.send(.didSelectPerformer(group))
    }
    
    func searchGroup(query: String) {
        var uri = SearchGroup.URI()
        uri.term = query
        searchGroupPaginationRequest = PaginationRequest<SearchGroup>(apiClient: apiClient, uri: uri)
        
        searchGroupPaginationRequest?.subscribe { [weak self] result in
            switch result {
            case .initial(let res):
                self?.state.searchResult = res.items
                self?.outputSubject.send(.didSearch(res.items))
            case .next(let res):
                self?.state.searchResult += res.items
                self?.outputSubject.send(.didPaginate(res.items))
            case .error(let err):
                self?.outputSubject.send(.reportError(err))
            }
        }
        
        searchGroupPaginationRequest?.next()
    }
    
    func paginateGroup() {
        searchGroupPaginationRequest?.next()
    }
    
    func refreshSearchGroup() {
        searchGroupPaginationRequest?.refresh()
    }
}


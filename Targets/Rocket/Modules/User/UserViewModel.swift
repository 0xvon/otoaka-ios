//
//  UserViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import Foundation
import Combine
import Endpoint

final class UserViewModel {
    enum Input {
        case updateSearchQuery(String?)
    }

    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case reloadData
        case isRefreshing(Bool)
    }
    enum Scope: Int, CaseIterable {
        case all
    }

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    private var cancellables: [AnyCancellable] = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
    }
    
    func updateSearchQuery(query: String?) {
        guard let query = query, !query.isEmpty else {
            return outputSubject.send(.updateSearchResult(.none))
        }
        outputSubject.send(.updateSearchResult(.user(query)))
    }
}

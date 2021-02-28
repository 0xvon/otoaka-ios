//
//  SearchViewModel.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/31.
//

import Foundation
import Combine

final class SearchViewModel {
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
    }

    enum Scope: CaseIterable {
        case live, group, user
        var title: String {
            switch self {
            case .live: return "ライブ"
            case .group: return "バンド"
            case .user: return "ユーザー"
            }
        }
    }
    var scopeButtonTitles: [String] {
        Scope.allCases.map(\.title)
    }

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    func updateSearchResults(queryText: String?, scopeIndex: Int) {
        let scope = Scope.allCases[scopeIndex]
        guard let query = queryText, !query.isEmpty else {
            outputSubject.send(.updateSearchResult(.none))
            return
        }
        switch scope {
        case .group:
            outputSubject.send(.updateSearchResult(.group(query)))
        case .live:
            outputSubject.send(.updateSearchResult(.live(query)))
        case .user:
            outputSubject.send(.updateSearchResult(.user(query)))
        }
    }
}

//
//  LiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/20.
//

import Foundation
import Combine
import Endpoint

final class SearchLiveViewModel {
    enum Input {
        case UpdateSearchQuery(String?)
    }
    
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case updateFilterCondition
    }
    
    struct State {
        var group: GroupFeed? = nil
        var fromDate: Date? = nil
        var toDate: Date? = nil
    }
    
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    func updateSearchResults(queryText: String?) {
        if let text = queryText {
            outputSubject.send(.updateSearchResult(.live(text, nil, nil, nil)))
        }
    }
    
    init() {
        self.state = State()
    }
    
    func updateGroup(group: GroupFeed) {
        state.group = group
        outputSubject.send(.updateFilterCondition)
    }
    
    func updateDate(fromDate: Date?, toDate: Date?) {
        state.fromDate = fromDate
        state.toDate = toDate
        outputSubject.send(.updateFilterCondition)
    }
}

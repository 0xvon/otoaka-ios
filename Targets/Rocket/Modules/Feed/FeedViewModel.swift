//
//  FeedViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/01/06.
//

import Foundation
import Combine
import Endpoint

final class FeedViewModel {
    enum Output {
        case reloadData
        case isRefreshing(Bool)
        case reportError(Error)
    }
    
    enum Scope: Int, CaseIterable {
        case all
    }
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never>
    private var _feeds = CurrentValueSubject<[ArtistFeedSummary], Never>([])
    var feeds: [ArtistFeedSummary] { _feeds.value }
    
    let refresh = PassthroughSubject<Void, Never>()
    let updateScope = PassthroughSubject<Int, Never>()
    let willDisplayCell = PassthroughSubject<IndexPath, Never>()
    
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        let getAllPagination = PaginationRequest<Endpoint.GetFollowingGroupFeeds>(apiClient: dependencyProvider.apiClient)
        
        let feeds = getAllPagination.items()
            .multicast(subject: self._feeds)
        
        let isRefreshing = getAllPagination.isRefreshing
            .map(Output.isRefreshing)
        
        let scope = updateScope.map { Scope.allCases[$0] }.prepend(.all)
        
        let reloadData = feeds.map { _ in Output.reloadData }
        
        refresh.prepend(()).combineLatest(scope) { $1 }.sink { scope in
            switch scope {
            case .all:
                getAllPagination.refresh()
            }
        }.store(in: &cancellables)
        
        willDisplayCell.combineLatest(feeds)
            .filter { indexPath, feeds in indexPath.row + 25 > feeds.count }
            .combineLatest(scope, { $1 })
            .sink { scope in
                switch scope {
                case .all:
                    getAllPagination.next()
                }
            }.store(in: &cancellables)
        
        feeds.connect().store(in: &cancellables)
        self.output = reloadData.merge(with: isRefreshing).eraseToAnyPublisher()
    }
}

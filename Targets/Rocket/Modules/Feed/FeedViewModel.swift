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
        case didDeleteFeed
        case reportError(Error)
    }
    
    enum Scope: Int, CaseIterable {
        case following
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never>
    private var _feeds = CurrentValueSubject<[UserFeedSummary], Never>([])
    var feeds: [UserFeedSummary] { _feeds.value }
    
    let refresh = PassthroughSubject<Void, Never>()
    let updateScope = PassthroughSubject<Int, Never>()
    let willDisplayCell = PassthroughSubject<IndexPath, Never>()
    
    private lazy var deleteFeedAction = Action(DeleteUserFeed.self, httpClient: self.apiClient)
    
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        
        let getAllPagination = PaginationRequest<Endpoint.GetFollowingUserFeeds>(apiClient: dependencyProvider.apiClient)
        
        let feeds = getAllPagination.items()
            .multicast(subject: self._feeds)
        
        let isRefreshing = getAllPagination.isRefreshing
            .map(Output.isRefreshing)
        
        let scope = updateScope.map { Scope.allCases[$0] }.prepend(.following)
        
        let reloadData = feeds.map { _ in Output.reloadData }
        
        refresh.prepend(()).combineLatest(scope) { $1 }.sink { scope in
            switch scope {
            case .following:
                getAllPagination.refresh()
            }
        }.store(in: &cancellables)
        
        willDisplayCell.combineLatest(feeds)
            .filter { indexPath, feeds in indexPath.row + 25 > feeds.count }
            .combineLatest(scope, { $1 })
            .sink { scope in
                switch scope {
                case .following:
                    getAllPagination.next()
                }
            }.store(in: &cancellables)
        
        feeds.connect().store(in: &cancellables)
        
        self.output = reloadData
            .merge(with: isRefreshing).eraseToAnyPublisher()
        
        self.output.merge(with: deleteFeedAction.elements.map { _ in .didDeleteFeed }).eraseToAnyPublisher()
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }
    
    func deleteFeed(feed: UserFeedSummary) {
        let request = DeleteUserFeed.Request(id: feed.id)
        let uri = DeleteUserFeed.URI()
        deleteFeedAction.input((request: request, uri: uri))
    }
}

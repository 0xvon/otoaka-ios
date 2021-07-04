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
        case updateSearchResult(SearchResultViewController.Input)
        case isRefreshing(Bool)
        case didDeleteFeed
        case didToggleLikeFeed
        case reportError(Error)
    }
    
    enum Scope: Int, CaseIterable {
        case all, following
        var description: String {
            switch self {
            case .all: return "すべて"
            case .following: return "フォロー中"
            }
        }
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never>
    private var _feeds = CurrentValueSubject<[UserFeedSummary], Never>([])
    var feeds: [UserFeedSummary] { _feeds.value }
    var scopes: [Scope] { Scope.allCases }
    
    let refresh = PassthroughSubject<Void, Never>()
    let updateScope = PassthroughSubject<Int, Never>()
    let willDisplayCell = PassthroughSubject<IndexPath, Never>()
    
    let updateSearchQuery = PassthroughSubject<String?, Never>()
    private lazy var deleteFeedAction = Action(DeleteUserFeed.self, httpClient: self.apiClient)
    private lazy var likeFeedAction = Action(LikeUserFeed.self, httpClient: apiClient)
    private lazy var unlikeFeedAction = Action(UnlikeUserFeed.self, httpClient: apiClient)
    
    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        
        let getAllPagination = PaginationRequest<Endpoint.GetAllUserFeeds>(apiClient: dependencyProvider.apiClient)
        let getFollowingPagination = PaginationRequest<Endpoint.GetFollowingUserFeeds>(apiClient: dependencyProvider.apiClient)
        
        let updateSearchResult = updateSearchQuery.map { queryText -> Output in
            guard let query  = queryText, !query.isEmpty else { return .updateSearchResult(.user("")) }
            return .updateSearchResult(.user(query))
        }
        .eraseToAnyPublisher()
        
        let feeds = getAllPagination.items()
            .merge(with: getFollowingPagination.items())
            .multicast(subject: self._feeds)
        
        let isRefreshing = getAllPagination.isRefreshing
            .merge(with: getFollowingPagination.isRefreshing)
            .map(Output.isRefreshing)
        
        let reloadData = feeds.map { _ in Output.reloadData }
        
        let scope = updateScope.map { Scope.allCases[$0] }.prepend(.all)
        
        refresh.prepend(()).combineLatest(scope) { $1 }.sink { scope in
            switch scope {
            case .all:
                getAllPagination.refresh()
            case .following:
                getFollowingPagination.refresh()
            }
        }.store(in: &cancellables)
        
        willDisplayCell.combineLatest(feeds)
            .filter { indexPath, feeds in indexPath.row + 25 > feeds.count }
            .combineLatest(scope, { $1 })
            .sink { scope in
                switch scope {
                case .all:
                    getAllPagination.next()
                case .following:
                    getFollowingPagination.next()
                }
            }.store(in: &cancellables)
        
        feeds.connect().store(in: &cancellables)
        
        self.output = reloadData
            .merge(with: isRefreshing, updateSearchResult).eraseToAnyPublisher()
        
        self.output.merge(with: deleteFeedAction.elements.map { _ in .didDeleteFeed }).eraseToAnyPublisher()
            .merge(with: likeFeedAction.elements.map { _ in .didToggleLikeFeed }.eraseToAnyPublisher())
            .merge(with: unlikeFeedAction.elements.map { _ in .didToggleLikeFeed }.eraseToAnyPublisher())
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }
    
    func deleteFeed(feed: UserFeedSummary) {
        let request = DeleteUserFeed.Request(id: feed.id)
        let uri = DeleteUserFeed.URI()
        deleteFeedAction.input((request: request, uri: uri))
    }
    
    func likeFeed(cellIndex: Int) {
        let feed = feeds[cellIndex]
        let request = LikeUserFeed.Request(feedId: feed.id)
        let uri = LikeUserFeed.URI()
        likeFeedAction.input((request: request, uri: uri))
    }
    
    func unlikeFeed(cellIndex: Int) {
        let feed = feeds[cellIndex]
        let request = UnlikeUserFeed.Request(feedId: feed.id)
        let uri = UnlikeUserFeed.URI()
        unlikeFeedAction.input((request: request, uri: uri))
    }
}

//
//  PickupViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/01.
//

import Combine
import Endpoint
import Foundation

class PickupViewModel {
    struct State {
        var recommendedGroups: [GroupFeed] = []
        var upcomingLives: [LiveFeed] = []
//        var groupRanking: [GroupTip] = []
//        var socialTipEvents: [SocialTipEvent] = []
    }
    enum Output {
        case didGetRecommendedGroups
        case didGetUpcomingLives
//        case didGetGroupRanking
//        case didGetSocialTipEvents
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    
    private lazy var allGroupPagination: PaginationRequest<GetAllGroups> = PaginationRequest<GetAllGroups>(apiClient: apiClient, uri: GetAllGroups.URI())
    private lazy var upcomingLivePagination: PaginationRequest<SearchLive> = PaginationRequest<SearchLive>(apiClient: apiClient, uri: {
        let date = Date()
        let from = date.addingTimeInterval(-60 * 60 * 24 * 1)
        let to = date.addingTimeInterval(60 * 60 * 24 * 1)
        var uri = SearchLive.URI()
        uri.fromDate = from.toFormatString(format: "yyyyMMdd")
        uri.toDate = to.toFormatString(format: "yyyyMMdd")
        uri.per = 20
        uri.page = 1
        return uri
    }())
    private lazy var socialTipEventPagination: PaginationRequest<GetSocialTipEvent> = PaginationRequest<GetSocialTipEvent>(apiClient: apiClient, uri: GetSocialTipEvent.URI())
    private lazy var rankingPagination: PaginationRequest<GetDailyGroupRanking> = PaginationRequest<GetDailyGroupRanking>(apiClient: apiClient, uri: GetDailyGroupRanking.URI())
    
    private lazy var unfollowGroupAction = Action(UnfollowGroup.self, httpClient: self.apiClient)
    private lazy var followGroupAction = Action(FollowGroup.self, httpClient: self.apiClient)
    private lazy var likeLiveAction = Action(LikeLive.self, httpClient: apiClient)
    private lazy var unlikeLiveAction = Action(UnlikeLive.self, httpClient: apiClient)
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        subscribe()
    }
    
    func subscribe() {
        allGroupPagination.subscribe { [weak self] in
            self?.updateState(with: $0)
        }
        
        upcomingLivePagination.subscribe { [weak self] in
            self?.updateState(with: $0)
        }
        
//        socialTipEventPagination.subscribe { [weak self] in
//            self?.updateState(with: $0)
//        }
//
//        rankingPagination.subscribe { [weak self] in
//            self?.updateState(with: $0)
//        }
    }
    
    func refresh() {
        allGroupPagination.refresh()
        upcomingLivePagination.refresh()
//        socialTipEventPagination.refresh()
//        rankingPagination.refresh()
    }
    
    func updateState(with result: PaginationEvent<Page<GroupFeed>>) {
        switch result {
        case .initial(let res):
            state.recommendedGroups = res.items
            outputSubject.send(.didGetRecommendedGroups)
        case .next(let res):
            state.recommendedGroups += res.items
            outputSubject.send(.didGetRecommendedGroups)
        case .error(let err):
            outputSubject.send(.reportError(err))
        }
    }
    
    func updateState(with result: PaginationEvent<Page<LiveFeed>>) {
        switch result {
        case .initial(let res):
            state.upcomingLives = res.items.reversed()
            outputSubject.send(.didGetUpcomingLives)
        case .next(let res):
            state.upcomingLives += res.items.reversed()
            outputSubject.send(.didGetUpcomingLives)
        case .error(let err):
            outputSubject.send(.reportError(err))
        }
    }
    
//    func updateState(with result: PaginationEvent<Page<SocialTipEvent>>) {
//        switch result {
//        case .initial(let res):
//            state.socialTipEvents = res.items
//            outputSubject.send(.didGetSocialTipEvents)
//        case .next(let res):
//            state.socialTipEvents += res.items
//            outputSubject.send(.didGetSocialTipEvents)
//        case .error(let err):
//            outputSubject.send(.reportError(err))
//        }
//    }
//
//    func updateState(with result: PaginationEvent<Page<GroupTip>>) {
//        switch result {
//        case .initial(let res):
//            state.groupRanking = res.items
//            outputSubject.send(.didGetGroupRanking)
//        case .next(let res):
//            state.groupRanking += res.items
//            outputSubject.send(.didGetGroupRanking)
//        case .error(let err):
//            outputSubject.send(.reportError(err))
//        }
//    }
    
    func followButtonTapped(group: GroupFeed) {
        if group.isFollowing {
            let req = UnfollowGroup.Request(groupId: group.group.id)
            unfollowGroupAction.input((request: req, uri: UnfollowGroup.URI()))
        } else {
            let req = FollowGroup.Request(groupId: group.group.id)
            followGroupAction.input((request: req, uri: FollowGroup.URI()))
        }
    }
    
    func likeLiveButtonTapped(liveFeed: LiveFeed) {
        if liveFeed.isLiked {
            let request = UnlikeLive.Request(liveId: liveFeed.live.id)
            let uri = UnlikeLive.URI()
            unlikeLiveAction.input((request: request, uri: uri))
        } else {
            let request = LikeLive.Request(liveId: liveFeed.live.id)
            let uri = LikeLive.URI()
            likeLiveAction.input((request: request, uri: uri))
        }
    }
}

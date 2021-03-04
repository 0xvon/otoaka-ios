//
//  LiveDetailViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/24.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent

class LiveDetailViewModel {
    enum DisplayType {
        case fan
        case group
        case host
    }
    enum SummaryRow {
        case feed, performers(Group)
    }
    struct State {
        var live: Live
        var feeds: [UserFeedSummary] = []
        let role: RoleProperties
    }
    
    enum Output {
        case didGetLiveDetail(LiveDetail)
        case didGetDisplayType(DisplayType)
        case updateFeedSummary(UserFeedSummary?)
        case updatePerformers([Group])
        case didDeleteFeed
        
        case didDeleteFeedButtonTapped(UserFeedSummary)
        case didShareFeedButtonTapped(UserFeedSummary)
        case pushToGroupFeedList(FeedListViewController.Input)
        case pushToPerformerDetail(BandDetailViewController.Input)
        case presentCommentList(CommentListViewController.Input)
        case openURLInBrowser(URL)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private lazy var getLive = Action(GetLive.self, httpClient: self.apiClient)
    private lazy var getGroup = Action(GetGroup.self, httpClient: self.apiClient)
    private lazy var getGroupFeed = Action(GetGroupsUserFeeds.self, httpClient: self.apiClient)
    private lazy var deleteFeed = Action(DeleteUserFeed.self, httpClient: self.apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider, live: Live
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(live: live, role: dependencyProvider.user.role)
        
        let errors = Publishers.MergeMany(
            getLive.errors,
            getGroup.errors,
            getGroupFeed.errors,
            deleteFeed.errors
        )
        
        Publishers.MergeMany(
            getLive.elements.map(Output.didGetLiveDetail).eraseToAnyPublisher(),
            getGroup.elements.map { result in
                let displayType: DisplayType = {
                    switch self.state.role {
                    case .fan(_):
                        return .fan
                    case .artist(_):
                        return result.isMember ? .host : .group
                    }
                }()
                return .didGetDisplayType(displayType)
            }.eraseToAnyPublisher(),
            getGroupFeed.elements.map { result in
                .updateFeedSummary(result.items.first)
            }.eraseToAnyPublisher(),
            deleteFeed.elements.map { _ in .didDeleteFeed }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getLive.elements
            .combineLatest(getGroupFeed.elements)
            .sink(receiveValue: { [unowned self] liveDetail, feeds in
                state.feeds = feeds.items
                outputSubject.send(.updatePerformers(liveDetail.live.performers))
            })
            .store(in: &cancellables)
    }
    
    func didTapSeeMore(at row: SummaryRow) {
        switch row {
        case .feed:
            outputSubject.send(.pushToGroupFeedList(.groupFeed(state.live.hostGroup)))
        default:
            break
        }
    }
    
    func didSelectRow(at row: SummaryRow) {
        switch row {
        case .feed:
            guard let feed = state.feeds.first else { return }
            switch feed.feedType {
            case .youtube(let url):
                outputSubject.send(.openURLInBrowser(url))
            }
        case .performers(let group):
            outputSubject.send(.pushToPerformerDetail(group))
        }
    }
    
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getLiveDetail()
        getHostGroup()
        getGroupFeedSummary()
    }
    
    func feedCellEvent(event: UserFeedCellContent.Output) {
        switch event {
        case .commentButtonTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.presentCommentList(.feedComment(feed)))
        case .deleteFeedButtonTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.didDeleteFeedButtonTapped(feed))
        case .likeFeedButtonTapped: break
        case .unlikeFeedButtonTapped: break
        case .shareButtonTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.didShareFeedButtonTapped(feed))
        }
    }
    
    func getLiveDetail() {
        var uri = GetLive.URI()
        uri.liveId = self.state.live.id
        let req = Empty()
        getLive.input((request: req, uri: uri))
    }
    
    func getHostGroup() {
        var uri = GetGroup.URI()
        uri.groupId = state.live.hostGroup.id
        getGroup.input((request: Empty(), uri: uri))
    }
    
    func getGroupFeedSummary() {
        var uri = GetGroupsUserFeeds.URI()
        uri.groupId = state.live.hostGroup.id
        uri.per = 1
        uri.page = 1
        let request = Empty()
        getGroupFeed.input((request: request, uri: uri))
    }
    
    func deleteFeed(feed: UserFeedSummary) {
        let request = DeleteUserFeed.Request(id: feed.id)
        let uri = DeleteUserFeed.URI()
        deleteFeed.input((request: request, uri: uri))
    }
    
    //    func likeLive() {
    //        let request = LikeLive.Request(liveId: self.live.id)
    //        apiClient.request(LikeLive.self, request: request) { result in
    //            switch result {
    //            case .success(_):
    //                self.outputHandler(.likeLive)
    //            case .failure(let error):
    //                self.outputHandler(.error(error))
    //            }
    //        }
    //    }
    //
    //    func unlikeLive() {
    //        let request = UnlikeLive.Request(liveId: self.live.id)
    //        apiClient.request(UnlikeLive.self, request: request) { result in
    //            switch result {
    //            case .success(_):
    //                self.outputHandler(.unlikeLive)
    //            case .failure(let error):
    //                self.outputHandler(.error(error))
    //            }
    //        }
    //    }
}

extension Live {
    var performers: [Group] {
        switch style {
        case .oneman(let performer):
            return [performer]
        case .battle(let performers):
            return performers
        case .festival(let performers):
            return performers
        }
    }
}

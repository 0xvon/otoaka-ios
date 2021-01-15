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
        var feeds: [ArtistFeedSummary] = []
        let role: RoleProperties
    }
    
    enum Output {
        case didGetLiveDetail(LiveDetail)
        case didGetDisplayType(DisplayType)
        case updateFeedSummary(ArtistFeedSummary?)
        case updatePerformers([Group])
        
        case pushToGroupFeedList(GroupFeedListViewController.Input)
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
    private lazy var getGroupFeed = Action(GetGroupFeed.self, httpClient: self.apiClient)
    
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
            getGroupFeed.errors
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
            outputSubject.send(.pushToGroupFeedList(state.live.hostGroup))
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
    
    func feedCellEvent(event: ArtistFeedCellContent.Output) {
        switch event {
        case .commentButtonTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.presentCommentList(.feedComment(feed)))
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
        var uri = GetGroupFeed.URI()
        uri.groupId = state.live.hostGroup.id
        uri.per = 1
        uri.page = 1
        let request = Empty()
        getGroupFeed.input((request: request, uri: uri))
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

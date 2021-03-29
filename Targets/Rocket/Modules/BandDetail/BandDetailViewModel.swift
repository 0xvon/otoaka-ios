//
//  BandDetailViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/28.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent

class BandDetailViewModel {
    enum DisplayType {
        case fan
        case group
        case member
    }
    enum SummaryRow {
        case live, feed
    }
    struct State {
        var group: Group
        var lives: [Live] = []
        var feeds: [UserFeedSummary] = []
        var groupDetail: GetGroup.Response?
        var channelItem: YouTubeVideo?
        let role: RoleProperties
        
        var displayType: DisplayType? {
            guard let detail = groupDetail else { return nil }
            return _displayType(isMember: detail.isMember)
        }
        
        fileprivate func _displayType(isMember: Bool) -> DisplayType {
            switch role {
            case .fan: return .fan
            case .artist:
                return isMember ? .member : .group
            }
        }
    }
    
    enum Output {
        case didGetGroupDetail(GetGroup.Response, displayType: DisplayType)
//        case updateLiveSummary(Live?)
        case updateFeedSummary(UserFeedSummary?)
        case didGetChart(Group, YouTubeVideo?)
        case didCreatedInvitation(InviteGroup.Invitation)
        case pushToLiveDetail(LiveDetailViewController.Input)
//        case pushToChartList(ChartListViewController.Input)
        case pushToCommentList(CommentListViewController.Input)
        case pushToLiveList(LiveListViewController.Input)
        case pushToFeedAuthor(User)
        case pushToGroupFeedList(FeedListViewController.Input)
        case pushToPlayTrack(PlayTrackViewController.Input)
        case openURLInBrowser(URL)
        case didDeleteFeed
        case didToggleLikeFeed
        case didDeleteFeedButtonTapped(UserFeedSummary)
        case didShareFeedButtonTapped(UserFeedSummary)
        case didDownloadButtonTapped(UserFeedSummary)
        case didInstagramButtonTapped(UserFeedSummary)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    
    private(set) var state: State

    private lazy var inviteGroup = Action(InviteGroup.self, httpClient: self.apiClient)
    private lazy var getGroup = Action(GetGroup.self, httpClient: self.apiClient)
    private lazy var getGroupLives = Action(GetGroupLives.self, httpClient: self.apiClient)
    private lazy var getGroupFeed = Action(GetGroupsUserFeeds.self, httpClient: self.apiClient)
    private lazy var listChannel = Action(ListChannel.self, httpClient: self.dependencyProvider.youTubeDataApiClient)
    private lazy var deleteFeed = Action(DeleteUserFeed.self, httpClient: self.apiClient)
    private lazy var likeFeedAction = Action(LikeUserFeed.self, httpClient: apiClient)
    private lazy var unlikeFeedAction = Action(UnlikeUserFeed.self, httpClient: apiClient)

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider, group: Group
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(group: group, role: dependencyProvider.user.role)
        
        let errors = Publishers.MergeMany(
            inviteGroup.errors,
            getGroup.errors,
//            getGroupLives.errors,
            getGroupFeed.errors,
            listChannel.errors,
            deleteFeed.errors,
            likeFeedAction.errors,
            unlikeFeedAction.errors
        )

        Publishers.MergeMany(
            inviteGroup.elements.map(Output.didCreatedInvitation).eraseToAnyPublisher(),
            getGroup.elements.map { result in
                .didGetGroupDetail(result, displayType: self.state._displayType(isMember: result.isMember))
            }.eraseToAnyPublisher(),
//            getGroupLives.elements.map { .updateLiveSummary($0.items.first) }.eraseToAnyPublisher(),
            getGroupFeed.elements.map { .updateFeedSummary($0.items.first) }.eraseToAnyPublisher(),
            listChannel.elements.map { [unowned self] in
                .didGetChart(self.state.group, $0.items.first)
            }.eraseToAnyPublisher(),
            deleteFeed.elements.map { _ in .didDeleteFeed }.eraseToAnyPublisher(),
            likeFeedAction.elements.map { _ in .didToggleLikeFeed }.eraseToAnyPublisher(),
            unlikeFeedAction.elements.map { _ in .didToggleLikeFeed }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getGroupFeed.elements
            .sink(receiveValue: { [unowned self] feeds in
                state.feeds = feeds.items
            })
            .store(in: &cancellables)
        
        listChannel.elements
            .sink(receiveValue: { [unowned self] channel in
                state.channelItem = channel.items.first
            })
            .store(in: &cancellables)
    }
    
    func didTapSeeMore(at row: SummaryRow) {
        switch row {
        case .live:
            outputSubject.send(.pushToLiveList(.groupLive(state.group)))
        case .feed:
            outputSubject.send(.pushToGroupFeedList(.groupFeed(state.group)))
        }
    }
    
    func didSelectRow(at row: SummaryRow) {
        switch row {
        case .live:
            guard let live = state.lives.first else { return }
            outputSubject.send(.pushToLiveDetail(live))
        case .feed:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.pushToPlayTrack(.userFeed(feed)))
        }
    }
    
    // MARK: - Inputs
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getGroupDetail()
        getChartSummary()
//        getGroupLiveSummary()
        getGroupFeedSummary()
    }
    
    func headerEvent(event: BandDetailHeaderView.Output) {
        switch event {
        case .track(.seeMoreChartsTapped):
            break
//            outputSubject.send(.pushToChartList(state.group))
        case .track(.playButtonTapped):
            guard let item = state.channelItem, let videoId = item.id.videoId, let snippet = item.snippet, let videoUrl = URL(string: "https://youtube.com/watch?v=\(videoId)") else { return }
            let track = Track(
                name: snippet.title ?? "",
                artistName: snippet.channelTitle ?? "",
                artwork: snippet.thumbnails?.high?.url ?? "",
                trackType: .youtube(videoUrl)
            )
            outputSubject.send(.pushToPlayTrack(.track(track)))
        case .track(.youtubeButtonTapped):
            guard let channelId = state.group.youtubeChannelId,
                  let url = URL(string: "https://www.youtube.com/channel/\(channelId)")
            else {
                return
            }
            outputSubject.send(.openURLInBrowser(url))
        case .track(.twitterButtonTapped):
            guard let id = state.group.twitterId,
                  let url = URL(string: "https://twitter.com/\(id)")
            else {
                return
            }
            outputSubject.send(.openURLInBrowser(url))
        case .track(.appleMusicButtonTapped),
             .track(.spotifyButtonTapped):
            break  // TODO
        }
    }
    
    func feedCellEvent(event: UserFeedCellContent.Output) {
        switch event {
        case .commentButtonTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.pushToCommentList(.feedComment(feed)))
        case .deleteFeedButtonTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.didDeleteFeedButtonTapped(feed))
        case .likeFeedButtonTapped:
            guard let feed = state.feeds.first else { return }
            likeFeed(feed: feed)
        case .unlikeFeedButtonTapped:
            guard let feed = state.feeds.first else { return }
            unlikeFeed(feed: feed)
        case .shareButtonTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.didShareFeedButtonTapped(feed))
        case .downloadButtonTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.didDownloadButtonTapped(feed))
        case .instagramButtonTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.didInstagramButtonTapped(feed))
        case .userTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.pushToFeedAuthor(feed.author))
        }
    }
    
    func inviteGroup(groupId: Group.ID) {
        let request = InviteGroup.Request(groupId: groupId)
        inviteGroup.input((request: request, uri: InviteGroup.URI()))
    }
    
    private func getGroupDetail() {
        var uri = GetGroup.URI()
        uri.groupId = state.group.id
        getGroup.input((request: Empty(), uri: uri))
    }
    
    private func getGroupLiveSummary() {
        let request = Empty()
        var uri = Endpoint.GetGroupLives.URI()
        uri.page = 1
        uri.per = 1
        uri.groupId = state.group.id
        getGroupLives.input((request: request, uri: uri))
    }
    
    private func getGroupFeedSummary() {
        var uri = GetGroupsUserFeeds.URI()
        uri.groupId = state.group.id
        uri.per = 1
        uri.page = 1
        let request = Empty()
        
        getGroupFeed.input((request: request, uri: uri))
    }
    
    private func getChartSummary() {
        guard let youtubeChannelId = state.group.youtubeChannelId else { return }
        let request = Empty()
        var uri = ListChannel.URI()
        uri.channelId = youtubeChannelId
        uri.part = "snippet"
        uri.maxResults = 1
        uri.order = "viewCount"
        
        listChannel.input((request: request, uri: uri))
    }
    
    func deleteFeed(feed: UserFeedSummary) {
        let request = DeleteUserFeed.Request(id: feed.id)
        let uri = DeleteUserFeed.URI()
        deleteFeed.input((request: request, uri: uri))
    }
    
    private func likeFeed(feed: UserFeedSummary) {
        let request = LikeUserFeed.Request(feedId: feed.id)
        let uri = LikeUserFeed.URI()
        likeFeedAction.input((request: request, uri: uri))
    }
    
    private func unlikeFeed(feed: UserFeedSummary) {
        let request = UnlikeUserFeed.Request(feedId: feed.id)
        let uri = UnlikeUserFeed.URI()
        unlikeFeedAction.input((request: request, uri: uri))
    }
}

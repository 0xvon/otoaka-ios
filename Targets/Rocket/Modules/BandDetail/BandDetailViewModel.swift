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
        var feeds: [ArtistFeedSummary] = []
        var groupDetail: GetGroup.Response?
        var channelItem: ChannelDetail.ChannelItem?
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
        case updateLiveSummary(Live?)
        case updateFeedSummary(ArtistFeedSummary?)
        case didGetChart(Group, ChannelDetail.ChannelItem?)
        case didCreatedInvitation(InviteGroup.Invitation)
        case pushToLiveDetail(LiveDetailViewController.Input)
        case pushToChartList(ChartListViewController.Input)
        case pushToCommentList(CommentListViewController.Input)
        case pushToLiveList(LiveListViewController.Input)
        case pushToGroupFeedList(GroupFeedListViewController.Input)
        case openURLInBrowser(URL)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    
    private(set) var state: State

    private lazy var inviteGroup = Action(InviteGroup.self, httpClient: self.apiClient)
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider, group: Group
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(group: group, role: dependencyProvider.user.role)

        let errors = inviteGroup.errors
        inviteGroup.elements
            .map(Output.didCreatedInvitation)
            .merge(with: errors.map(Output.reportError))
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }
    
    func didTapSeeMore(at row: SummaryRow) {
        switch row {
        case .live:
            outputSubject.send(.pushToLiveList(.groupLive(state.group)))
        case .feed:
            outputSubject.send(.pushToGroupFeedList(state.group))
        }
    }
    
    func didSelectRow(at row: SummaryRow) {
        switch row {
        case .live:
            guard let live = state.lives.first else { return }
            outputSubject.send(.pushToLiveDetail(live))
        case .feed:
            guard let feed = state.feeds.first else { return }
            switch feed.feedType {
            case .youtube(let url):
                outputSubject.send(.openURLInBrowser(url))
            }
        }
    }
    
    // MARK: - Inputs
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getGroupDetail()
        getChartSummary()
        getGroupLiveSummary()
        getGroupFeedSummary()
    }
    
    func headerEvent(event: BandDetailHeaderView.Output) {
        switch event {
        case .track(.seeMoreChartsTapped):
            outputSubject.send(.pushToChartList(state.group))
        case .track(.playButtonTapped):
            guard let item = state.channelItem,
                  let url = URL(string: "https://youtube.com/watch?v=\(item.id.videoId)")
            else {
                return
            }
            outputSubject.send(.openURLInBrowser(url))
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
    
    func feedCellEvent(event: ArtistFeedCellContent.Output) {
        switch event {
        case .commentButtonTapped:
            guard let feed = state.feeds.first else { return }
            outputSubject.send(.pushToCommentList(.feedComment(feed)))
        }
    }
    
    func inviteGroup(groupId: Group.ID) {
        let request = InviteGroup.Request(groupId: groupId)
        inviteGroup.input((request: request, uri: InviteGroup.URI()))
    }
    
    private func getGroupDetail() {
        var uri = GetGroup.URI()
        uri.groupId = state.group.id
        apiClient.request(GetGroup.self, request: Empty(), uri: uri)
            .sink(
                receiveCompletion: { [unowned self] error in
                    switch error {
                    case .failure(let error):
                        outputSubject.send(.reportError(error))
                    default:
                        break
                    }
                },
                receiveValue: { [unowned self] result in
                    outputSubject.send(.didGetGroupDetail(result, displayType: state._displayType(isMember: result.isMember)))
                }
            ).store(in: &cancellables)
    }
    
    private func getGroupLiveSummary() {
        let request = Empty()
        var uri = Endpoint.GetGroupLives.URI()
        uri.page = 1
        uri.per = 1
        uri.groupId = state.group.id
        apiClient.request(GetGroupLives.self, request: request, uri: uri) { [weak self] result in
            switch result {
            case .success(let lives):
                self?.state.lives = lives.items
                self?.outputSubject.send(.updateLiveSummary(lives.items.first))
            case .failure(let error):
                self?.outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func getGroupFeedSummary() {
        var uri = GetGroupFeed.URI()
        uri.groupId = state.group.id
        uri.per = 1
        uri.page = 1
        let request = Empty()
        apiClient.request(GetGroupFeed.self, request: request, uri: uri) { [weak self] result in
            switch result {
            case .success(let res):
                self?.state.feeds = res.items
                self?.outputSubject.send(.updateFeedSummary(res.items.first))
            case .failure(let error):
                self?.outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func getChartSummary() {
        guard let youtubeChannelId = state.group.youtubeChannelId else { return }
        let request = Empty()
        var uri = ListChannel.URI()
        uri.channelId = youtubeChannelId
        uri.part = "snippet"
        uri.maxResults = 1
        uri.order = "viewCount"
        dependencyProvider.youTubeDataApiClient.request(ListChannel.self, request: request, uri: uri) { [weak self] result in
            switch result {
            case .success(let res):
                self?.state.channelItem = res.items.first
                guard let group = self?.state.group else { return }
                self?.outputSubject.send(.didGetChart(group, res.items.first))
            case .failure(let error):
                self?.outputSubject.send(.reportError(error))
            }
        }
    }
}

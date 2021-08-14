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
        case live, post
    }
    struct State {
        var group: Group
        var lives: [LiveFeed] = []
        var posts: [PostSummary] = []
        var groupDetail: GetGroup.Response?
        var channelItem: InternalDomain.YouTubeVideo?
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
        case updateLiveSummary(LiveFeed?)
        case updatePostSummary(PostSummary?)
        case didGetChart(Group, InternalDomain.YouTubeVideo?)
        case didCreatedInvitation(InviteGroup.Invitation)
        case pushToLiveDetail(LiveDetailViewController.Input)
//        case pushToChartList(ChartListViewController.Input)
        
        case pushToCommentList(CommentListViewController.Input)
        case pushToLiveList(LiveListViewController.Input)
        case pushToPostAuthor(User)
        case pushToPostList(PostListViewController.Input)
        case pushToUserList(UserListViewController.Input)
        case pushToPost(PostViewController.Input)
        case pushToPlayTrack(PlayTrackViewController.Input)
        case pushToGroupDetail(Group)
        case openURLInBrowser(URL)
        
        case didDeletePost
        case didToggleLikePost
        case didInstagramButtonTapped(PostSummary)
        case didDeletePostButtonTapped(PostSummary)
        case didToggleLikeLive
        case didTwitterButtonTapped(PostSummary)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    
    private(set) var state: State

    private lazy var inviteGroup = Action(InviteGroup.self, httpClient: self.apiClient)
    private lazy var getGroup = Action(GetGroup.self, httpClient: self.apiClient)
    private lazy var getGroupLives = Action(GetGroupLives.self, httpClient: self.apiClient)
    private lazy var getGroupPost = Action(GetGroupPosts.self, httpClient: self.apiClient)
    private lazy var listChannel = Action(ListChannel.self, httpClient: self.dependencyProvider.youTubeDataApiClient)
    
    private lazy var deletePostAction = Action(DeletePost.self, httpClient: apiClient)
    private lazy var likePostAction = Action(LikePost.self, httpClient: apiClient)
    private lazy var unLikePostAction = Action(UnlikePost.self, httpClient: apiClient)
    private lazy var likeLiveAction = Action(LikeLive.self, httpClient: apiClient)
    private lazy var unlikeLiveAction = Action(UnlikeLive.self, httpClient: apiClient)

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
            getGroupLives.errors,
            getGroupPost.errors,
            listChannel.errors,
            deletePostAction.errors,
            likePostAction.errors,
            unLikePostAction.errors,
            likeLiveAction.errors,
            unlikeLiveAction.errors
        )

        Publishers.MergeMany(
            inviteGroup.elements.map(Output.didCreatedInvitation).eraseToAnyPublisher(),
            getGroup.elements.map { [unowned self] result in
                .didGetGroupDetail(result, displayType: self.state._displayType(isMember: result.isMember))
            }.eraseToAnyPublisher(),
            getGroupLives.elements.map { .updateLiveSummary($0.items.first) }.eraseToAnyPublisher(),
            getGroupPost.elements.map { .updatePostSummary($0.items.first) }.eraseToAnyPublisher(),
            listChannel.elements.map { [unowned self] in
                .didGetChart(self.state.group, $0.items.first)
            }.eraseToAnyPublisher(),
            deletePostAction.elements.map { _ in .didDeletePost }.eraseToAnyPublisher(),
            likePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            unLikePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            likeLiveAction.elements.map { _ in .didToggleLikeLive }.eraseToAnyPublisher(),
            unlikeLiveAction.elements.map { _ in .didToggleLikeLive }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getGroupPost.elements
            .combineLatest(getGroupLives.elements)
            .sink(receiveValue: { [unowned self] posts, lives in
                state.posts = posts.items
                state.lives = lives.items
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
        case .post:
            outputSubject.send(.pushToPostList(.groupPost(state.group)))
        }
    }
    
    func didSelectRow(at row: SummaryRow) {
        switch row {
        case .live:
            guard let live = state.lives.first else { return }
            outputSubject.send(.pushToLiveDetail(live))
        case .post: break
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
        getGroupPostSummary()
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
    
    func postCellEvent(event: PostCellContent.Output) {
        guard let post = state.posts.first else { return }
        
        switch event {
        case .commentTapped:
            outputSubject.send(.pushToCommentList(.postComment(post)))
        case .deleteTapped:
            outputSubject.send(.didDeletePostButtonTapped(post))
        case .likeTapped:
            post.isLiked
                ? unlikePost(post: post)
                : likePost(post: post)
        case .twitterTapped:
            outputSubject.send(.didTwitterButtonTapped(post))
        case .instagramTapped:
            outputSubject.send(.didInstagramButtonTapped(post))
        case .userTapped:
            outputSubject.send(.pushToPostAuthor(post.author))
        case .groupTapped:
            guard let group = post.groups.first else { return }
            outputSubject.send(.pushToGroupDetail(group))
        default: break
        }
    }
    
    func liveCellEvent(event: LiveCellContent.Output) {
        guard let live = state.lives.first else { return }
        switch event {
        case .buyTicketButtonTapped:
            if let url = live.live.piaEventUrl, let afUrl = URL(string: "https://click.linksynergy.com/deeplink?id=HDD1WlcV/Qk&mid=36672&murl=\(url.absoluteString)") {
                outputSubject.send(.openURLInBrowser(afUrl))
            }
        case .likeButtonTapped:
            live.isLiked ? unlikeLive(live: live.live) : likeLive(live: live.live)
        case .numOfLikeTapped:
            outputSubject.send(.pushToUserList(.liveLikedUsers(live.live.id)))
        case .numOfReportTapped:
            outputSubject.send(.pushToPostList(.livePost(live.live)))
        case .reportButtonTapped:
            outputSubject.send(.pushToPost(live.live))
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
    
    private func getGroupPostSummary() {
        var uri = GetGroupPosts.URI()
        uri.groupId = state.group.id
        uri.per = 1
        uri.page = 1
        let request = Empty()
        getGroupPost.input((request: request, uri: uri))
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
    
    private func likePost(post: PostSummary) {
        let request = LikePost.Request(postId: post.id)
        let uri = LikePost.URI()
        likePostAction.input((request: request, uri: uri))
    }
    
    private func unlikePost(post: PostSummary) {
        let request = UnlikePost.Request(postId: post.id)
        let uri = UnlikePost.URI()
        unLikePostAction.input((request: request, uri: uri))
    }
    
    func deletePost(post: PostSummary) {
        let request = DeletePost.Request(postId: post.id)
        let uri = DeletePost.URI()
        deletePostAction.input((request: request, uri: uri))
    }
    
    func likeLive(live: Live) {
        let request = LikeLive.Request(liveId: live.id)
        let uri = LikeLive.URI()
        likeLiveAction.input((request: request, uri: uri))
    }
    
    func unlikeLive(live: Live) {
        let request = UnlikeLive.Request(liveId: live.id)
        let uri = UnlikeLive.URI()
        unlikeLiveAction.input((request: request, uri: uri))
    }
}

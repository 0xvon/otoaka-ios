//
//  UserDetailViewModel.swift
//  ImagePipeline
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent
import ImageViewer

class UserDetailViewModel {
    enum DisplayType {
        case account
        case user
    }
    enum SummaryRow {
        case post
        case group
        case live
    }
    struct State {
        var user: User
        var selfUser: User
        var post: PostSummary? = nil
        var group: Group? = nil
        var live: LiveFeed? = nil
        var groupNameSummary: [String] = []
        var userDetail: UserDetail?
        
        var displayType: DisplayType {
            return _displayType(isMe: user.id == selfUser.id)
        }
        
        fileprivate func _displayType(isMe: Bool) -> DisplayType {
            return isMe ? .account : .user
        }
    }
    
    enum Output {
        case didRefreshUserDetail(UserDetail)
        case didRefreshPostSummary(PostSummary?)
        case didRefreshLikedLive(LiveFeed?)
        case didRefreshFollowingGroup(Group?, [String])
        case followButtontapped
        case editProfileButtonTapped
        
        case pushToPlayTrack(PlayTrackViewController.Input)
        case pushToGroupDetail(Group)
        case openImage(GalleryItemsDataSource)
        case pushToFeedList(FeedListViewController.Input)
        case pushToPostList(PostListViewController.Input)
        case pushToGroupList(GroupListViewController.Input)
        case pushToUserList(UserListViewController.Input)
        case pushToLiveList(LiveListViewController.Input)
        case pushToCommentList(CommentListViewController.Input)
        case pushToTrackList(TrackListViewController.Input)
        case openURLInBrowser(URL)
        case pushToPostAuthor(User)
        case pushToMessageRoom(MessageRoom)
        case pushToPost(PostViewController.Input)
        
        case didDeletePost
        case didToggleLikePost
        case didInstagramButtonTapped(PostSummary)
        case didDeletePostButtonTapped(PostSummary)
        case didTwitterButtonTapped(PostSummary)
        
        case didToggleLikeLive
        
        case reportError(Error)
    }
    
    var dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var getUserDetailAction = Action(GetUserDetail.self, httpClient: apiClient)
    private lazy var getUserPostAction = Action(GetPosts.self, httpClient: apiClient)
    private lazy var getLikedLiveAction = Action(GetLikedLive.self, httpClient: apiClient)
    private lazy var followingGroupsAction = Action(FollowingGroups.self, httpClient: apiClient)
    
    private lazy var deletePostAction = Action(DeletePost.self, httpClient: apiClient)
    private lazy var likePostAction = Action(LikePost.self, httpClient: apiClient)
    private lazy var unLikePostAction = Action(UnlikePost.self, httpClient: apiClient)
    private lazy var createMessageRoomAction = Action(CreateMessageRoom.self, httpClient: apiClient)
    private lazy var likeLiveAction = Action(LikeLive.self, httpClient: apiClient)
    private lazy var unlikeLiveAction = Action(UnlikeLive.self, httpClient: apiClient)
    
//    init(
//        dependencyProvider: LoggedInDependencyProvider, user: User
//    ) {
//        fatalError()
//    }
    init(dependencyProvider: LoggedInDependencyProvider, user: User) {
//        self.dependencyProvider = dependencyProvider
        self.state = State(user: user, selfUser: dependencyProvider.user)
        self.dependencyProvider = dependencyProvider
        
        let errors = Publishers.MergeMany(
            getUserDetailAction.errors,
            getUserPostAction.errors,
            getLikedLiveAction.errors,
            followingGroupsAction.errors,
            deletePostAction.errors,
            likePostAction.errors,
            unLikePostAction.errors,
            createMessageRoomAction.errors,
            likeLiveAction.errors,
            unlikeLiveAction.errors
        )
        
        Publishers.MergeMany(
            getUserDetailAction.elements.map(Output.didRefreshUserDetail).eraseToAnyPublisher(),
            getUserPostAction.elements.map { .didRefreshPostSummary($0.items.first) }.eraseToAnyPublisher(),
            getLikedLiveAction.elements.map { .didRefreshLikedLive($0.items.first) }.eraseToAnyPublisher(),
            followingGroupsAction.elements.map { .didRefreshFollowingGroup($0.items.first, $0.items.map { $0.name }) }.eraseToAnyPublisher(),
            deletePostAction.elements.map { _ in .didDeletePost }.eraseToAnyPublisher(),
            likePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            unLikePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            createMessageRoomAction.elements.map(Output.pushToMessageRoom).eraseToAnyPublisher(),
            likeLiveAction.elements.map { _ in .didToggleLikeLive }.eraseToAnyPublisher(),
            unlikeLiveAction.elements.map { _ in .didToggleLikeLive }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getUserDetailAction.elements
            .combineLatest(getUserPostAction.elements, followingGroupsAction.elements, getLikedLiveAction.elements)
            .sink(receiveValue: { [unowned self] userDetail, posts, groups, lives in
                state.userDetail = userDetail
                state.post = posts.items.first
                state.group = groups.items.first
                state.live = lives.items.first
                state.groupNameSummary = groups.items.map { $0.name }
            })
            .store(in: &cancellables)
    }
    
    func didSelectRow(at row: SummaryRow) {
        switch row {
        case .post: break
        case .group:
            guard let group = state.group else { return }
            outputSubject.send(.pushToGroupDetail(group))
        case .live: break
        }
    }
    
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getUserDetail()
        getUserPostSummary()
        getFollowingGroup()
        getLikedLive()
    }
    
    func headerEvent(output: UserDetailHeaderView.Output) {
        switch output {
        case .followersButtonTapped:
            outputSubject.send(.pushToUserList(.userFollowers(state.user.id)))
        case .followingUsersButtonTapped:
            outputSubject.send(.pushToUserList(.followingUsers(state.user.id)))
        case .likeFeedButtonTapped:
//            outputSubject.send(.pushToFeedList(.likedFeed(state.user)))
            outputSubject.send(.pushToPostList(.likedPost(state.user)))
        case .followButtonTapped:
            outputSubject.send(.followButtontapped)
        case .editButtonTapped:
            outputSubject.send(.editProfileButtonTapped)
        }
    }
    
    func groupCellEvent(event: GroupCellContent.Output) {
        switch event {
        case .listenButtonTapped: break
        }
    }
    
    func postCellEvent(event: PostCellContent.Output) {
        guard let post = state.post else { return }
        
        switch event {
        case .commentTapped:
            outputSubject.send(.pushToCommentList(.postComment(post)))
//            outputSubject.send(.pushToCommentList(.feedComment(feed)))
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
        case .trackTapped(_): break
        case .playTapped(let track):
            outputSubject.send(.pushToPlayTrack(.track(track)))
        case .imageTapped(let image):
            outputSubject.send(.openImage(image))
        case .cellTapped: break
        case .postListTapped:
            guard let live = post.post.live else { return }
            outputSubject.send(.pushToPostList(.livePost(live)))
        case .seePlaylistTapped:
            outputSubject.send(.pushToTrackList(.playlist(post.post)))
        case .postTapped:
            guard let live = post.post.live else { return }
            if post.post.author.id == dependencyProvider.user.id {
                outputSubject.send(.pushToPost((live: live, post: post.post)))
            } else {
                outputSubject.send(.pushToPost((live: live, post: nil)))
            }
        }
    }
    
    func liveCellEvent(event: LiveCellContent.Output) {
        guard let live = state.live else { return }
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
            outputSubject.send(.pushToPost((live: live.live, post: nil)))
        }
    }
    
    private func getUserDetail() {
        var uri = GetUserDetail.URI()
        uri.userId = state.user.id
        getUserDetailAction.input((request: Empty(), uri: uri))
    }
    
    private func getUserPostSummary() {
        var uri = GetPosts.URI()
        uri.userId = state.user.id
        uri.page = 1
        uri.per = 1
        getUserPostAction.input((request: Empty(), uri: uri))
    }
    
    private func getFollowingGroup() {
        var uri = FollowingGroups.URI()
        uri.id = state.user.id
        uri.page = 1
        uri.per = 5
        followingGroupsAction.input((request: Empty(), uri: uri))
    }
    
    private func getLikedLive() {
        var uri = GetLikedLive.URI()
        uri.userId = state.user.id
        uri.page = 1
        uri.per = 1
        getLikedLiveAction.input((request: Empty(), uri: uri))
    }
    
    private func likePost(post: PostSummary) {
        let request = LikePost.Request(postId: post.id)
        let uri = LikePost.URI()
        likePostAction.input((request: request, uri: uri))
    }
    
    func createMessageRoom(partner: User) {
        let request = CreateMessageRoom.Request(members: [partner.id], name: partner.name)
        let uri = CreateMessageRoom.URI()
        createMessageRoomAction.input((request: request, uri: uri))
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
    
    func didTapSeeMore(at row: SummaryRow) {
        switch row {
        case .post:
//            outputSubject.send(.pushToFeedList(.userFeed(state.user)))
            outputSubject.send(.pushToPostList(.userPost(state.user)))
        case .group:
            outputSubject.send(.pushToGroupList(.followingGroups(state.user.id)))
        case .live:
            outputSubject.send(.pushToLiveList(.likedLive(state.user)))
        }
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
    
    deinit {
        print("UserViewModel.deinit")
    }
}

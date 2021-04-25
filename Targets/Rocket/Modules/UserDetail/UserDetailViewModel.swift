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

class UserDetailViewModel {
    enum DisplayType {
        case account
        case user
    }
    enum SummaryRow {
        case post
        case group
    }
    struct State {
        var user: User
        var selfUser: User
        var post: PostSummary? = nil
        var group: Group? = nil
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
        case didRefreshFollowingGroup(Group?, [String])
        
        case pushToPlayTrack(PlayTrackViewController.Input)
        case pushToGroupDetail(Group)
        case pushToFeedList(FeedListViewController.Input)
        case pushToPostList(PostListViewController.Input)
        case pushToGroupList(GroupListViewController.Input)
        case pushToUserList(UserListViewController.Input)
        case pushToCommentList(CommentListViewController.Input)
        case openURLInBrowser(URL)
        case pushToPostAuthor(User)
        
        case didDeletePost
        case didToggleLikePost
        case didInstagramButtonTapped(PostSummary)
        case didDeletePostButtonTapped(PostSummary)
        case didTwitterButtonTapped(PostSummary)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var getUserDetailAction = Action(GetUserDetail.self, httpClient: apiClient)
    private lazy var getUserPostAction = Action(GetPosts.self, httpClient: apiClient)
    private lazy var followingGroupsAction = Action(FollowingGroups.self, httpClient: apiClient)
    
    private lazy var deletePostAction = Action(DeletePost.self, httpClient: apiClient)
    private lazy var likePostAction = Action(LikePost.self, httpClient: apiClient)
    private lazy var unLikePostAction = Action(UnlikePost.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, user: User
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(user: user, selfUser: dependencyProvider.user)
        
        let errors = Publishers.MergeMany(
            getUserDetailAction.errors,
            getUserPostAction.errors,
            followingGroupsAction.errors,
            deletePostAction.errors,
            likePostAction.errors,
            unLikePostAction.errors
        )
        
        Publishers.MergeMany(
            getUserDetailAction.elements.map(Output.didRefreshUserDetail).eraseToAnyPublisher(),
            getUserPostAction.elements.map { .didRefreshPostSummary($0.items.first) }.eraseToAnyPublisher(),
            followingGroupsAction.elements.map { .didRefreshFollowingGroup($0.items.first, $0.items.map { $0.name }) }.eraseToAnyPublisher(),
            deletePostAction.elements.map { _ in .didDeletePost }.eraseToAnyPublisher(),
            likePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            unLikePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getUserDetailAction.elements
            .combineLatest(getUserPostAction.elements, followingGroupsAction.elements)
            .sink(receiveValue: { [unowned self] userDetail, posts, groups in
                state.userDetail = userDetail
                state.post = posts.items.first
                state.group = groups.items.first
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
        }
    }
    
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getUserDetail()
        getUserPostSummary()
        getFollowingGroup()
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
        case .commentTapped: break
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
        default: break
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
        uri.per = 10
        followingGroupsAction.input((request: Empty(), uri: uri))
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
    
    func didTapSeeMore(at row: SummaryRow) {
        switch row {
        case .post:
//            outputSubject.send(.pushToFeedList(.userFeed(state.user)))
            outputSubject.send(.pushToPostList(.userPost(state.user)))
        case .group:
            outputSubject.send(.pushToGroupList(.followingGroups(state.user.id)))
        }
    }
}

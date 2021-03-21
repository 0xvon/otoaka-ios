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
        case feed
        case group
    }
    struct State {
        var user: User
        var selfUser: User
        var feed: UserFeedSummary? = nil
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
        case didRefreshFeedSummary(UserFeedSummary?)
        case didRefreshFollowingGroup(Group?)
        
        case pushToPlayTrack(PlayTrackViewController.Input)
        case pushToGroupDetail(Group)
        case pushToFeedList(FeedListViewController.Input)
        case pushToGroupList(GroupListViewController.Input)
        case pushToUserList(UserListViewController.Input)
        case pushToCommentList(CommentListViewController.Input)
        case openURLInBrowser(URL)
        case pushToFeedAuthor(User)
        
        case didDeleteFeed
        case didToggleLikeFeed
        case didDownloadButtonTapped(UserFeedSummary)
        case didInstagramButtonTapped(UserFeedSummary)
        case didDeleteFeedButtonTapped(UserFeedSummary)
        case didShareFeedButtonTapped(UserFeedSummary)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var getUserDetailAction = Action(GetUserDetail.self, httpClient: apiClient)
    private lazy var getUsersFeedAction = Action(GetUserFeeds.self, httpClient: apiClient)
    private lazy var followingGroupsAction = Action(FollowingGroups.self, httpClient: apiClient)
    private lazy var deleteFeedAction = Action(DeleteUserFeed.self, httpClient: apiClient)
    private lazy var likeFeedAction = Action(LikeUserFeed.self, httpClient: apiClient)
    private lazy var unLikeFeedAction = Action(UnlikeUserFeed.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, user: User
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(user: user, selfUser: dependencyProvider.user)
        
        let errors = Publishers.MergeMany(
            getUserDetailAction.errors,
            getUsersFeedAction.errors,
            followingGroupsAction.errors,
            deleteFeedAction.errors,
            likeFeedAction.errors,
            unLikeFeedAction.errors
        )
        
        Publishers.MergeMany(
            getUserDetailAction.elements.map(Output.didRefreshUserDetail).eraseToAnyPublisher(),
            getUsersFeedAction.elements.map { .didRefreshFeedSummary($0.items.first) }.eraseToAnyPublisher(),
            followingGroupsAction.elements.map { .didRefreshFollowingGroup($0.items.first) }.eraseToAnyPublisher(),
            deleteFeedAction.elements.map { _ in .didDeleteFeed }.eraseToAnyPublisher(),
            likeFeedAction.elements.map { _ in .didToggleLikeFeed }.eraseToAnyPublisher(),
            unLikeFeedAction.elements.map { _ in .didToggleLikeFeed }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getUserDetailAction.elements
            .combineLatest(getUsersFeedAction.elements, followingGroupsAction.elements)
            .sink(receiveValue: { [unowned self] userDetail, feeds, groups in
                state.userDetail = userDetail
                state.feed = feeds.items.first
                state.group = groups.items.first
                state.groupNameSummary = groups.items.map { $0.name }
            })
            .store(in: &cancellables)
    }
    
    func didSelectRow(at row: SummaryRow) {
        switch row {
        case .feed:
            guard let feed = state.feed else { return }
            outputSubject.send(.pushToPlayTrack(.userFeed(feed)))
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
        getUsersFeedSummary()
        getFollowingGroup()
    }
    
    func headerEvent(output: UserDetailHeaderView.Output) {
        switch output {
        case .followersButtonTapped:
            outputSubject.send(.pushToUserList(.userFollowers(state.user.id)))
        case .followingUsersButtonTapped:
            outputSubject.send(.pushToUserList(.followingUsers(state.user.id)))
        case .likeFeedButtonTapped:
            outputSubject.send(.pushToFeedList(.likedFeed(state.user)))
        }
    }
    
    func groupCellEvent(event: GroupCellContent.Output) {
        switch event {
        case .listenButtonTapped: break
        }
    }
    
    func feedCellEvent(event: UserFeedCellContent.Output) {
        switch event {
        case .commentButtonTapped:
            guard let feed = state.feed else { return }
            outputSubject.send(.pushToCommentList(.feedComment(feed)))
        case .deleteFeedButtonTapped:
            guard let feed = state.feed else { return }
            outputSubject.send(.didDeleteFeedButtonTapped(feed))
        case .likeFeedButtonTapped:
            guard let feed = state.feed else { return }
            likeFeed(feed: feed)
        case .unlikeFeedButtonTapped:
            guard let feed = state.feed else { return }
            unlikeFeed(feed: feed)
        case .shareButtonTapped:
            guard let feed = state.feed else { return }
            outputSubject.send(.didShareFeedButtonTapped(feed))
        case .downloadButtonTapped:
            guard let feed = state.feed else { return }
            outputSubject.send(.didDownloadButtonTapped(feed))
        case .instagramButtonTapped:
            guard let feed = state.feed else { return }
            outputSubject.send(.didInstagramButtonTapped(feed))
        case .userTapped:
            guard let feed = state.feed else { return }
            outputSubject.send(.pushToFeedAuthor(feed.author))
            
        }
    }
    
    private func getUserDetail() {
        var uri = GetUserDetail.URI()
        uri.userId = state.user.id
        getUserDetailAction.input((request: Empty(), uri: uri))
    }
    
    private func getUsersFeedSummary() {
        var uri = GetUserFeeds.URI()
        uri.userId = state.user.id
        uri.page = 1
        uri.per = 1
        getUsersFeedAction.input((request: Empty(), uri: uri))
    }
    
    private func getFollowingGroup() {
        var uri = FollowingGroups.URI()
        uri.id = state.user.id
        uri.page = 1
        uri.per = 10
        followingGroupsAction.input((request: Empty(), uri: uri))
    }
    
    private func likeFeed(feed: UserFeedSummary) {
        let request = LikeUserFeed.Request(feedId: feed.id)
        let uri = LikeUserFeed.URI()
        likeFeedAction.input((request: request, uri: uri))
    }
    
    private func unlikeFeed(feed: UserFeedSummary) {
        let request = UnlikeUserFeed.Request(feedId: feed.id)
        let uri = UnlikeUserFeed.URI()
        unLikeFeedAction.input((request: request, uri: uri))
    }
    
    func deleteFeed(feed: UserFeedSummary) {
        let request = DeleteUserFeed.Request(id: feed.id)
        let uri = DeleteUserFeed.URI()
        deleteFeedAction.input((request: request, uri: uri))
    }
    
    func didTapSeeMore(at row: SummaryRow) {
        switch row {
        case .feed:
            outputSubject.send(.pushToFeedList(.userFeed(state.user)))
        case .group:
            outputSubject.send(.pushToGroupList(.followingGroups(state.user.id)))
        }
    }
}

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
    }
    struct State {
        var user: User
        var selfUser: User
        var feed: UserFeedSummary? = nil
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
        case didRefreshFollowingGroupSummary
        case pushToFeedList(FeedListViewController.Input)
        case pushToGroupList(GroupListViewController.Input)
        case pushToUserList(UserListViewController.Input)
        case pushToCommentList(CommentListViewController.Input)
        case openURLInBrowser(URL)
        case didDeleteFeed
        case didLikeFeed
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
    private lazy var deleteFeedAction = Action(DeleteUserFeed.self, httpClient: apiClient)
    private lazy var likeFeedAction = Action(LikeUserFeed.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, user: User
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(user: user, selfUser: dependencyProvider.user)
        
        let errors = Publishers.MergeMany(
            getUserDetailAction.errors,
            getUsersFeedAction.errors,
            deleteFeedAction.errors,
            likeFeedAction.errors
        )
        
        Publishers.MergeMany(
            getUserDetailAction.elements.map(Output.didRefreshUserDetail).eraseToAnyPublisher(),
            getUsersFeedAction.elements.map { .didRefreshFeedSummary($0.items.first) }.eraseToAnyPublisher(),
            deleteFeedAction.elements.map { _ in .didDeleteFeed }.eraseToAnyPublisher(),
            likeFeedAction.elements.map { _ in .didLikeFeed }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getUserDetailAction.elements
            .combineLatest(getUsersFeedAction.elements)
            .sink(receiveValue: { [unowned self] userDetail, feeds in
                state.userDetail = userDetail
                state.feed = feeds.items.first
            })
            .store(in: &cancellables)
    }
    
    func didSelectRow(at row: SummaryRow) {
        switch row {
        case .feed:
            guard let feed = state.feed else { return }
            switch feed.feedType {
            case .youtube(let url):
                outputSubject.send(.openURLInBrowser(url))
            }
        }
    }
    
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getUserDetail()
        getUsersFeedSummary()
    }
    
    func headerEvent(output: UserDetailHeaderView.Output) {
        switch output {
        case .followersButtonTapped:
            outputSubject.send(.pushToUserList(.userFollowers(state.user.id)))
        case .followingUsersButtonTapped:
            outputSubject.send(.pushToUserList(.followingUsers(state.user.id)))
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
        case .shareButtonTapped:
            guard let feed = state.feed else { return }
            outputSubject.send(.didShareFeedButtonTapped(feed))
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
    
    private func likeFeed(feed: UserFeedSummary) {
        let request = LikeUserFeed.Request(feedId: feed.id)
        let uri = LikeUserFeed.URI()
        likeFeedAction.input((request: request, uri: uri))
    }
    
    func deleteFeed(feed: UserFeedSummary) {
        let request = DeleteUserFeed.Request(id: feed.id)
        let uri = DeleteUserFeed.URI()
        deleteFeedAction.input((request: request, uri: uri))
    }
    
    func didTapSeeMore(at row: SummaryRow) {
        switch row {
        case .feed: break
//            outputSubject.send(.pushToFeedList(.groupFeed(state.group)))
        }
    }
}

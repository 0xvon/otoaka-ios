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
import ImageViewer

class LiveDetailViewModel {
    enum SummaryRow {
        case post, performers(Group)
    }
    struct State {
        var live: LiveFeed
        var liveDetail: LiveDetail?
        var posts: [PostSummary] = []
        let role: RoleProperties
    }
    
    enum Output {
        case didGetLiveDetail(LiveDetail)
        case updatePostSummary(PostSummary?)
        case updatePerformers([Group])
        case didDeletePost
        case didToggleLikeLive
        case didToggleLikePost
        
        case didDeletePostButtonTapped(PostSummary)
        case pushToPostList(PostListViewController.Input)
        case pushToTrackList(TrackListViewController.Input)
        case pushToUser(User)
        case pushToPlayTrack(PlayTrackViewController.Input)
        case pushToGroup(BandDetailViewController.Input)
        case pushToCommentList(CommentListViewController.Input)
        case pushToUserList(UserListViewController.Input)
        case pushToPost(PostViewController.Input)
        case openURLInBrowser(URL)
        case didInstagramButtonTapped(PostSummary)
        case didTwitterButtonTapped(PostSummary)
        case openImage(GalleryItemsDataSource)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private lazy var getLiveAction = Action(GetLive.self, httpClient: self.apiClient)
    private lazy var getLivePostAction = Action(GetLivePosts.self, httpClient: self.apiClient)
    private lazy var deletePostAction = Action(DeletePost.self, httpClient: self.apiClient)
    private lazy var likePostAction = Action(LikePost.self, httpClient: apiClient)
    private lazy var unLikePostAction = Action(UnlikePost.self, httpClient: apiClient)
    private lazy var likeLiveAction = Action(LikeLive.self, httpClient: apiClient)
    private lazy var unlikeLiveAction = Action(UnlikeLive.self, httpClient: apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider, live: LiveFeed
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(live: live, role: dependencyProvider.user.role)
        
        let errors = Publishers.MergeMany(
            getLiveAction.errors,
            getLivePostAction.errors,
            deletePostAction.errors,
            likePostAction.errors,
            unLikePostAction.errors,
            likeLiveAction.errors,
            unlikeLiveAction.errors
        )
        
        Publishers.MergeMany(
            getLiveAction.elements.map(Output.didGetLiveDetail).eraseToAnyPublisher(),
            getLivePostAction.elements.map { result in
                .updatePostSummary(result.items.first)
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
        
        getLiveAction.elements
            .combineLatest(getLivePostAction.elements)
            .sink(receiveValue: { [unowned self] liveDetail, posts in
                state.liveDetail = liveDetail
                state.posts = posts.items
                outputSubject.send(.updatePerformers(liveDetail.live.performers))
            })
            .store(in: &cancellables)
    }
    
    func didTapSeeMore(at row: SummaryRow) {
        switch row {
        case .post:
            outputSubject.send(.pushToPostList(.livePost(state.live.live)))
        default: break
        }
    }
    
    func didSelectRow(at row: SummaryRow) {
        switch row {
        case .performers(let group):
            outputSubject.send(.pushToGroup(group))
        default: break
        }
    }
    
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getLiveDetail()
        getLivePostSummary()
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
            outputSubject.send(.pushToUser(post.author))
        case .groupTapped:
            guard let group = post.groups.first else { return }
            outputSubject.send(.pushToGroup(group))
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
            
        case .trackTapped(_): break
        }
    }
    
    func getLiveDetail() {
        var uri = GetLive.URI()
        uri.liveId = self.state.live.live.id
        let req = Empty()
        getLiveAction.input((request: req, uri: uri))
    }
    
    func getLivePostSummary() {
        var uri = GetLivePosts.URI()
        uri.liveId = state.live.live.id
        uri.per = 1
        uri.page = 1
        let request = Empty()
        getLivePostAction.input((request: request, uri: uri))
    }
    
    func likeCountTapped() {
        outputSubject.send(.pushToUserList(.liveLikedUsers(state.live.live.id)))
    }
    
    func postCountTapped() {
        outputSubject.send(.pushToPostList(.livePost(state.live.live)))
    }
    
    func deletePost(post: PostSummary) {
        let request = DeletePost.Request(postId: post.id)
        let uri = DeletePost.URI()
        deletePostAction.input((request: request, uri: uri))
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

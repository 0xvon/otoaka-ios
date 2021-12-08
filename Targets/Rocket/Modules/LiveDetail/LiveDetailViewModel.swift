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
        var live: Live
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
        case pushToGroup(BandDetailViewController.Input)
        case pushToUserList(UserListViewController.Input)
        case pushToPostList(PostListViewController.Input)
        case openURLInBrowser(URL)
        case openImage(GalleryItemsDataSource)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private lazy var getLiveAction = Action(GetLive.self, httpClient: self.apiClient)
    private lazy var getLivePostAction = Action(GetLivePosts.self, httpClient: self.apiClient)
    private lazy var likeLiveAction = Action(LikeLive.self, httpClient: apiClient)
    private lazy var unlikeLiveAction = Action(UnlikeLive.self, httpClient: apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider, live: Live
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(live: live, role: dependencyProvider.user.role)
        
        let errors = Publishers.MergeMany(
            getLiveAction.errors,
            getLivePostAction.errors,
            likeLiveAction.errors,
            unlikeLiveAction.errors
        )
        
        Publishers.MergeMany(
            getLiveAction.elements.map(Output.didGetLiveDetail).eraseToAnyPublisher(),
            getLivePostAction.elements.map { result in
                .updatePostSummary(result.items.first)
            }.eraseToAnyPublisher(),
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
            outputSubject.send(.pushToPostList(.livePost(state.live)))
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
    
    func getLiveDetail() {
        var uri = GetLive.URI()
        uri.liveId = self.state.live.id
        let req = Empty()
        getLiveAction.input((request: req, uri: uri))
    }
    
    func isLivePast() -> Bool {
        let today = Date()
        guard let date = state.live.date else { return false }
        return date < today.toFormatString(format: "yyyyMMdd")
    }
    
    func getLivePostSummary() {
        var uri = GetLivePosts.URI()
        uri.liveId = state.live.id
        uri.per = 1
        uri.page = 1
        let request = Empty()
        getLivePostAction.input((request: request, uri: uri))
    }
    
    func likeCountTapped() {
        outputSubject.send(.pushToUserList(.liveLikedUsers(state.live.id)))
    }
    
    func postCountTapped() {
        outputSubject.send(.pushToPostList(.livePost(state.live)))
    }
    
    func likeButtonTapped() {
        guard let liveDetail = state.liveDetail else { return }
        liveDetail.isLiked ? unlikeLive() : likeLive()
    }
    
    func likeLive() {
        let request = LikeLive.Request(liveId: state.live.id)
        let uri = LikeLive.URI()
        likeLiveAction.input((request: request, uri: uri))
    }
    
    func unlikeLive() {
        let request = UnlikeLive.Request(liveId: state.live.id)
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

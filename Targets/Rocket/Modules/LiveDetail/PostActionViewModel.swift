//
//  PostActionViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/10/13.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent
import ImageViewer

class PostActionViewModel {
    enum Output {
        case didDeletePost
        case pushToPostAuthor(User)
        case pushToPostDetail(PostSummary)
        case pushToLiveDetail(Live)
        case pushToPlayTrack(PlayTrackViewController.Input)
        case pushToCommentList(CommentListViewController.Input)
        case pushToDM(User)
        case didToggleLikePost
        case didSettingTapped(PostSummary)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var deletePostAction = Action(DeletePost.self, httpClient: self.apiClient)
    private lazy var likePostAction = Action(LikePost.self, httpClient: apiClient)
    private lazy var unLikePostAction = Action(UnlikePost.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        
        let errors = Publishers.MergeMany(
            deletePostAction.errors,
            likePostAction.errors,
            unLikePostAction.errors
        )
        
        Publishers.MergeMany(
            deletePostAction.elements.map { _ in .didDeletePost }.eraseToAnyPublisher(),
            likePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            unLikePostAction.elements.map { _ in .didToggleLikePost }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    func postCellEvent(_ post: PostSummary, event: PostCellContent.Output) {
        switch event {
        case .selfTapped:
            outputSubject.send(.pushToPostDetail(post))
        case .userTapped:
            outputSubject.send(.pushToPostAuthor(post.author))
        case .liveTapped:
            if let live = post.live {
                outputSubject.send(.pushToLiveDetail(live))
            }
        case .trackTapped:
            if let postTrack = post.tracks.first, let track = Track.translate(postTrack) {
                outputSubject.send(.pushToPlayTrack(.track(track)))
            }
        case .commentTapped:
//            outputSubject.send(.pushToCommentList(.postComment(post)))
            if post.post.author.id != dependencyProvider.user.id {
                outputSubject.send(.pushToDM(post.author))
            }
        case .likeTapped:
            post.isLiked ? unlikePost(post: post) : likePost(post: post)
        case .settingTapped:
            outputSubject.send(.didSettingTapped(post))
        }
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
    
}

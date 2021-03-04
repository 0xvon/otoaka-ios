//
//  PlayTrackViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/04.
//

import Foundation
import Combine
import DomainEntity
import Endpoint

final class PlayTrackViewModel {
    enum Input {
        case youtubeVideo(String)
        case userFeed(UserFeedSummary)
    }
    
    enum Output {
        case didToggleLikeFeed
        case didDeleteFeed
        case error(Error)
    }
    
    struct State {
        let dataSource: Input
        var likeCount: Int = 0
    }
    
    var dependencyProvider: LoggedInDependencyProvider
    private(set) var state: State
    var apiClient: APIClient { dependencyProvider.apiClient }
    var cancellables: Set<AnyCancellable> = []

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    private lazy var deleteFeedAction = Action(DeleteUserFeed.self, httpClient: self.apiClient)
    private lazy var likeFeedAction = Action(LikeUserFeed.self, httpClient: apiClient)
    private lazy var unlikeFeedAction = Action(UnlikeUserFeed.self, httpClient: apiClient)
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        switch input {
        case .userFeed(let feed):
            self.state = State(dataSource: input, likeCount: feed.likeCount)
        case .youtubeVideo(_):
            self.state = State(dataSource: input)
        }
        
        let errors = Publishers.MergeMany(
            deleteFeedAction.errors,
            likeFeedAction.errors,
            unlikeFeedAction.errors
        )
        
        Publishers.MergeMany(
            deleteFeedAction.elements.map {_ in .didDeleteFeed }.eraseToAnyPublisher(),
            likeFeedAction.elements.map { _ in .didToggleLikeFeed }.eraseToAnyPublisher(),
            unlikeFeedAction.elements.map { _ in .didToggleLikeFeed }.eraseToAnyPublisher(),
            errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    func deleteFeed() {
        switch state.dataSource {
        case .userFeed(let feed):
            let request = DeleteUserFeed.Request(id: feed.id)
            let uri = DeleteUserFeed.URI()
            deleteFeedAction.input((request: request, uri: uri))
        case .youtubeVideo(_): break
        }
    }
    
    func likeFeed() {
        switch state.dataSource {
        case .userFeed(let feed):
            let request = LikeUserFeed.Request(feedId: feed.id)
            let uri = LikeUserFeed.URI()
            likeFeedAction.input((request: request, uri: uri))
        case .youtubeVideo(_): break
        }
        state.likeCount += 1
    }
    
    func unlikeFeed() {
        switch state.dataSource {
        case .userFeed(let feed):
            let request = UnlikeUserFeed.Request(feedId: feed.id)
            let uri = UnlikeUserFeed.URI()
            unlikeFeedAction.input((request: request, uri: uri))
        case .youtubeVideo(_): break
        }
        state.likeCount -= 1
    }
}

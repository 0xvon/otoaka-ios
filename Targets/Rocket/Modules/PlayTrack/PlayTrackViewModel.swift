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
import InternalDomain

final class PlayTrackViewModel {
    enum Input {
        case youtubeVideo(String)
        case track(Track)
        case userFeed(UserFeedSummary)
    }
    
    enum Output {
        case didToggleLikeFeed
        case didDeleteFeed
        case playingStateChanged
        case playingDurationChanged
        case didSearchLyrics(String?)
        case error(Error)
    }
    
    struct State {
        let dataSource: Input
        var playingState: PlayingState = .pausing
        var playingThermalIndicators: [Int] = [0, 0, 0]
        var likeCount: Int = 0
    }
    
    enum PlayingState {
        case playing
        case pausing
    }
    
    var dependencyProvider: LoggedInDependencyProvider
    private(set) var state: State
    var apiClient: APIClient { dependencyProvider.apiClient }
    var musixmatchClient: MusixmatchAPIClient { dependencyProvider.musixApiClient }
    var cancellables: Set<AnyCancellable> = []

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    private lazy var deleteFeedAction = Action(DeleteUserFeed.self, httpClient: self.apiClient)
    private lazy var likeFeedAction = Action(LikeUserFeed.self, httpClient: apiClient)
    private lazy var unlikeFeedAction = Action(UnlikeUserFeed.self, httpClient: apiClient)
    private lazy var searchLyricsAction = Action(MatcherLyrics.self, httpClient: musixmatchClient)
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Input) {
        self.dependencyProvider = dependencyProvider
        switch input {
        case .userFeed(let feed):
            self.state = State(dataSource: input, likeCount: feed.likeCount)
        case .youtubeVideo(_), .track(_):
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
            searchLyricsAction.elements.map { res in .didSearchLyrics(res.message.body?.lyrics.lyrics_body) }.eraseToAnyPublisher(),
            searchLyricsAction.errors.map { _ in .didSearchLyrics(nil) }.eraseToAnyPublisher(),
            errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    func changePlayingState(_ playingState: PlayingState) {
        state.playingState = playingState
        self.outputSubject.send(.playingStateChanged)
    }
    
    func changePlayingDuration() {
        switch state.playingState {
        case .pausing:
            state.playingThermalIndicators = [0, 0, 0]
        case .playing:
            state.playingThermalIndicators = [Int.random(in: 1...10), Int.random(in: 1...10), Int.random(in: 1...10)]
        }
        self.outputSubject.send(.playingDurationChanged)
    }
    
    func deleteFeed() {
        switch state.dataSource {
        case .userFeed(let feed):
            let request = DeleteUserFeed.Request(id: feed.id)
            let uri = DeleteUserFeed.URI()
            deleteFeedAction.input((request: request, uri: uri))
        case .youtubeVideo(_), .track(_): break
        }
    }
    
    func likeFeed() {
        switch state.dataSource {
        case .userFeed(let feed):
            let request = LikeUserFeed.Request(feedId: feed.id)
            let uri = LikeUserFeed.URI()
            likeFeedAction.input((request: request, uri: uri))
        case .youtubeVideo(_), .track(_): break
        }
        state.likeCount += 1
    }
    
    func unlikeFeed() {
        switch state.dataSource {
        case .userFeed(let feed):
            let request = UnlikeUserFeed.Request(feedId: feed.id)
            let uri = UnlikeUserFeed.URI()
            unlikeFeedAction.input((request: request, uri: uri))
        case .youtubeVideo(_), .track(_): break
        }
        state.likeCount -= 1
    }
    
    func searchLyrics() {
        let request = Empty()
        var uri = MatcherLyrics.URI()
        uri.format = "json"
        
        switch state.dataSource {
        case .userFeed(let feed):
            uri.q_track = feed.title
            uri.q_artist = feed.group.name
        case .track(let track):
            uri.q_artist = track.artistName
            uri.q_track = track.name
        default: break
        }
        
        searchLyricsAction.input((request: request, uri: uri))
    }
}

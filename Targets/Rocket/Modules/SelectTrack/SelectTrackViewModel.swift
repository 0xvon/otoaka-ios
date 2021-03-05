//
//  SelectTrackViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/03.
//

import Foundation
import Combine
import Endpoint
import InternalDomain

final class SelectTrackViewModel {
    enum Input {
        case updateSearchQuery(String?)
    }
    
    enum Output {
        case updateSearchResult(SearchResultViewController.Input)
        case selectTrack(InternalDomain.ChannelDetail.ChannelItem)
        case reloadData
        case isRefreshing(Bool)
        case reportError(Error)
    }
    
    struct State {
        var group: Group
        var tracks: [InternalDomain.ChannelDetail.ChannelItem] = []
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    var youTubeDataApiClient: YouTubeDataAPIClient { dependencyProvider.youTubeDataApiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    private lazy var listChannelAction = Action(ListChannel.self, httpClient: youTubeDataApiClient)

    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Group) {
        self.dependencyProvider = dependencyProvider
        self.state = State(group: input)
        
        let errors = Publishers.MergeMany(
            listChannelAction.errors
        )
        
        Publishers.MergeMany(
            listChannelAction.elements.map { _ in .reloadData }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        listChannelAction.elements
            .sink(receiveValue: { [unowned self] channel in
                state.tracks = channel.items
            })
            .store(in: &cancellables)
    }
    
    func didSelectTrack(at section: InternalDomain.ChannelDetail.ChannelItem) {
        outputSubject.send(.selectTrack(section))
    }
    
    private func searchYouTubeTracks() {
        let request = Empty()
        var uri = ListChannel.URI()
        uri.channelId = state.group.youtubeChannelId
        uri.part = "snippet"
        uri.type = "video"
        uri.order = "viewCount"
        uri.maxResults = 10
        
        listChannelAction.input((request: request, uri: uri))
    }
    
    func refresh() {
        if state.group.youtubeChannelId != nil {
            outputSubject.send(.isRefreshing(true))
            searchYouTubeTracks()
        } else {
            outputSubject.send(.reloadData)
            outputSubject.send(.isRefreshing(false))
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.tracks.count else { return }
    }
    
    func updateSearchQuery(query: String?) {
        guard let query = query else { return }
        outputSubject.send(.updateSearchResult(.trackToSelect(state.group, query)))
    }
}

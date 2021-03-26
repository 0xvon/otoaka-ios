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
        case selectTrack(Track)
        case reloadData
        case isRefreshing(Bool)
        case reportError(Error)
    }
    
    struct State {
        var isLoading = false
        var nextPageToken: String? = nil
        var tracks: [Track] = []
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    var youTubeDataApiClient: YouTubeDataAPIClient { dependencyProvider.youTubeDataApiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Void) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
    }
    
    func didSelectTrack(at section: Track) {
        outputSubject.send(.selectTrack(section))
    }
    
//    private func searchYouTubeTracks() {
//        if state.isLoading { return }
//        let request = Empty()
//        var uri = ListChannel.URI()
//        uri.channelId = state.group.youtubeChannelId
//        uri.part = "snippet"
//        uri.type = "video"
//        uri.order = "viewCount"
//        uri.maxResults = per
//        uri.pageToken = state.nextPageToken
//        state.isLoading = true
//        listChannelAction.input((request: request, uri: uri))
//    }
    
    func refresh() {
//        if state.group.youtubeChannelId != nil {
//            state.nextPageToken = nil
//            outputSubject.send(.isRefreshing(true))
//            searchYouTubeTracks()
//        } else {
//            outputSubject.send(.reloadData)
//            outputSubject.send(.isRefreshing(false))
//        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.tracks.count else { return }
//        searchYouTubeTracks()
    }
    
    func updateSearchQuery(query: String?) {
        guard let query = query, query != "", query != " " else { return }
        outputSubject.send(.updateSearchResult(.trackToSelect(query)))
    }
}

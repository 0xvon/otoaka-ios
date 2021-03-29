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
    
    enum Scope: Int, CaseIterable {
        case appleMusic, youtube
        var description: String {
            switch self {
            case .appleMusic: return "Apple Music"
            case .youtube: return "YouTube"
            }
        }
    }
    
    struct State {
        var isLoading = false
        var nextPageToken: String? = nil
        var tracks: [Track] = []
        var scope: Scope = .appleMusic
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    var youTubeDataApiClient: YouTubeDataAPIClient { dependencyProvider.youTubeDataApiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var scopes: [Scope] { Scope.allCases }

    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: Void) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
    }
    
    func didSelectTrack(at section: Track) {
        outputSubject.send(.selectTrack(section))
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.tracks.count else { return }
//        searchYouTubeTracks()
    }
    
    func updateSearchQuery(query: String?) {
        guard let query = query, query != "", query != " " else { return }
        switch state.scope {
        case .appleMusic:
            outputSubject.send(.updateSearchResult(.appleMusicToSelect(query)))
        case .youtube:
            outputSubject.send(.updateSearchResult(.youtubeToSelect(query)))
        }
    }
    
    func updateScope(_ scope: Int) {
        state.scope = Scope.allCases[scope]
    }
}

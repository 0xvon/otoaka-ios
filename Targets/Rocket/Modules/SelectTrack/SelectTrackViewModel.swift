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
        case addTrack
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
        var selected: [Track] = []
        var groups: [Group] = []
        var scope: Scope = .appleMusic
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    var youTubeDataApiClient: YouTubeDataAPIClient { dependencyProvider.youTubeDataApiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var scopes: [Scope] { Scope.allCases }
    private lazy var followingGroupPagination: PaginationRequest<FollowingGroups> = {
        var uri = FollowingGroups.URI()
        uri.id = dependencyProvider.user.id
        let request = PaginationRequest<FollowingGroups>(apiClient: self.apiClient, uri: uri)
        return request
    }()

    private var cancellables: [AnyCancellable] = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: [Track]) {
        self.dependencyProvider = dependencyProvider
        self.state = State(selected: input)
        
        subscribe()
    }
    
    func subscribe() {
        followingGroupPagination.subscribe { [weak self] in
            self?.updateState(with: $0)
            self?.outputSubject.send(.isRefreshing(false))
        }
    }
    
    func updateState(with result: PaginationEvent<Page<Group>>) {
        switch result {
        case .initial(let res):
            state.groups = res.items
            outputSubject.send(.reloadData)
        case .next(let res):
            state.groups += res.items
            outputSubject.send(.reloadData)
        case .error(let err):
            outputSubject.send(.reportError(err))
        }
    }
    
    func refresh() {
        self.outputSubject.send(.isRefreshing(true))
        followingGroupPagination.refresh()
    }
    
    func didSelectTrack(at section: Track) {
        state.selected.append(section)
        outputSubject.send(.addTrack)
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.groups.count else { return }
        self.outputSubject.send(.isRefreshing(true))
        followingGroupPagination.next()
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

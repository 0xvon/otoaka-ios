//
//  TrackListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/03.
//

import UIKit
import Endpoint
import Combine
import InternalDomain

class TrackListViewModel {
    typealias Input = (
        dataSource: DataSource,
        group: Group?
    )
    
    enum DataSource {
        case searchResults(String)
        case none
    }
    
    struct State {
        var isToSelect: Bool = false
        var group: Group? = nil
        var tracks: [InternalDomain.ChannelDetail.ChannelItem] = []
    }
    
    enum Output {
        case reloadTableView
        case error(Error)
    }
    
    var dataSource: DataSource
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    lazy var listChannelAction = Action(ListChannel.self, httpClient: dependencyProvider.youTubeDataApiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(group: input.group)
        self.dataSource = input.dataSource
        
        let errors = Publishers.MergeMany(
            listChannelAction.errors
        )
        
        Publishers.MergeMany(
            listChannelAction.elements.map { _ in .reloadTableView }.eraseToAnyPublisher(),
            errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        listChannelAction.elements
            .sink(receiveValue: { [unowned self] channel in
                state.tracks = channel.items
            })
            .store(in: &cancellables)
                
        subscribe(dataSource: input.dataSource)
    }
    
    func inject(_ input: Input, isToSelect: Bool = false) {
        self.state.group = input.group
        self.state.isToSelect = isToSelect
        subscribe(dataSource: input.dataSource)
        refresh()
    }
    
    func subscribe(dataSource: DataSource) {
        switch dataSource {
        case .searchResults(let query):
            searchYouTubeTracks(query: query)
        default: break
        }
    }
    
    private func searchYouTubeTracks(query: String?) {
        let request = Empty()
        var uri = ListChannel.URI()
        uri.channelId = state.group?.youtubeChannelId
        uri.q = query
        uri.part = "snippet"
        uri.maxResults = 5
        uri.order = "viewCount"
        
        listChannelAction.input((request: request, uri: uri))
    }
    
    func refresh() {
        switch self.dataSource {
        case let .searchResults(query):
            searchYouTubeTracks(query: query)
        case .none: break
        }
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.section + 25 > state.tracks.count else { return }
        switch self.dataSource {
        case let .searchResults(query):
            searchYouTubeTracks(query: query)
        case .none: break
        }
    }
}

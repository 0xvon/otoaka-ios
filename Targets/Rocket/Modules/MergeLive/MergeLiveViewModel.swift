//
//  MergeLiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/03/16.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIKit

class MergeLiveViewModel {
    enum Output {
        case didMergeLive
        case updateSubmittableState(PageState)
        case reportError(Error)
    }
    struct State {
        var live: Live
        var otherLives: [Live] = []
    }
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var mergeLiveAction = Action(MergeLive.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, live: Live
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(live: live)
        
        mergeLiveAction.elements.map { _ in .didMergeLive }.eraseToAnyPublisher()
            .merge(with: mergeLiveAction.errors.map(Output.reportError)).eraseToAnyPublisher()
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }
    
    func addLive(_ live: Live) {
        state.otherLives.append(live)
        submittableState()
    }
    
    func removeLive(_ live: Live) {
        state.otherLives = state.otherLives.filter { $0.id != live.id }
        submittableState()
    }
    
    func submittableState() {
        let submittable = !state.otherLives.isEmpty
        outputSubject.send(.updateSubmittableState(.editting(submittable)))
    }
    
    func merge() {
        let request = MergeLive.Request(liveId: state.live.id, lives: state.otherLives.map { $0.id })
        print(request)
        let uri = MergeLive.URI()
        mergeLiveAction.input((request: request, uri: uri))
    }
}

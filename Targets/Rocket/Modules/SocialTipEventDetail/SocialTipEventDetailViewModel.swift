//
//  SocialTipEventDetailViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/01/05.
//

import UIKit
import Endpoint
import Combine

class SocialTipEventDetailViewModel {
    typealias Input = SocialTipEvent
    
    struct State {
        var event: SocialTipEvent
    }
    
    enum Output {
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    var cancellables: Set<AnyCancellable> = []

    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(event: input)
    }
}

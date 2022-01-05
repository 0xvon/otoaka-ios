//
//  SocialTipRankingViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/12/30.
//

import Foundation
import Combine
import Endpoint

final class SocialTipRankingViewModel {
    enum Output {
    }
    
    enum Scope: Int, CaseIterable {
        case user, group
        var description: String {
            switch self {
            case .user: return "ユーザー"
            case .group: return "アーティスト"
            }
        }
    }
    
    struct State {
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private(set) var state: State
    private(set) var scope: Scope
    var scopes: [Scope] { Scope.allCases }
    var cancellables: Set<AnyCancellable> = []
    
    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        self.scope = .user
    }
}

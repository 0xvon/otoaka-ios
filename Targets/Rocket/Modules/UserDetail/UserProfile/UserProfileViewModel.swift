//
//  UserProfileViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/01.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent

class UserProfileViewModel {
    struct State {
        let user: User
        var rankings: [GroupTip] = []
        var liveSchedule: [LiveFeed] = []
    }
    
    enum Output {
        case didGetRanking([GroupTip])
        case didGetLiveSchedule([LiveFeed])
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private lazy var getFollowingGroupsAction = Action(FollowingGroups.self, httpClient: self.apiClient)
    private lazy var getLiveScheduleAction = Action(GetLikedFutureLive.self, httpClient: self.apiClient)
    private lazy var getGroupRankingAction = Action(GetUserTipToGroupRanking.self, httpClient: self.apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: User) {
        self.dependencyProvider = dependencyProvider
        self.state = State(user: input)
        
        let errors = Publishers.MergeMany(
            getGroupRankingAction.errors,
            getLiveScheduleAction.errors
        )
        
        Publishers.MergeMany(
            getGroupRankingAction.elements.map { Output.didGetRanking($0.items) }.eraseToAnyPublisher(),
            getLiveScheduleAction.elements.map { Output.didGetLiveSchedule($0.items) }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getGroupRankingAction.elements
            .combineLatest(getLiveScheduleAction.elements)
            .sink(receiveValue: { [unowned self] rankings, liveSchedule in
                state.rankings = rankings.items
                state.liveSchedule = liveSchedule.items
            })
            .store(in: &cancellables)
    }
    
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getRankings()
        getLiveSchedule()
    }
    
    func getRankings() {
        var uri = GetUserTipToGroupRanking.URI()
        uri.userId = state.user.id
        uri.page = 1
        uri.per = 2
        getGroupRankingAction.input((request: Empty(), uri: uri))
    }
    
    func getLiveSchedule() {
        var uri = GetLikedFutureLive.URI()
        uri.userId = state.user.id
        uri.page = 1
        uri.per = 3
        getLiveScheduleAction.input((request: Empty(), uri: uri))
    }
}

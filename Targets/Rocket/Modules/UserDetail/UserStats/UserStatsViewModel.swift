//
//  UserStatsViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/02.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent

class UserStatsViewModel {
    struct State {
        let user: User
        var liveTransition: LiveTransition? = nil
        var frequentlyWatchingGroups: [GroupFeed] = []
        var groupTipRanking: [GroupTip] = []
        var socialTip: SocialTip? = nil
    }
    
    enum Output {
        case didGetLiveTransition(LiveTransition)
        case didGetFrequentlyWathingGroups([GroupFeed])
        case didGetUserTipRanking([GroupTip])
        case didGetUserTip(SocialTip?)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private lazy var getLiveTransitionAction = Action(GetLikedLiveTransition.self, httpClient: self.apiClient)
    private lazy var getFrequentlyWathingGroupsAction = Action(FrequentlyWatchingGroups.self, httpClient: self.apiClient)
    private lazy var getUserTipRankingAction = Action(GetUserTipToGroupRanking.self, httpClient: apiClient)
    private lazy var getUserTipAction = Action(GetUserTips.self, httpClient: apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: User) {
        self.dependencyProvider = dependencyProvider
        self.state = State(user: input)
        
        let errors = Publishers.MergeMany(
            getLiveTransitionAction.errors,
            getFrequentlyWathingGroupsAction.errors,
            getUserTipRankingAction.errors,
            getUserTipAction.errors
        )
        .map(Output.reportError)
        .eraseToAnyPublisher()
        
        Publishers.MergeMany(
            getLiveTransitionAction.elements.map(Output.didGetLiveTransition).eraseToAnyPublisher(),
            getFrequentlyWathingGroupsAction.elements.map { Output.didGetFrequentlyWathingGroups($0.items) }.eraseToAnyPublisher(),
            getUserTipRankingAction.elements.map {
                Output.didGetUserTipRanking($0.items)
            }.eraseToAnyPublisher(),
            getUserTipAction.elements.map {
                Output.didGetUserTip($0.items.first)
            }.eraseToAnyPublisher(),
            errors
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getLiveTransitionAction.elements
            .combineLatest(getFrequentlyWathingGroupsAction.elements, getUserTipAction.elements)
            .sink(receiveValue: { [unowned self] liveTransition, groups, socialTips in
                state.liveTransition = liveTransition
                state.frequentlyWatchingGroups = groups.items
//                state.groupTipRanking = groupTip.items
                state.socialTip = socialTips.items.first
            })
            .store(in: &cancellables)
    }
    
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getLiveTransition()
        getFrequentlyWatchingGroups()
//        getUserTip()
        socialTip()
    }
    
    func getLiveTransition() {
        var uri = GetLikedLiveTransition.URI()
        uri.userId = state.user.id
        getLiveTransitionAction.input((request: Empty(), uri: uri))
    }
    
    func getFrequentlyWatchingGroups() {
        var uri = FrequentlyWatchingGroups.URI()
        uri.page = 1
        uri.per = 3
        uri.userId = state.user.id
        getFrequentlyWathingGroupsAction.input((request: Empty(), uri: uri))
    }
    
    func getUserTip() {
        var uri = GetUserTipToGroupRanking.URI()
        uri.userId = state.user.id
        uri.page = 1
        uri.per = 3
        getUserTipRankingAction.input((request: Empty(), uri: uri))
    }
    
    func socialTip() {
        var uri = GetUserTips.URI()
        uri.userId = state.user.id
        uri.page = 1
        uri.per = 1
        getUserTipAction.input((request: Empty(), uri: uri))
    }
}

//
//  NichiTagCanvasViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2022/02/15.
//

import Combine
import Endpoint
import UIKit

final class NichiTagCanvasViewModel {
    struct State {
        var recentlyFollowingGroups: [GroupFeed] = []
        var followingGroups: [GroupFeed] = []
        
        var liveSchedule: [LiveFeed] = []
        var liveTransition: LiveTransition? = nil
        var frequentlyWatchingGroups: [GroupFeed] = []
    }
    
    enum Output {
        case getLeftItem
        case getRightItem
        case error(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var getFollowingGroupsAction = Action(FollowingGroups.self, httpClient: self.apiClient)
    private lazy var getRecentlyFollowingGroupsAction = Action(RecentlyFollowingGroups.self, httpClient: self.apiClient)
    private lazy var getLiveScheduleAction = Action(GetLikedFutureLive.self, httpClient: self.apiClient)
    private lazy var getLiveTransitionAction = Action(GetLikedLiveTransition.self, httpClient: self.apiClient)
    private lazy var getFrequentlyWathingGroupsAction = Action(FrequentlyWatchingGroups.self, httpClient: self.apiClient)
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        Publishers.MergeMany(
            getFollowingGroupsAction.errors,
            getRecentlyFollowingGroupsAction.errors,
            getLiveScheduleAction.errors,
            getLiveTransitionAction.errors,
            getFrequentlyWathingGroupsAction.errors
        )
            .map(Output.error)
            .eraseToAnyPublisher()
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
        
        getFollowingGroupsAction.elements.combineLatest(getRecentlyFollowingGroupsAction.elements, getLiveScheduleAction.elements)
            .sink(receiveValue: { [unowned self] followingGroups, recentlyFollowingGroups, liveSchedule in
                state.followingGroups = followingGroups.items
                state.recentlyFollowingGroups = recentlyFollowingGroups
                state.liveSchedule = liveSchedule.items
                outputSubject.send(.getLeftItem)
            })
            .store(in: &cancellables)
        
        getLiveTransitionAction.elements.combineLatest(getFrequentlyWathingGroupsAction.elements)
            .sink(receiveValue: { [unowned self] liveTransition, frequentlyWatchingGroups in
                state.liveTransition = liveTransition
                state.frequentlyWatchingGroups = frequentlyWatchingGroups.items
                outputSubject.send(.getRightItem)
            })
            .store(in: &cancellables)
    }
    
    func refresh() {
        getFollowingGroups()
        getRecentlyFollowingGroups()
        getLiveSchedule()
        getLiveTransition()
        getFrequentlyWatchingGroups()
    }
    
    func getFollowingGroups() {
        var uri = FollowingGroups.URI()
        uri.id = dependencyProvider.user.id
        uri.page = 1
        uri.per = 5
        getFollowingGroupsAction.input((request: Empty(), uri: uri))
        
    }
    
    func getRecentlyFollowingGroups() {
        var uri = RecentlyFollowingGroups.URI()
        uri.id = dependencyProvider.user.id
        getRecentlyFollowingGroupsAction.input((request: Empty(), uri: uri))
    }
    
    func getLiveSchedule() {
        var uri = GetLikedFutureLive.URI()
        uri.userId = dependencyProvider.user.id
        uri.page = 1
        uri.per = 3
        getLiveScheduleAction.input((request: Empty(), uri: uri))
    }
    
    func getLiveTransition() {
        var uri = GetLikedLiveTransition.URI()
        uri.userId = dependencyProvider.user.id
        getLiveTransitionAction.input((request: Empty(), uri: uri))
    }
    
    func getFrequentlyWatchingGroups() {
        var uri = FrequentlyWatchingGroups.URI()
        uri.page = 1
        uri.per = 3
        uri.userId = dependencyProvider.user.id
        getFrequentlyWathingGroupsAction.input((request: Empty(), uri: uri))
    }
}

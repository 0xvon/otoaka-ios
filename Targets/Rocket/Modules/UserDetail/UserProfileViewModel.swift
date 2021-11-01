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
    enum SumamryRow {
        case following, recentlyFollowing, liveSchedule
    }
    
    struct State {
        let user: User
        var followingGroups: [GroupFeed] = []
        var recentlyFollowingGroups: [GroupFeed] = []
        var liveSchedule: [LiveFeed] = []
    }
    
    enum Output {
        case didGetRecentlyFollowing([GroupFeed])
        case didGetFollowing([GroupFeed])
        case didGetLiveSchedule([LiveFeed])
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private lazy var getFollowingGroupsAction = Action(FollowingGroups.self, httpClient: self.apiClient)
    private lazy var getRecentlyFollowingGroupsAction = Action(RecentlyFollowingGroups.self, httpClient: self.apiClient)
    private lazy var getLiveScheduleAction = Action(GetLikedFutureLive.self, httpClient: self.apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    init(dependencyProvider: LoggedInDependencyProvider, input: User) {
        self.dependencyProvider = dependencyProvider
        self.state = State(user: input)
        
        let errors = Publishers.MergeMany(
            getFollowingGroupsAction.errors,
            getRecentlyFollowingGroupsAction.errors,
            getLiveScheduleAction.errors
        )
        
        Publishers.MergeMany(
            getRecentlyFollowingGroupsAction.elements.map { Output.didGetRecentlyFollowing($0) }.eraseToAnyPublisher(),
            getFollowingGroupsAction.elements.map { Output.didGetFollowing($0.items) }.eraseToAnyPublisher(),
            getLiveScheduleAction.elements.map { Output.didGetLiveSchedule($0.items) }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        getFollowingGroupsAction.elements
            .combineLatest(getRecentlyFollowingGroupsAction.elements, getLiveScheduleAction.elements)
            .sink(receiveValue: { [unowned self] followings, recentlyFollowings, liveSchedule in
                state.followingGroups = followings.items
                state.recentlyFollowingGroups = recentlyFollowings
                state.liveSchedule = liveSchedule.items
            })
            .store(in: &cancellables)
    }
    
    func viewDidLoad() {
        refresh()
    }
    
    func refresh() {
        getFollowingGroups()
        getRecentlyFollowingGroups()
        getLiveSchedule()
    }
    
    func getFollowingGroups() {
        var uri = FollowingGroups.URI()
        uri.id = state.user.id
        uri.page = 1
        uri.per = 15
        getFollowingGroupsAction.input((request: Empty(), uri: uri))
        
    }
    
    func getRecentlyFollowingGroups() {
        var uri = RecentlyFollowingGroups.URI()
        uri.id = state.user.id
        getRecentlyFollowingGroupsAction.input((request: Empty(), uri: uri))
    }
    
    func getLiveSchedule() {
        var uri = GetLikedFutureLive.URI()
        uri.userId = state.user.id
        uri.page = 1
        uri.per = 3
        getLiveScheduleAction.input((request: Empty(), uri: uri))
    }
}

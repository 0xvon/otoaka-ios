//
//  FollowingViewModel.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/28.
//

import Combine
import Endpoint
import Foundation

class FollowingViewModel {
    struct State {
        let group: Group.ID
        var isFollowing: Bool?
        var followersCount: Int?
    }

    enum Output {
        case updateIsButtonEnabled(Bool)
        case updateFollowersCount(Int)
        case updateFollowing(Bool)
        case reportError(Error)
    }

    private(set) var state: State

    private let apiClient: APIClient
    private lazy var unfollowGroupAction = Action(UnfollowGroup.self, httpClient: self.apiClient)
    private lazy var followGroupAction = Action(FollowGroup.self, httpClient: self.apiClient)
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []

    init(group: Group.ID, apiClient: APIClient) {
        self.apiClient = apiClient
        self.state = State(group: group, isFollowing: nil)
        
        let errors = Publishers.MergeMany(
            followGroupAction.errors,
            unfollowGroupAction.errors
        )
        
        Publishers.MergeMany(
            followGroupAction.elements.map { _ in .updateFollowing(true) }.eraseToAnyPublisher(),
            unfollowGroupAction.elements.map { _ in .updateFollowing(false) }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        followGroupAction.elements
            .sink(receiveValue: { [unowned self] _ in
                guard let count = state.followersCount else { return }
                state.followersCount = count + 1
                state.isFollowing = true
                outputSubject.send(.updateFollowersCount(count + 1))
                outputSubject.send(.updateIsButtonEnabled(true))
            })
            .store(in: &cancellables)
        
        unfollowGroupAction.elements
            .sink(receiveValue: { [unowned self] _ in
                guard let count = state.followersCount else { return }
                state.followersCount = count - 1
                state.isFollowing = false
                outputSubject.send(.updateFollowersCount(count - 1))
                outputSubject.send(.updateIsButtonEnabled(true))
            })
            .store(in: &cancellables)
    }

    func viewDidLoad() {
        outputSubject.send(.updateIsButtonEnabled(false))
    }

    func didGetGroupDetail(isFollowing: Bool, followersCount: Int) {
        state.isFollowing = isFollowing
        state.followersCount = followersCount
        outputSubject.send(.updateIsButtonEnabled(true))
        outputSubject.send(.updateFollowing(isFollowing))
        outputSubject.send(.updateFollowersCount(followersCount))
    }

    func didButtonTapped() {
        guard let isFollowing = state.isFollowing else {
            preconditionFailure("Button shouldn't be enabled before got isFollowing")
        }
        outputSubject.send(.updateIsButtonEnabled(false))
        if isFollowing {
            let req = UnfollowGroup.Request(groupId: state.group)
            unfollowGroupAction.input((request: req, uri: UnfollowGroup.URI()))
        } else {
            let req = FollowGroup.Request(groupId: state.group)
            followGroupAction.input((request: req, uri: FollowGroup.URI()))
        }
    }
}

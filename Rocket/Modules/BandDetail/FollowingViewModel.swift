//
//  FollowingViewModel.swift
//  Rocket
//
//  Created by kateinoigakukun on 2020/12/28.
//

import Endpoint
import Foundation
import Combine

class FollowingViewModel {
    struct State {
        let group: Group.ID
        var isFollowing: Bool?
        var followersCount: Int?
    }
    
    enum Output {
        case updateIsButtonEnabled(Bool)
        case updateFollowing(Bool)
        case updateFollowersCount(Int)
        case reportError(Error)
    }

    private var state: State

    private let apiClient: APIClient
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(group: Group.ID, apiClient: APIClient) {
        self.apiClient = apiClient
        self.state = State(group: group, isFollowing: nil)
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
            apiClient.request(UnfollowGroup.self, request: req) { [unowned self] in
                self.updateState(with: $0, didFollow: false)
            }
        } else {
            let req = FollowGroup.Request(groupId: state.group)
            apiClient.request(FollowGroup.self, request: req) { [unowned self] in
                self.updateState(with: $0, didFollow: false)
            }
        }
    }

    private func updateState<T>(with result: Result<T, Error>, didFollow: Bool) {
        guard let count = state.followersCount else {
            preconditionFailure("Button shouldn't be enabled before got followersCount")
        }
        outputSubject.send(.updateIsButtonEnabled(true))
        switch result {
        case .success(_):
            state.isFollowing = didFollow
            let newCount = count + (didFollow ? 1 : -1)
            state.followersCount = newCount
            outputSubject.send(.updateFollowersCount(newCount))
            outputSubject.send(.updateFollowing(didFollow))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}


//
//  UserFollowingViewModel.swift
//  ImagePipeline
//
//  Created by Masato TSUTSUMI on 2021/02/28.
//

import Combine
import Endpoint
import Foundation

class UserFollowingViewModel {
    struct State {
        let user: User
        let selfUser: User
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
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var unfollowUserAction = Action(UnfollowUser.self, httpClient: self.apiClient)
    private lazy var followUserAction = Action(FollowUser.self, httpClient: self.apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, user: User
    ) {
        self.apiClient = dependencyProvider.apiClient
        self.state = State(user: user, selfUser: dependencyProvider.user)
        
        let errors = Publishers.MergeMany(
            followUserAction.errors,
            unfollowUserAction.errors
        )
        
        Publishers.MergeMany(
            followUserAction.elements.map { _ in .updateFollowing(true) }.eraseToAnyPublisher(),
            unfollowUserAction.elements.map { _ in
                .updateFollowing(false)
            }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        followUserAction.elements
            .sink(receiveValue: { [unowned self] _ in
                guard let count = state.followersCount else { return }
                state.followersCount = count + 1
                state.isFollowing = true
                outputSubject.send(.updateFollowersCount(count + 1))
                outputSubject.send(.updateIsButtonEnabled(true))
            })
            .store(in: &cancellables)
        
        unfollowUserAction.elements
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
    
    func didGetUserDetail(isFollowing: Bool, followersCount: Int) {
        state.isFollowing = isFollowing
        state.followersCount = followersCount
        outputSubject.send(.updateFollowing(isFollowing))
        outputSubject.send(.updateFollowersCount(followersCount))
        outputSubject.send(.updateIsButtonEnabled(true))
    }
    
    func didButtonTapped() {
        guard let isFollowing = state.isFollowing else {
            preconditionFailure("Button shouldn't be enabled before got isFollowing")
        }
        outputSubject.send(.updateIsButtonEnabled(false))
        if isFollowing {
            let req = UnfollowUser.Request(userId: state.user.id)
            unfollowUserAction.input((request: req, uri: UnfollowUser.URI()))
        } else {
            let req = FollowUser.Request(userId: state.user.id)
            followUserAction.input((request: req, uri: FollowUser.URI()))
        }
    }
}

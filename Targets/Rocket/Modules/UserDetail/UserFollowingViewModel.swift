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
    }
    
    enum Output {
        case updateFollowing
        case updateBlocking
        case reportError(Error)
    }
    
    private(set) var state: State

    private let apiClient: APIClient
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var unfollowUserAction = Action(UnfollowUser.self, httpClient: self.apiClient)
    private lazy var followUserAction = Action(FollowUser.self, httpClient: self.apiClient)
    private lazy var blockUserAction = Action(BlockUser.self, httpClient: self.apiClient)
    private lazy var unblockUserAction = Action(UnblockUser.self, httpClient: self.apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, user: User
    ) {
        self.apiClient = dependencyProvider.apiClient
        self.state = State(user: user, selfUser: dependencyProvider.user)
        
        let errors = Publishers.MergeMany(
            followUserAction.errors,
            unfollowUserAction.errors,
            blockUserAction.errors,
            unblockUserAction.errors
        )
        
        Publishers.MergeMany(
            followUserAction.elements.map { _ in .updateFollowing }.eraseToAnyPublisher(),
            unfollowUserAction.elements.map { _ in
                .updateFollowing
            }.eraseToAnyPublisher(),
            blockUserAction.elements.map { _ in .updateBlocking }.eraseToAnyPublisher(),
            unblockUserAction.elements.map { _ in .updateBlocking }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    func didButtonTapped(isFollowing: Bool) {
        if isFollowing {
            let req = UnfollowUser.Request(userId: state.user.id)
            unfollowUserAction.input((request: req, uri: UnfollowUser.URI()))
        } else {
            let req = FollowUser.Request(userId: state.user.id)
            followUserAction.input((request: req, uri: FollowUser.URI()))
        }
    }
    
    func didBlockButtonTapped(isBlocking: Bool) {
        if isBlocking {
            let req = UnblockUser.Request(userId: state.user.id)
            unblockUserAction.input((request: req, uri: UnblockUser.URI()))
        } else {
            let req = BlockUser.Request(userId: state.user.id)
            blockUserAction.input((request: req, uri: BlockUser.URI()))
        }
    }
    
    deinit {
        print("UserFollowingViewModel.deinit")
    }
}

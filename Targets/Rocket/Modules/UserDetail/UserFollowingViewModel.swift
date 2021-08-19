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
        case updateIsButtonEnabled(Bool)
        case updateFollowing
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
            followUserAction.elements.map { _ in .updateFollowing }.eraseToAnyPublisher(),
            unfollowUserAction.elements.map { _ in
                .updateFollowing
            }.eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        followUserAction.elements
            .sink(receiveValue: { [unowned self] _ in
                outputSubject.send(.updateIsButtonEnabled(true))
            })
            .store(in: &cancellables)
        
        unfollowUserAction.elements
            .sink(receiveValue: { [unowned self] _ in
                outputSubject.send(.updateIsButtonEnabled(true))
            })
            .store(in: &cancellables)
    }
    
    func viewDidLoad() {
        outputSubject.send(.updateIsButtonEnabled(false))
    }
    
    func didGetUserDetail() {
        outputSubject.send(.updateIsButtonEnabled(true))
    }
    
    func didButtonTapped(isFollowing: Bool) {
        outputSubject.send(.updateIsButtonEnabled(false))
        if isFollowing {
            let req = UnfollowUser.Request(userId: state.user.id)
            unfollowUserAction.input((request: req, uri: UnfollowUser.URI()))
        } else {
            let req = FollowUser.Request(userId: state.user.id)
            followUserAction.input((request: req, uri: FollowUser.URI()))
        }
    }
    
    deinit {
        print("UserFollowingViewModel.deinit")
    }
}

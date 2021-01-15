//
//  RootViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/01/15.
//

import Foundation
import Endpoint
import Combine

class RootViewModel {
    enum Output {
        case didGetSignupStatus(Bool)
        case didGetUserInfo(User)
        case reportError(Error)
    }
    
    let dependencyProvider: DependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    
    private lazy var signupStatus = Action(SignupStatus.self, httpClient: self.dependencyProvider.apiClient)
    private lazy var getUserInfo = Action(GetUserInfo.self, httpClient: self.dependencyProvider.apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    init(
        dependencyProvider: DependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        
        let errors = Publishers.MergeMany(
            signupStatus.errors,
            getUserInfo.errors
        )
        
        Publishers.MergeMany(
            signupStatus.elements.map { .didGetSignupStatus($0.isSignedup) }.eraseToAnyPublisher(),
            getUserInfo.elements.map(Output.didGetUserInfo).eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    func getSignupStatus() {
        signupStatus.input((request: Empty(), uri: SignupStatus.URI()))
    }
    
    func userInfo() {
        getUserInfo.input((request: Empty(), uri: GetUserInfo.URI()))
    }
}

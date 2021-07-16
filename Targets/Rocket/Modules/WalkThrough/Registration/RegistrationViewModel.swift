//
//  RegistrationViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/17.
//

import AWSCognitoAuth
import Endpoint
import Foundation
import Combine

class RegistrationViewModel {
    enum Output {
        case signupStatus(Bool)
        case didCreateUser(User)
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var signupStatus = Action(SignupStatus.self, httpClient: self.apiClient)
    private lazy var createUserAction = Action(Signup.self, httpClient: self.apiClient)
    
    init(auth: AWSCognitoAuth, apiClient: APIClient) {
        self.auth = auth
        self.apiClient = apiClient

        let errors = signupStatus.errors
            .filter { error in
                guard case .underlyingError(let error as NSError) = error else { return true }
                let isCognitoCancellError = error.domain == AWSCognitoAuthErrorDomain
                    && error.code == AWSCognitoAuthClientErrorType.errorUserCanceledOperation.rawValue
                return !isCognitoCancellError
            }
            .merge(with: createUserAction.errors)
        Publishers.MergeMany(
            signupStatus.elements.map {
                .signupStatus($0.isSignedup)
            }.eraseToAnyPublisher(),
            createUserAction.elements.map(Output.didCreateUser).eraseToAnyPublisher(),
            errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }

    func getSignupStatus() {
        signupStatus.input((request: Empty(), uri: SignupStatus.URI()))
    }
    
    func signup() {
        let request = Signup.Request(
            name: "ライブキッズ君",
            biography: nil,
            sex: nil,
            age: nil,
            liveStyle: nil,
            residence: nil,
            thumbnailURL: "https://rocket-auth-storage.s3.ap-northeast-1.amazonaws.com/assets/public/default.jpeg",
            role: .fan(Fan()),
            twitterUrl: nil,
            instagramUrl: nil
        )
        createUserAction.input((request: request, uri: Signup.URI()))
    }
}

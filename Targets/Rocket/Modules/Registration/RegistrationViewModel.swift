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
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    init(auth: AWSCognitoAuth, apiClient: APIClient) {
        self.auth = auth
        self.apiClient = apiClient
    }

    func getSignupStatus() {
        apiClient.request(SignupStatus.self) { [unowned self] result in
            switch result {
            case .success(let res):
                self.outputSubject.send(.signupStatus(res.isSignedup))
            case .failure(let error as NSError) where
                    error.domain == AWSCognitoAuthErrorDomain &&
                    error.code == AWSCognitoAuthClientErrorType.errorUserCanceledOperation.rawValue:
                break
            case .failure(let error):
                self.outputSubject.send(.error(error))
            }
        }
    }
}

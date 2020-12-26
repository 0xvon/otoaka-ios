//
//  AccountViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/29.
//

import AWSCognitoAuth
import Endpoint
import UIKit

class AccountViewModel {
    enum Output {
        case getRequestCount(Int)
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let user: User
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, user: User, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.user = user
        self.auth = auth
        self.outputHandler = outputHander
    }
    
    func getPerformanceRequest() {
        let req = Empty()
        apiClient.request(GetPendingRequestCount.self, request: req) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.getRequestCount(res.pendingRequestCount))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
}

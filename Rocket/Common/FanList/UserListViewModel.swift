//
//  FanListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/08.
//

import UIKit
import Endpoint
import AWSCognitoAuth

class UserListViewModel {
    enum Output {
        case getFans([User])
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let input: UserListViewController.InputType
    let apiClient: APIClient
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, input: UserListViewController.InputType, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.input = input
        self.auth = auth
        self.outputHandler = outputHander
    }
    
    func getFans() {
        
    }
}

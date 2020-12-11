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
    
    func getFans(inputType: UserListViewController.InputType) {
        switch inputType {
        case .followers(let groupId):
            var uri = GroupFollowers.URI()
            uri.id = groupId
            uri.page = 1
            uri.per = 100
            let req = Empty()
            apiClient.request(GroupFollowers.self, request: req, uri: uri) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.getFans(res.items))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        default:
            print("hello")
        }
    }
}

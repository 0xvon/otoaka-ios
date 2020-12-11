//
//  BandContentsListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/06.
//

import UIKit
import AWSCognitoAuth
import Endpoint

class BandContentsListViewModel {
    enum Output {
        case getContents([GroupFeed])
        case error(Error)
    }

    let auth: AWSCognitoAuth
    let group: Group
    let apiClient: APIClient
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, group: Group, auth: AWSCognitoAuth,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.group = group
        self.auth = auth
        self.outputHandler = outputHander
    }
    
    func getContents() {
        var uri = GetGroupFeed.URI()
        uri.groupId = self.group.id
        uri.per = 1
        uri.page = 1
        let request = Empty()
        apiClient.request(GetGroupFeed.self, request: request, uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.getContents(res.items))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
}


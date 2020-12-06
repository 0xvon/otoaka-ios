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
        case getContents([String])
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
        
    }
}


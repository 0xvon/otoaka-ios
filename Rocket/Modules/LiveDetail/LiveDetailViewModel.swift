//
//  LiveDetailViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/24.
//

import Foundation
import Endpoint
import AWSCognitoAuth

class LiveDetailViewModel {
    enum Output {
        case getLive(Live)
        case error(Error)
    }
    
    let auth: AWSCognitoAuth
    let apiClient: APIClient
    let outputHandler: (Output) -> Void
    
    init(apiClient: APIClient, auth: AWSCognitoAuth, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.auth = auth
        self.outputHandler = outputHander
    }
    
    func getLive(liveId: Live.ID) {
        var uri = GetLive.URI()
        uri.liveId = liveId
        let req = Empty()
        
        do {
            try apiClient.request(GetLive.self, request: req, uri: uri) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.getLive(res))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        } catch let error {
            self.outputHandler(.error(error))
        }
    }
}

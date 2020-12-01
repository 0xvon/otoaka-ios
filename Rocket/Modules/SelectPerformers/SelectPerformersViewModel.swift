//
//  SearchBandViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/01.
//

import UIKit
import Endpoint
import AWSCognitoAuth

class SelectPerformersViewModel {
    enum Output {
        case search([Group])
        case error(Error)
    }

    let apiClient: APIClient
    let s3Client: S3Client
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, s3Bucket: String, outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.s3Client = S3Client(s3Bucket: s3Bucket)
        self.outputHandler = outputHander
    }
    
    func searchGroup(query: String) {
        var uri = GetAllGroups.URI()
        uri.page = 1
        uri.per = 1000
        let req = Empty()
        apiClient.request(GetAllGroups.self, request: req, uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.search(res.items))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }
}


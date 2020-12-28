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
        case paginate([Group])
        case search([Group])
        case error(Error)
    }

    let apiClient: APIClient
    let s3Client: S3Client
    let outputHandler: (Output) -> Void
    
    var searchGroupPaginationRequest: PaginationRequest<SearchGroup>? = nil

    init(
        apiClient: APIClient, s3Client: S3Client, outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.s3Client = s3Client
        self.outputHandler = outputHander
    }
    
    func searchGroup(query: String) {
        var uri = SearchGroup.URI()
        uri.term = query
        searchGroupPaginationRequest = PaginationRequest<SearchGroup>(apiClient: apiClient, uri: uri)
        
        searchGroupPaginationRequest?.subscribe { result in
            switch result {
            case .initial(let res):
                self.outputHandler(.search(res.items))
            case .next(let res):
                self.outputHandler(.paginate(res.items))
            case .error(let err):
                self.outputHandler(.error(err))
            }
        }
        
        searchGroupPaginationRequest?.next()
    }
    
    func paginateGroup() {
        searchGroupPaginationRequest?.next()
    }
    
    func refreshSearchGroup() {
        searchGroupPaginationRequest?.next(isNext: false)
    }
}


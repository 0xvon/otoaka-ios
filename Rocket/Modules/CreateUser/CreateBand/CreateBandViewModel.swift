//
//  CreateBandViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import Foundation
import UIKit
import Endpoint

class CreateBandViewModel {
    enum Output {
        case create(Endpoint.Group)
        case error(String)
    }
    
    let idToken: String
    let apiEndpoint: String
    let s3Client: S3Client
    let outputHandler: (Output) -> Void
    
    init(idToken: String, apiEndpoint: String, s3Bucket: String, outputHander: @escaping (Output) -> Void) {
        self.idToken = idToken
        self.apiEndpoint = apiEndpoint
        self.s3Client = S3Client(s3Bucket: s3Bucket)
        self.outputHandler = outputHander
    }
    
    func create(name: String, englishName: String?, biography: String?,
                since: Date?, artwork: UIImage?, hometown: String?) {
        self.s3Client.uploadImage(image: artwork) { (imageUrl, error) in
            if let error = error { self.outputHandler(.error(error)) }
            guard let imageUrl = imageUrl else { return }
            
            let createGroupAPIClient = APIClient<CreateGroup>(baseUrl: self.apiEndpoint, idToken: self.idToken)
            let req: CreateGroup.Request = CreateGroup.Request(name: name, englishName: englishName, biography: biography, since: since, artworkURL: URL(string: imageUrl), hometown: hometown)
            
            createGroupAPIClient.request(req: req) { res in
                self.outputHandler(.create(res))
            }
        }
    }
}

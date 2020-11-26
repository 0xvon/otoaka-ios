//
//  CreateUserViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/10/31.
//

import Endpoint
import Foundation
import UIKit

class CreateUserViewModel {
    enum Output {
        case artist(User)
        case fan(User)
        case error(Error)
    }

    let apiClient: APIClient
    let s3Client: S3Client
    let outputHandler: (Output) -> Void

    init(apiClient: APIClient, s3Bucket: String, outputHander: @escaping (Output) -> Void) {
        self.apiClient = apiClient
        self.s3Client = S3Client(s3Bucket: s3Bucket)
        self.outputHandler = outputHander
    }

    func signupAsFan(name: String, thumbnail: UIImage?) {
        self.s3Client.uploadImage(image: thumbnail) { [apiClient] (imageUrl, error) in
            let req = Signup.Request(
                name: name, biography: nil, thumbnailURL: imageUrl, role: .fan(Fan()))
            apiClient.request(Signup.self, request: req) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.fan(res))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        }
    }

    func signupAsArtist(name: String, thumbnail: UIImage?, part: String) {
        self.s3Client.uploadImage(image: thumbnail) { [apiClient] (imageUrl, error) in
            let req = Signup.Request(
                name: name, biography: nil, thumbnailURL: imageUrl,
                role: .artist(Artist(part: part)))
            apiClient.request(Signup.self, request: req) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.artist(res))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        }
    }
}

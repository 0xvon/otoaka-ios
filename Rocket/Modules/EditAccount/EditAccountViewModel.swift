//
//  EditAccountViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import AWSCognitoAuth
import Endpoint
import UIKit

class EditAccountViewModel {
    enum Output {
        case editAccount(User)
        case error(Error)
    }

    let apiClient: APIClient
    let s3Client: S3Client
    let user: User
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, s3Client: S3Client, user: User, outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.s3Client = s3Client
        self.user = user
        self.outputHandler = outputHander
    }

    func editAccount(
        name: String, biography: String?, thumbnail: UIImage?, role: RoleProperties
    ) {
        self.s3Client.uploadImage(image: thumbnail) { [apiClient] result in
            switch result {
            case .success(let imageUrl):
                let req = EditUserInfo.Request(
                    name: name, biography: biography, thumbnailURL: imageUrl, role: role)
                apiClient.request(EditUserInfo.self, request: req) { result in
                    switch result {
                    case .success(let res):
                        self.outputHandler(.editAccount(res))
                    case .failure(let error):
                        self.outputHandler(.error(error))
                    }
                }
            case .failure(let error):
                self.outputHandler(.error(error))
            }
            
        }
    }
}

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
        apiClient: APIClient, s3Bucket: String, user: User, outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.s3Client = S3Client(s3Bucket: s3Bucket)
        self.user = user
        self.outputHandler = outputHander
    }

    func editAccount(
        id: User.ID, name: String, biography: String?, thumbnail: UIImage?, role: RoleProperties
    ) {
        let imageUrl: String = "aaa"
        let user = User(
            id: id, name: name, biography: biography, thumbnailURL: imageUrl, role: role)
        outputHandler(.editAccount(user))
    }
}

//
//  EditGroupViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import AWSCognitoAuth
import Endpoint
import UIKit

class EditBandViewModel {
    enum Output {
        case editGroup(Group)
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

    func editGroup(
        id: Group.ID, name: String, englishName: String, biography: String?, since: Date?,
        thumbnail: UIImage?, youtubeChannelId: String?, twitterId: String?, hometown: String?
    ) {
        self.s3Client.uploadImage(image: thumbnail) { [apiClient] result in
            switch result {
            case .success(let imageUrl):
                let req = EditGroup.Request(
                    name: name, englishName: englishName, biography: biography, since: since,
                    artworkURL: URL(string: imageUrl), twitterId: twitterId, youtubeChannelId: youtubeChannelId, hometown: hometown)
                var uri = EditGroup.URI()
                uri.id = id
                apiClient.request(EditGroup.self, request: req, uri: uri) { result in
                    switch result {
                    case .success(let res):
                        self.outputHandler(.editGroup(res))
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

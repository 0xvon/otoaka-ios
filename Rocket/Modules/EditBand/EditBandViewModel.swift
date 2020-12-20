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
        let imageUrl: String = "aaa"

        var uri = EditGroup.URI()
        uri.id = id
        let request = EditGroup.Request(
            name: name, englishName: englishName, biography: biography, since: since,
            artworkURL: URL(string: imageUrl), twitterId: twitterId, youtubeChannelId: youtubeChannelId, hometown: hometown)
    }
}

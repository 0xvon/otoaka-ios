//
//  EditLiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Endpoint
import Foundation
import UIKit

class EditLiveViewModel {
    enum Output {
        case editLive(Endpoint.Live)
        case getHostGroups([Endpoint.Group])
        case error(Error)
    }

    let apiClient: APIClient
    let live: Live
    let s3Client: S3Client
    let user: User
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, live: Live, s3Bucket: String, user: User,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.live = live
        self.s3Client = S3Client(s3Bucket: s3Bucket)
        self.user = user
        self.outputHandler = outputHander
    }

    func getMyGroups() {
        let request = Empty()
        var uri = Endpoint.GetMemberships.URI()
        uri.artistId = self.user.id
        apiClient.request(GetMemberships.self, request: request, uri: uri) { result in
            switch result {
            case .success(let res):
                self.outputHandler(.getHostGroups(res))
            case .failure(let error):
                self.outputHandler(.error(error))
            }
        }
    }

    func editLive(
        title: String, liveId: Endpoint.Live.ID, livehouse: String, openAt: Date?, startAt: Date?,
        endAt: Date?, thumbnail: UIImage?
    ) {
        self.s3Client.uploadImage(image: thumbnail) { [apiClient] result in
            switch result {
            case .success(let imageUrl):
                var uri = EditLive.URI()
                uri.id = liveId

                let req = EditLive.Request(
                    title: title, artworkURL: URL(string: imageUrl), openAt: openAt, startAt: startAt,
                    endAt: endAt)
                apiClient.request(EditLive.self, request: req, uri: uri) { result in
                    switch result {
                    case .success(let res):
                        self.outputHandler(.editLive(res))
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

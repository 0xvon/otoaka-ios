//
//  CreateLiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/23.
//

import Endpoint
import Foundation
import UIKit

class CreateLiveViewModel {
    enum Output {
        case createLive(Endpoint.Live)
        case getHostGroups([Endpoint.Group])
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

//    func getGroups() {
//        let request = Empty()
//        var uri = Endpoint.GetAllGroups.URI()
//        uri.page = 1
//        uri.per = 1000
//        apiClient.request(GetAllGroups.self, request: request, uri: uri) { result in
//            switch result {
//            case .success(let res):
//                self.outputHandler(.getPerformers(res.items))
//            case .failure(let error):
//                self.outputHandler(.error(error))
//            }
//        }
//    }

    func createLive(
        title: String, style: LiveStyleInput, price: Int, hostGroupId: Endpoint.Group.ID, livehouse: String?,
        openAt: Date?, startAt: Date?, endAt: Date?, thumbnail: UIImage?
    ) {
        self.s3Client.uploadImage(image: thumbnail) { [apiClient] result in
            switch result {
            case .success(let imageUrl):
                let req = CreateLive.Request(
                    title: title, style: style, price: price, artworkURL: URL(string: imageUrl),
                    hostGroupId: hostGroupId, liveHouse: livehouse,
                    openAt: openAt, startAt: startAt, endAt: endAt)
                apiClient.request(CreateLive.self, request: req) { result in
                    switch result {
                    case .success(let res):
                        self.outputHandler(.createLive(res))
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

//
//  PostViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/02.
//

import UIKit
import Endpoint
import AWSCognitoAuth

class PostViewModel {
    enum Output {
        case post(ArtistFeed)
        case error(Error)
    }

    let apiClient: APIClient
    let s3Client: S3Client
    let user: User
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, s3Client: S3Client, user: User,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.s3Client = s3Client
        self.user = user
        self.outputHandler = outputHander
    }

    func post(postType: PostViewController.PostType, text: String) {
        switch postType {
        case .movie(_, _):
            break
//            if let url = url, let asset = asset {
//                print("yo")
//                self.s3Client.uploadMovie(url: url, asset: asset) { (videoUrl, error) in
//                    if let error = error {
//                        self.outputHandler(.error(ViewModelError.notFoundError(error)))
//                    }
//                    guard let videoUrl = videoUrl else { return }
//                    print(videoUrl)
//                    self.outputHandler(.post)
//                }
//            }
        case .spotify(let url):
            print(url!)
        case .youtube(let url):
            let request = CreateArtistFeed.Request(text: text, feedType: .youtube(url!))
            apiClient.request(CreateArtistFeed.self, request: request) { result in
                switch result {
                case .success(let res):
                    self.outputHandler(.post(res))
                case .failure(let error):
                    self.outputHandler(.error(error))
                }
            }
        }
    }
}

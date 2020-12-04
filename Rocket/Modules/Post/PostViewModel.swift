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
        case post
        case error(Error)
    }

    let apiClient: APIClient
    let s3Client: S3Client
    let user: User
    let outputHandler: (Output) -> Void

    init(
        apiClient: APIClient, s3Bucket: String, user: User,
        outputHander: @escaping (Output) -> Void
    ) {
        self.apiClient = apiClient
        self.s3Client = S3Client(s3Bucket: s3Bucket)
        self.user = user
        self.outputHandler = outputHander
    }

    func post(postType: PostViewController.PostType) {
        switch postType {
        case .movie(let url, let asset):
            if let url = url, let asset = asset {
                print("yo")
                self.s3Client.uploadMovie(url: url, asset: asset) { (videoUrl, error) in
                    if let error = error {
                        self.outputHandler(.error(ViewModelError.notFoundError(error)))
                    }
                    guard let videoUrl = videoUrl else { return }
                    print(videoUrl)
                    self.outputHandler(.post)
                }
            }
        case .spotify(let url):
            print(url!)
        case .youtube(let url):
            print(url!)
        }
    }
}

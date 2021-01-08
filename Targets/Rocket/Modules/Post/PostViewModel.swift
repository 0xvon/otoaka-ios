//
//  PostViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/02.
//

import UIKit
import Endpoint
import AWSCognitoAuth
import Photos
import PhotosUI
import AVKit
import Combine
import InternalDomain

class PostViewModel {
    enum PostType {
        case movie(URL, PHAsset?)
        case youtube(URL)
        case spotify(URL)
    }
    
    struct State {
        var post: PostType?
        var text: String?
        let maxLength: Int = 140
    }
    
    enum Output {
        case didPostArtistFeed(ArtistFeed)
        case updateSubmittableState(Bool)
        case didGetThumbnail(URL)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
    }
    
    func didUpdateInputText(text: String?) {
        self.state.text = text
        
        outputSubject.send(.updateSubmittableState((text != nil && state.post != nil)))
    }
    
    func didUpdatePost(post: PostType?) {
        self.state.post = post
        
        outputSubject.send(.updateSubmittableState((state.text != nil && post != nil)))
    }
    
    func getYouTubeThumbnail(url: String) {
        let youTubeClient = YouTubeClient(url: url)
        guard let thumbnail = youTubeClient.getThumbnailUrl() else { return }
        outputSubject.send(.didGetThumbnail(thumbnail))
    }

    func post() {
        outputSubject.send(.updateSubmittableState(false))
        guard let text = state.text else { return }
        guard let post = state.post else { return }
        switch post {
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
        case .spotify(_):
            break
        case .youtube(let url):
            let request = CreateArtistFeed.Request(text: text, feedType: .youtube(url))
            apiClient.request(CreateArtistFeed.self, request: request) { [unowned self] result in
                self.updateState(with: result)
            }
        }
    }
    
    private func updateState(with result: Result<ArtistFeed, Error>) {
        outputSubject.send(.updateSubmittableState(true))
        switch result {
        case .success(let feed):
            outputSubject.send(.updateSubmittableState(true))
            outputSubject.send(.didPostArtistFeed(feed))
        case .failure(let error):
            outputSubject.send(.updateSubmittableState(true))
            outputSubject.send(.reportError(error))
        }
    }
}

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
    
    enum ThumbnailType {
        case movie(URL)
        case youtube(URL)
        case none
    }
    
    struct State {
        var post: PostType?
        var text: String?
        let maxLength: Int = 140
    }
    
    enum PageState {
        case loading
        case completed
        case editting(Bool)
    }
    
    enum Output {
        case didPostArtistFeed(ArtistFeed)
        case updateSubmittableState(PageState)
        case didGetThumbnail(ThumbnailType)
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
        
        let submittable = (state.text != nil && state.post != nil)
        outputSubject.send(.updateSubmittableState(.editting(submittable)))
    }
    
    func didUpdatePost(post: PostType?) {
        self.state.post = post
        
        let submittable = (state.text != nil && state.post != nil)
        outputSubject.send(.updateSubmittableState(.editting(submittable)))
        if post == nil { outputSubject.send(.didGetThumbnail(.none)) }
    }
    
    func getYouTubeThumbnail(url: String) {
        let youTubeClient = YouTubeClient(url: url)
        guard let thumbnail = youTubeClient.getThumbnailUrl() else { return }
        outputSubject.send(.didGetThumbnail(.youtube(thumbnail)))
    }

    func post() {
        outputSubject.send(.updateSubmittableState(.loading))
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
        outputSubject.send(.updateSubmittableState(.completed))
        switch result {
        case .success(let feed):
            outputSubject.send(.didPostArtistFeed(feed))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}

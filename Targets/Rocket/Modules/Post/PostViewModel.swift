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
        case editting(Bool)
        case invalidUrl
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
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var createArtistFeedAction = Action(CreateArtistFeed.self, httpClient: self.apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        createArtistFeedAction.elements
            .map(Output.didPostArtistFeed).eraseToAnyPublisher()
            .merge(with: createArtistFeedAction.errors.map(Output.reportError))
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
        
        createArtistFeedAction.elements
            .sink(receiveValue: { [unowned self] _ in
                outputSubject.send(.updateSubmittableState(.editting(true)))
            })
            .store(in: &cancellables)
    }
    
    func didUpdateInputText(text: String?) {
        self.state.text = text
        
        let submittable = (state.text != nil && state.post != nil)
        outputSubject.send(.updateSubmittableState(.editting(submittable)))
    }
    
    func didUpdatePost(post: PostType?) {
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
            if let thumbnail = getYouTubeThumbnail(url: url.absoluteString) {
                self.state.post = post
                let submittable = (state.text != nil && state.post != nil)
                outputSubject.send(.updateSubmittableState(.editting(submittable)))
                outputSubject.send(.didGetThumbnail(.youtube(thumbnail)))
            } else {
                state.post = nil
                outputSubject.send(.updateSubmittableState(.invalidUrl))
                outputSubject.send(.didGetThumbnail(.none))
            }
        case nil:
            self.state.post = nil
        }
    }
    
    func getYouTubeThumbnail(url: String) -> URL?  {
        let youTubeClient = YouTubeClient(url: url)
        let thumbnail = youTubeClient.getThumbnailUrl()
        return thumbnail
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
            createArtistFeedAction.input((request: request, uri: CreateArtistFeed.URI()))
        }
    }
}

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
        case none
    }
    
    struct State {
        var post: PostType?
        var text: String?
        var title: String?
        var group: Group?
        var ogpUrl: String?
        let maxLength: Int = 140
    }
    
    enum PageState {
        case loading
        case editting(Bool)
        case invalidUrl
    }
    
    enum Output {
        case didPostArtistFeed(UserFeed)
        case updateSubmittableState(PageState)
        case didGetThumbnail(PostType)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var createUserFeedAction = Action(CreateUserFeed.self, httpClient: self.apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        createUserFeedAction.elements
            .map(Output.didPostArtistFeed).eraseToAnyPublisher()
            .merge(with: createUserFeedAction.errors.map(Output.reportError))
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
        
        createUserFeedAction.elements
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
    
    func didUpdatePost(post: PostType) {
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
        case .none:
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
        guard let title = state.title else { return }
        guard let group = state.group else { return }
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
            // TODO: fix logic
            let request = CreateUserFeed.Request(text: text, feedType: .youtube(url), ogpUrl: state.ogpUrl, groupId: group.id, title: title)
            createUserFeedAction.input((request: request, uri: CreateUserFeed.URI()))
        case .none: break
        }
    }
}

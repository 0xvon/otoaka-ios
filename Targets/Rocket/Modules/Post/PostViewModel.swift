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
        var thumbnailUrl: URL?
        var ogpUrl: String?
        let maxLength: Int = 40
    }
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    enum Output {
        case didPostUserFeed(UserFeed)
        case updateSubmittableState(PageState)
        case didSelectPost
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
            .map(Output.didPostUserFeed).eraseToAnyPublisher()
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
        validatePost()
    }
    
    func didSelectTrack(group: Group, track: InternalDomain.ChannelDetail.ChannelItem) {
        state.title = track.snippet?.title
        state.group = group
        if let videoId = track.id.videoId, let url = URL(string: "https://youtube.com/watch?v=\(videoId)") {
            state.post = .youtube(url)
        }
        
        if let snippet = track.snippet, let thumbnails = snippet.thumbnails, let high = thumbnails.high, let url = URL(string: high.url ?? "") {
            state.thumbnailUrl = url
        }
        
        outputSubject.send(.didSelectPost)
        validatePost()
    }
    
    func validatePost() {
        let submittable = (
            state.text != nil
                && state.text?.count ?? 0 <= state.maxLength
                && state.post != nil
                && state.thumbnailUrl != nil
                && state.title != nil
                && state.group != nil
        )
        
        outputSubject.send(.updateSubmittableState(.editting(submittable)))
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

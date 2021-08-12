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
    struct State {
        var text: String? = ""
        var images: [UIImage] = []
        var groups: [Group] = []
        var live: Live
        var tracks: [Endpoint.Track] = []
        let maxLength: Int = 140
    }
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    enum Output {
        case didPost(Post)
        case updateSubmittableState(PageState)
        case didUpdateContent
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var createPostAction = Action(CreatePost.self, httpClient: self.apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(
        dependencyProvider: LoggedInDependencyProvider, live: Live
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(live: live)
        
        createPostAction.elements
            .map(Output.didPost).eraseToAnyPublisher()
            .merge(with: createPostAction.errors.map(Output.reportError))
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
        
        createPostAction.elements
            .sink(receiveValue: { [unowned self] _ in
                outputSubject.send(.updateSubmittableState(.editting(true)))
            })
            .store(in: &cancellables)
    }
    
    func didUpdateInputText(text: String?) {
        self.state.text = text
        validatePost()
    }
    
    func didSelectTrack(tracks: [Endpoint.Track]) {
        state.tracks = tracks
        outputSubject.send(.didUpdateContent)
    }
    
    func didSelectGroup(groups: [Group]) {
        state.groups = groups
        outputSubject.send(.didUpdateContent)
    }
    
    func didUploadImages(images: [UIImage]) {
        state.images = images
        outputSubject.send(.didUpdateContent)
    }
    
    func validatePost() {
        let submittable = state.text != nil && state.text != ""
        outputSubject.send(.updateSubmittableState(.editting(submittable)))
    }

    func postButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        guard let image = state.images.first else {
            post(imageUrls: [])
            return
        }
        
        dependencyProvider.s3Client.uploadImage(image: image) { [weak self] result in
            switch result {
            case .success(let imageUrl):
                self?.post(imageUrls: [imageUrl])
            case .failure(let error):
                self?.outputSubject.send(.updateSubmittableState(.editting(true)))
                self?.outputSubject.send(.reportError(error))
            }
        }
    }
    
    func post(imageUrls: [String]) {
        guard let text = state.text else { return }
        let request = CreatePost.Request(
            author: dependencyProvider.user,
            live: state.live,
            text: text,
            tracks: state.tracks,
            groups: state.groups,
            imageUrls: imageUrls
        )
        createPostAction.input((request: request, uri: CreatePost.URI()))
    }
}

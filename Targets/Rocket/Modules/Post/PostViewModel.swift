//
//  PostViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/02.
//

import UIKit
import Endpoint
import Photos
import PhotosUI
import AVKit
import Combine
import InternalDomain

class PostViewModel {
    typealias Input = (
        live: Live,
        post: Post?
    )
    struct State {
        var post: Post?
        var text: String? = ""
        var images: [UIImage] = []
        var groups: [Group] = []
        var live: Live
        var tracks: [Endpoint.Track] = []
        let maxLength: Int = 5000
        var imageState: ImageState = .initial
    }
    
    enum ImageState {
        case initial, updated
    }
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    enum Output {
        case didPost(Post)
        case updateSubmittableState(PageState)
        case didInitContent
        case didUpdateContent
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var createPostAction = Action(CreatePost.self, httpClient: self.apiClient)
    private lazy var editPostAction = Action(EditPost.self, httpClient: self.apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(post: input.post, live: input.live)
        
        createPostAction.elements
            .map(Output.didPost).eraseToAnyPublisher()
            .merge(with: editPostAction.elements.map(Output.didPost).eraseToAnyPublisher())
            .merge(with: createPostAction.errors.map(Output.reportError).eraseToAnyPublisher())
            .merge(with: editPostAction.errors.map(Output.reportError).eraseToAnyPublisher())
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
        
        createPostAction.elements
            .combineLatest(editPostAction.elements)
            .sink(receiveValue: { [unowned self] _, _ in
                outputSubject.send(.updateSubmittableState(.editting(true)))
            })
            .store(in: &cancellables)
    }
    
    func viewDidLoad() {
        if let post = state.post {
            state.text = post.text
            state.groups = post.groups
            state.images = post.imageUrls.map { UIImage(url: $0) }
            state.tracks = post.tracks.map {
                Track(
                    name: $0.trackName,
                    artistName: $0.groupName,
                    artwork: $0.thumbnailUrl!,
                    trackType: $0.type
                )
            }
        }
        self.outputSubject.send(.didInitContent)
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
        state.groups = []
        outputSubject.send(.didUpdateContent)
    }
    
    func didUploadImage(image: UIImage) {
        state.images.append(image)
        state.imageState = .updated
        outputSubject.send(.didUpdateContent)
    }
    
    func didDeleteImage(at index: Int) {
        state.images.remove(at: index)
        state.imageState = .updated
        outputSubject.send(.didUpdateContent)
    }
    
    func validatePost() {
        let submittable = state.text != nil && state.text != ""
        outputSubject.send(.updateSubmittableState(.editting(submittable)))
    }

    func postButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        if state.imageState == .initial {
            self.post(imageUrls: state.post?.imageUrls ?? [])
        } else {
            guard let image = state.images.first else {
                self.post(imageUrls: [])
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
    }
    
    func post(imageUrls: [String]) {
        guard let text = state.text else { return }
        let request = CreatePost.Request(
            author: dependencyProvider.user.id,
            live: state.live.id,
            isPrivate: false,
            text: text,
            tracks: state.tracks,
            groups: state.groups,
            imageUrls: imageUrls
        )
        if let post = state.post {
            var uri = EditPost.URI()
            uri.id = post.id
            editPostAction.input((request: request, uri: uri))
        } else {
            createPostAction.input((request: request, uri: CreatePost.URI()))
        }
    }
}

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
//    enum PostType {
//        case movie(URL, PHAsset?)
//        case youtube(URL)
//        case spotify(URL)
//        case none
//    }
    
    struct State {
        var text: String?
        var track: InternalDomain.Track?
        var group: Group?
        var thumbnailUrl: URL?
        var ogpUrl: String?
        let maxLength: Int = 140
    }
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    enum Output {
        case didPostUserFeed(UserFeed)
        case updateSubmittableState(PageState)
        case didSelectTrack
        case didSelectGroup
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var createUserFeedAction = Action(CreateUserFeed.self, httpClient: self.apiClient)
    private lazy var searchGroupAction = Action(SearchGroup.self, httpClient: self.apiClient)
    
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
            .merge(with: searchGroupAction.errors.map(Output.reportError))
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
        
        createUserFeedAction.elements
            .sink(receiveValue: { [unowned self] _ in
                outputSubject.send(.updateSubmittableState(.editting(true)))
            })
            .store(in: &cancellables)
        
        searchGroupAction.elements
            .sink(receiveValue: { [unowned self] results in
                didSelectGroup(group: results.items.first)
            })
            .store(in: &cancellables)
    }
    
    func didUpdateInputText(text: String?) {
        self.state.text = text
        validatePost()
    }
    
    func didSelectTrack(track: InternalDomain.Track) {
        state.track = track
        outputSubject.send(.didSelectTrack)
        searchGroup(artistName: track.artistName)
        validatePost()
    }
    
    func searchGroup(artistName: String) {
        let request = Empty()
        var uri = SearchGroup.URI()
        uri.term = artistName
        uri.page = 1
        uri.per = 1
        searchGroupAction.input((request: request, uri: uri))
    }
    
    func cancelToSelectGroup() {
        state.track = nil
        outputSubject.send(.didSelectTrack)
    }
    
    func didSelectGroup(group: Group?) {
        state.group = group
        outputSubject.send(.didSelectGroup)
        validatePost()
    }
    
    func validatePost() {
        let submittable = (
            state.text != nil
                && state.text?.count ?? 0 <= state.maxLength
                && state.track != nil
                && state.group != nil
        )
        
        outputSubject.send(.updateSubmittableState(.editting(submittable)))
    }

    func postButtonTapped(ogpImage: UIImage) {
        outputSubject.send(.updateSubmittableState(.loading))
        dependencyProvider.s3Client.uploadImage(image: ogpImage) { [unowned self] res in
            switch res {
            case .success(let url):
                state.ogpUrl = url
                post()
            case .failure(let err):
                outputSubject.send(.reportError(err))
            }
        }
    }
    
    func post() {
        guard let text = state.text else { return }
        guard let track = state.track else { return }
        guard let group = state.group else { return }
        switch track.trackType {
        case .appleMusic(let musicId):
            let request = CreateUserFeed.Request(text: text, feedType: .appleMusic(musicId), ogpUrl: state.ogpUrl, thumbnailUrl: track.artwork, groupId: group.id, title: track.name)
            createUserFeedAction.input((request: request, uri: CreateUserFeed.URI()))
        case .youtube(let url):
            let request = CreateUserFeed.Request(text: text, feedType: .youtube(url), ogpUrl: state.ogpUrl, thumbnailUrl: track.artwork, groupId: group.id, title: track.name)
            createUserFeedAction.input((request: request, uri: CreateUserFeed.URI()))
        }
    }
}

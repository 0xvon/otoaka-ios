//
//  CreateBandViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/01.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent
import UIKit

class CreateBandViewModel {
    struct State {
        var name: String?
        var englishName: String?
        var biography: String?
        var since: Date?
        var artwork: UIImage?
        var youtubeChannelId: String?
        var twitterId: String?
        var hometown: String?
        let socialInputs: SocialInputs
    }
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    enum Output {
        case didCreateGroup(Group)
        case updateSubmittableState(PageState)
//        case didValidateYoutubeChannelId(Bool)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
//    private lazy var listChannelAction = Action(ListChannel.self, httpClient: dependencyProvider.youTubeDataApiClient)
    private lazy var createGroupAction = Action(CreateGroup.self, httpClient: apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(socialInputs: try! dependencyProvider.masterService.blockingMasterData())
        
        let errors = Publishers.MergeMany(
            createGroupAction.errors
        )
        
        Publishers.MergeMany(
//            listChannelAction.elements.map { _ in .didValidateYoutubeChannelId(true) }.eraseToAnyPublisher(),
            createGroupAction.elements.map { _ in .updateSubmittableState(.editting(true)) }.eraseToAnyPublisher(),
            createGroupAction.elements.map(Output.didCreateGroup).eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
//        listChannelAction.errors
//            .sink(receiveValue: { [unowned self] _ in
//                state.youtubeChannelId = nil
//                outputSubject.send(.didValidateYoutubeChannelId(false))
//            })
//            .store(in: &cancellables)
    }
    
//    func validateYoutubeChannelId(youtubeChannelId: String?) {
//        guard let youtubeChannelId = youtubeChannelId else { return }
//
//        let request = Empty()
//        var uri = ListChannel.URI()
//        uri.channelId = youtubeChannelId
//        uri.part = "snippet"
//        uri.maxResults = 1
//        uri.order = "viewCount"
//        listChannelAction.input((request: request, uri: uri))
//    }
    
    func didUpdateInputItems(
        name: String?, englishName: String?, biography: String?,
        since: Date?, youtubeChannelId: String?, twitterId: String?, hometown: String?
    ) {
        state.name = name
        state.englishName = englishName
        state.biography = biography
        state.since = since
        state.twitterId = twitterId
        state.youtubeChannelId = youtubeChannelId
        state.hometown = hometown
        
        submittable()
//        validateYoutubeChannelId(youtubeChannelId: youtubeChannelId)
    }
    
    func didUpdateArtwork(artwork: UIImage?) {
        self.state.artwork = artwork
        submittable()
    }
    
    func submittable() {
        let isSubmittable: Bool = (state.name != nil && state.artwork != nil)
        outputSubject.send(.updateSubmittableState(.editting(isSubmittable)))
    }

    func didRegisterButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        self.dependencyProvider.s3Client.uploadImage(image: state.artwork) { [weak self] result in
            switch result {
            case .success(let imageUrl):
                self?.createGroup(imageUrl: imageUrl)
            case .failure(let error):
                self?.outputSubject.send(.updateSubmittableState(.editting(true)))
                self?.outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func createGroup(imageUrl: String) {
        guard let name = state.name else { return }
        let req = CreateGroup.Request(
            name: name, englishName: state.englishName, biography: state.biography, since: state.since,
            artworkURL: URL(string: imageUrl),twitterId: state.twitterId, youtubeChannelId: state.youtubeChannelId, hometown: state.hometown)
        createGroupAction.input((request: req, uri: CreateGroup.URI()))
    }
}

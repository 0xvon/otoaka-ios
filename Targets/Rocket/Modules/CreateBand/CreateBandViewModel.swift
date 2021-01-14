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
        case completed
        case editting(Bool)
    }
    
    enum Output {
        case didCreateGroup(Group)
        case updateSubmittableState(PageState)
        case didValidateYoutubeChannelId(Bool)
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
        self.state = State(socialInputs: try! dependencyProvider.masterService.blockingMasterData())
    }
    
    func validateYoutubeChannelId(youtubeChannelId: String?, callback: @escaping ((Bool) -> Void)) {
        guard let youtubeChannelId = youtubeChannelId else { callback(false); return }
        
        let request = Empty()
        var uri = ListChannel.URI()
        uri.channelId = youtubeChannelId
        uri.part = "snippet"
        uri.maxResults = 1
        uri.order = "viewCount"
        dependencyProvider.youTubeDataApiClient.request(ListChannel.self, request: request, uri: uri) { result in
            switch result {
            case .success(_):
                callback(true)
            case .failure(let error):
                print(error)
                callback(false)
            }
        }
    }
    
    func didUpdateInputItems(
        name: String?, englishName: String?, biography: String?,
        since: Date?, youtubeChannelId: String?, twitterId: String?, hometown: String?
    ) {
        state.name = name
        state.englishName = englishName
        state.biography = biography
        state.since = since
        state.twitterId = twitterId
        state.hometown = hometown
        
        let isSubmittable: Bool = (name != nil && englishName != nil)
        outputSubject.send(.updateSubmittableState(.editting(isSubmittable)))
        
        if let youtubeChannelId = youtubeChannelId {
            validateYoutubeChannelId(youtubeChannelId: youtubeChannelId) { [unowned self] isValid in
                state.youtubeChannelId = isValid ? youtubeChannelId : nil
                outputSubject.send(.didValidateYoutubeChannelId(isValid))
            }
        }
    }
    
    func didUpdateArtwork(artwork: UIImage?) {
        self.state.artwork = artwork
    }

    func didRegisterButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        guard let name = state.name else { return }
        guard let englishName = state.englishName else { return }
        self.dependencyProvider.s3Client.uploadImage(image: state.artwork) { [weak self] result in
            switch result {
            case .success(let imageUrl):
                guard let state = self?.state else { return }
                let req = CreateGroup.Request(
                    name: name, englishName: englishName, biography: state.biography, since: state.since,
                    artworkURL: URL(string: imageUrl),twitterId: state.twitterId, youtubeChannelId: state.youtubeChannelId, hometown: state.hometown)
                self?.apiClient.request(CreateGroup.self, request: req) { [weak self] result in
                    self?.updateState(with: result)
                }
            case .failure(let error):
                self?.outputSubject.send(.updateSubmittableState(.completed))
                self?.outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func updateState(with result: Result<Group, Error>) {
        outputSubject.send(.updateSubmittableState(.completed))
        switch result {
        case .success(let group):
            outputSubject.send(.didCreateGroup(group))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}

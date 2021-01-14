//
//  EditGroupViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent
import UIKit

class EditBandViewModel {
    struct State {
        var group: Group
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
        case didEditGroup(Group)
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
        dependencyProvider: LoggedInDependencyProvider, group: Group
    ) {
        self.dependencyProvider = dependencyProvider
        
        self.state = State(group: group, name: group.name, englishName: group.englishName, biography: group.biography, since: group.since, artwork: nil, youtubeChannelId: group.youtubeChannelId, twitterId: group.twitterId, hometown: group.hometown, socialInputs: try! dependencyProvider.masterService.blockingMasterData())
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
        state.youtubeChannelId = youtubeChannelId
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
    
    func didEditButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        if let artwork = self.state.artwork {
            self.dependencyProvider.s3Client.uploadImage(image: artwork) { [weak self] result in
                switch result {
                case .success(let imageUrl):
                    self?.editBand(imageUrl: URL(string: imageUrl))
                case .failure(let error):
                    self?.outputSubject.send(.updateSubmittableState(.completed))
                    self?.outputSubject.send(.reportError(error))
                }
            }
        } else {
            editBand(imageUrl: state.group.artworkURL)
        }
    }
    
    private func editBand(imageUrl: URL?) {
        guard let name = state.name else { return }
        var uri = EditGroup.URI()
        uri.id = self.state.group.id
        let req = EditGroup.Request(
            name: name,
            englishName: self.state.englishName,
            biography: self.state.biography,
            since: self.state.since,
            artworkURL: imageUrl,
            twitterId: self.state.twitterId,
            youtubeChannelId: self.state.youtubeChannelId,
            hometown: self.state.hometown)
        apiClient.request(EditGroup.self, request: req, uri: uri) { [weak self] result in
            self?.updateState(with: result)
        }
    }
    
    private func updateState(with result: Result<Group, Error>) {
        outputSubject.send(.updateSubmittableState(.completed))
        switch result {
        case .success(let group):
            outputSubject.send(.didEditGroup(group))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}

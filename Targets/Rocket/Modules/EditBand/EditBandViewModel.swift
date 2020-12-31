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
        var submittable: Bool
        let socialInputs: SocialInputs
    }
    
    enum Output {
        case didEditGroup(Group)
        case updateSubmittableState(Bool)
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
        
        self.state = State(group: group, name: group.name, englishName: group.englishName, biography: group.biography, since: group.since, artwork: UIImage(url: group.artworkURL?.absoluteString ?? ""), youtubeChannelId: group.youtubeChannelId, twitterId: group.twitterId, hometown: group.hometown, submittable: true, socialInputs: try! dependencyProvider.masterService.blockingMasterData())
    }
    
    func validateYoutubeChannelId(youtubeChannelId: String?, callback: @escaping ((Bool) -> Void)) {
        guard let youtubeChannelId = youtubeChannelId else { callback(false); return }
        let url = URL(string: "https://youtube.com/channel/\(youtubeChannelId)")
        // TODO: call YouTubeData API Async
        callback(url != nil)
    }
    
    func didUpdateInputItems(
        name: String?, englishName: String?, biography: String?,
        since: Date?, artwork: UIImage?, youtubeChannelId: String?, twitterId: String?, hometown: String?
    ) {
        state.name = name
        state.englishName = englishName
        state.biography = biography
        state.since = since
        state.artwork = artwork
        state.youtubeChannelId = youtubeChannelId
        state.twitterId = twitterId
        state.hometown = hometown
        
        validateYoutubeChannelId(youtubeChannelId: youtubeChannelId) { [unowned self] isValid in
            let isSubmittable: Bool = (name != nil && isValid)
            outputSubject.send(.updateSubmittableState(isSubmittable))
        }
    }
    
    func didEditButtonTapped() {
        outputSubject.send(.updateSubmittableState(false))
        guard let name = state.name else { return }
        self.dependencyProvider.s3Client.uploadImage(image: state.artwork) { [unowned self] result in
            switch result {
            case .success(let imageUrl):
                var uri = EditGroup.URI()
                uri.id = self.state.group.id
                print(state)
                let req = EditGroup.Request(
                    name: name,
                    englishName: self.state.englishName,
                    biography: self.state.biography,
                    since: self.state.since,
                    artworkURL: URL(string: imageUrl),
                    twitterId: self.state.twitterId,
                    youtubeChannelId: self.state.youtubeChannelId,
                    hometown: self.state.hometown)
                apiClient.request(EditGroup.self, request: req, uri: uri) { [unowned self] result in
                    updateState(with: result)
                }
            case .failure(let error):
                outputSubject.send(.updateSubmittableState(true))
                outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func updateState(with result: Result<Group, Error>) {
        outputSubject.send(.updateSubmittableState(true))
        switch result {
        case .success(let group):
            outputSubject.send(.didEditGroup(group))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}

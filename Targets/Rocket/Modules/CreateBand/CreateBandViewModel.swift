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
        var submittable: Bool
        let socialInputs: SocialInputs
    }
    
    enum Output {
        case didCreateGroup(Group)
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
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(submittable: false, socialInputs: try! dependencyProvider.masterService.blockingMasterData())
    }
    
    func validateYoutubeChannelId(youtubeChannelId: String?, callback: @escaping ((Bool) -> Void)) {
        guard let youtubeChannelId = youtubeChannelId else { callback(false); return }
        let url = URL(string: "https://youtube.com/channel/\(youtubeChannelId)")
        // TODO: call YouTubeData API Async
        callback(url != nil)
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
        
        validateYoutubeChannelId(youtubeChannelId: youtubeChannelId) { [unowned self] isValid in
            let isSubmittable: Bool = (name != nil && englishName != nil && isValid)
            state.submittable = isSubmittable
            outputSubject.send(.updateSubmittableState(isSubmittable))
        }
    }
    
    func didUpdateArtwork(artwork: UIImage?) {
        self.state.artwork = artwork
    }

    func didRegisterButtonTapped() {
        outputSubject.send(.updateSubmittableState(false))
        guard let name = state.name else { return }
        guard let englishName = state.englishName else { return }
        self.dependencyProvider.s3Client.uploadImage(image: state.artwork) { [unowned self] result in
            switch result {
            case .success(let imageUrl):
                let req = CreateGroup.Request(
                    name: name, englishName: englishName, biography: self.state.biography, since: self.state.since,
                    artworkURL: URL(string: imageUrl),twitterId: self.state.twitterId, youtubeChannelId: self.state.youtubeChannelId, hometown: self.state.hometown)
                apiClient.request(CreateGroup.self, request: req) { [unowned self] result in
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
            outputSubject.send(.didCreateGroup(group))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}

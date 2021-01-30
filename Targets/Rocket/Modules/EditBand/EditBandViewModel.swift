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
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var listChannelAction = Action(ListChannel.self, httpClient: dependencyProvider.youTubeDataApiClient)
    private lazy var editGroupAction = Action(EditGroup.self, httpClient: apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider, group: Group
    ) {
        self.dependencyProvider = dependencyProvider
        
        self.state = State(group: group, name: group.name, englishName: group.englishName, biography: group.biography, since: group.since, artwork: nil, youtubeChannelId: group.youtubeChannelId, twitterId: group.twitterId, hometown: group.hometown, socialInputs: try! dependencyProvider.masterService.blockingMasterData())
        
        let errors = Publishers.MergeMany(
            editGroupAction.errors
        )
        
        Publishers.MergeMany(
            listChannelAction.elements.map { _ in .didValidateYoutubeChannelId(true) }.eraseToAnyPublisher(),
            editGroupAction.elements.map { _ in .updateSubmittableState(.editting(true)) }.eraseToAnyPublisher(),
            editGroupAction.elements.map(Output.didEditGroup).eraseToAnyPublisher(),
            errors.map(Output.reportError).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
        
        listChannelAction.errors
            .sink(receiveValue: { [unowned self] _ in
                state.youtubeChannelId = nil
                outputSubject.send(.didValidateYoutubeChannelId(false))
            })
            .store(in: &cancellables)
    }
    
    func validateYoutubeChannelId(youtubeChannelId: String?) {
        guard let youtubeChannelId = youtubeChannelId else { return }
        
        let request = Empty()
        var uri = ListChannel.URI()
        uri.channelId = youtubeChannelId
        uri.part = "snippet"
        uri.maxResults = 1
        uri.order = "viewCount"
        listChannelAction.input((request: request, uri: uri))
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
        
        let isSubmittable: Bool = (name != nil)
        outputSubject.send(.updateSubmittableState(.editting(isSubmittable)))
        validateYoutubeChannelId(youtubeChannelId: youtubeChannelId)
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
                    self?.editGroup(imageUrl: URL(string: imageUrl))
                case .failure(let error):
                    self?.outputSubject.send(.updateSubmittableState(.editting(true)))
                    self?.outputSubject.send(.reportError(error))
                }
            }
        } else {
            editGroup(imageUrl: state.group.artworkURL)
        }
    }
    
    private func editGroup(imageUrl: URL?) {
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
        editGroupAction.input((request: req, uri: uri))
    }
}

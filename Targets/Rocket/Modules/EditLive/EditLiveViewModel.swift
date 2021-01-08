//
//  EditLiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIKit

class EditLiveViewModel {
    struct State {
        var title: String?
        var livehouse: String?
        var openAt: Date
        var startAt: Date
        var endAt: Date
        var thumbnail: UIImage?
        let socialInputs: SocialInputs
        let live: Live
    }
    
    enum PageState {
        case loading
        case completed
        case editting(Bool)
    }
    
    enum DatePickerType {
        case openAt(Date)
        case startAt(Date)
        case endAt(Date)
    }
    
    enum Output {
        case didEditLive(Live)
        case didInject
        case updateSubmittableState(PageState)
        case didUpdateDatePickers(DatePickerType)
        case reportError(Error)
    }

    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }

    init(
        dependencyProvider: LoggedInDependencyProvider, live: Live
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(title: live.title, livehouse: live.liveHouse, openAt: live.openAt ?? Date(), startAt: live.startAt ?? Date(), endAt: live.endAt ?? Date(), thumbnail: nil, socialInputs: try! dependencyProvider.masterService.blockingMasterData(), live: live)
    }
    
    func viewDidLoad() {
        didUpdateDatePicker(pickerType: .openAt(state.openAt))
        inject()
    }
    
    func inject() {
        outputSubject.send(.didInject)
    }
    
    func didUpdateInputItems(
        title: String?, livehouse: String?
    ) {
        state.title = title
        state.livehouse = livehouse
        
        let isSubmittable: Bool = (title != nil && livehouse != nil)
        outputSubject.send(.updateSubmittableState(.editting(isSubmittable)))
    }
    
    func didUpdateDatePicker(pickerType: DatePickerType) {
        switch pickerType {
        case .openAt(let openAt):
            state.openAt = openAt
            state.startAt = openAt > state.startAt ? openAt : state.startAt
            state.endAt = openAt > state.endAt ? openAt : state.endAt
        case .startAt(let startAt):
            state.startAt = startAt
            state.endAt = startAt > state.endAt ? startAt : state.endAt
        case .endAt(let endAt):
            state.endAt = endAt
        }
        outputSubject.send(.didUpdateDatePickers(pickerType))
    }
    
    func didUpdateArtwork(thumbnail: UIImage?) {
        self.state.thumbnail = thumbnail
    }

    func didEditButtonTapped() {
        outputSubject.send(.updateSubmittableState(.loading))
        if let image = state.thumbnail {
            dependencyProvider.s3Client.uploadImage(image: image) { [unowned self] result in
                switch result {
                case .success(let imageUrl):
                    editLive(imageUrl: URL(string: imageUrl))
                case .failure(let error):
                    outputSubject.send(.updateSubmittableState(.completed))
                    outputSubject.send(.reportError(error))
                }
            }
        } else {
            editLive(imageUrl: state.live.artworkURL)
        }
    }
    
    private func editLive(imageUrl: URL?) {
        var uri = EditLive.URI()
        uri.id = state.live.id
        let req = EditLive.Request(
            title: state.title ?? state.live.title, artworkURL: imageUrl, liveHouse: state.livehouse ?? state.live.liveHouse, openAt: state.openAt, startAt: state.startAt,
            endAt: state.endAt)
        apiClient.request(EditLive.self, request: req, uri: uri) { [unowned self] result in
            updateState(with: result)
        }
    }
    
    private func updateState(with result: Result<Live, Error>) {
        outputSubject.send(.updateSubmittableState(.completed))
        switch result {
        case .success(let live):
            outputSubject.send(.didEditLive(live))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }
}

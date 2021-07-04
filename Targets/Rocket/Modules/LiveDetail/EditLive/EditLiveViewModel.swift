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
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var editLiveAction = Action(EditLive.self, httpClient: self.apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider, live: Live
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(title: live.title, livehouse: live.liveHouse, openAt: live.openAt ?? Date(), startAt: live.startAt ?? Date(), endAt: live.endAt ?? Date(), thumbnail: nil, socialInputs: try! dependencyProvider.masterService.blockingMasterData(), live: live)
        
        editLiveAction.elements
            .map(Output.didEditLive).eraseToAnyPublisher()
            .merge(with: editLiveAction.errors.map(Output.reportError).eraseToAnyPublisher())
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
        
        editLiveAction.elements
            .sink(receiveValue: { [unowned self] _ in
                outputSubject.send(.updateSubmittableState(.editting(true)))
            })
            .store(in: &cancellables)
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
            dependencyProvider.s3Client.uploadImage(image: image) { [weak self] result in
                switch result {
                case .success(let imageUrl):
                    self?.editLive(imageUrl: URL(string: imageUrl))
                case .failure(let error):
                    self?.outputSubject.send(.updateSubmittableState(.editting(true)))
                    self?.outputSubject.send(.reportError(error))
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
        editLiveAction.input((request: req, uri: uri))
    }
}

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
        var date: Date
        var endDate: Date?
        var openAt: Date
        var startAt: Date
        var thumbnail: UIImage?
        let socialInputs: SocialInputs
        let live: Live
    }
    
    let dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY/MM/dd"
        return dateFormatter
    }()
    
    let timeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
        return dateFormatter
    }()
    
    enum PageState {
        case loading
        case editting(Bool)
    }
    
    enum DatePickerType {
        case openAt(Date)
        case startAt(Date)
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
        self.state = State(
            title: live.title,
            livehouse: live.liveHouse,
            date: dateFormatter.date(from: live.date ?? "") ?? Date(),
            openAt: timeFormatter.date(from: live.openAt ?? "") ?? Date(),
            startAt: timeFormatter.date(from: live.startAt ?? "") ?? Date(),
            thumbnail: nil,
            socialInputs: try! dependencyProvider.masterService.blockingMasterData(),
            live: live
        )
        
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
        case .startAt(let startAt):
            state.startAt = startAt
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
        var style: LiveStyleInput;
        switch state.live.style {
        case .oneman(let performer):
            style = .oneman(performer: performer.id)
        case .battle(let performers):
            style = .battle(performers: performers.map { $0.id })
        case .festival(let performers):
            style = .festival(performers: performers.map { $0.id })
        }
        
        let req = EditLive.Request(
            title: state.title ?? state.live.title,
            style: style,
            price: state.live.price,
            artworkURL: imageUrl,
            hostGroupId: state.live.hostGroup.id,
            liveHouse: state.livehouse ?? state.live.liveHouse,
            date: dateFormatter.string(from: state.date),
            endDate: state.endDate.map(dateFormatter.string(from:)),
            openAt: timeFormatter.string(from: state.openAt),
            startAt: timeFormatter.string(from: state.startAt),
            piaEventCode: state.live.piaEventCode,
            piaReleaseUrl: state.live.piaReleaseUrl,
            piaEventUrl: state.live.piaEventUrl
        )
        editLiveAction.input((request: req, uri: uri))
    }
}

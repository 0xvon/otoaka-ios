//
//  CreateLiveViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/23.
//

import Combine
import Endpoint
import Foundation
import InternalDomain
import UIComponent
import UIKit

class CreateLiveViewModel {
    struct State {
        var groupId: Group.ID?
        var memberships: [Group] = []
        var title: String?
        var liveStyle: LiveStyle<Group.ID>?
        var price: Int?
        var livehouse: String?
        var performers: [Group] = []
        var openAt: Date = Date()
        var startAt: Date = Date()
        var endAt: Date = Date()
        var thumbnail: UIImage?
        var submittable: Bool
        let socialInputs: SocialInputs
    }
    
    enum DatePickerType {
        case openAt(Date)
        case startAt(Date)
        case endAt(Date)
    }
    
    enum Output {
        case didCreateLive(Live)
        case updateSubmittableState(Bool)
        case didUpdateDatePickers(DatePickerType)
        case didUpdateLiveStyle(LiveStyle<Group.ID>?)
        case didUpdatePerformers([Group])
        case didGetMemberships([Group])
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
    
    func viewDidLoad() {
        getMemberships()
        didUpdateDatePicker(pickerType: .openAt(Date()))
    }
    
    func didUpdateInputItems(
        title: String?, hostGroup: Group.ID?, liveStyle: String?,
        price: Int?, livehouse: String?
    ) {
        state.title = title
        state.groupId = hostGroup
        state.price = price
        state.livehouse = livehouse
        
        let liveStyle: LiveStyle<Group.ID>? = {
            if let hostGroup = hostGroup {
                switch liveStyle {
                case "ワンマン":
                    return .oneman(performer: hostGroup)
                case "対バン":
                    return .battle(performers: state.performers.map { $0.id })
                case "フェス":
                    return .festival(performers: state.performers.map { $0.id })
                default:
                    return nil
                }
            } else { return nil }
        }()
        state.liveStyle = liveStyle
        
        
        let isSubmittable: Bool = (title != nil && hostGroup != nil && liveStyle != nil && price != nil && livehouse != nil)
        state.submittable = isSubmittable
        outputSubject.send(.updateSubmittableState(isSubmittable))
        outputSubject.send(.didUpdateLiveStyle(liveStyle))
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
    
    func didAddPerformer(performer: Group) {
        let performers = self.state.performers + [performer]
        self.state.performers = performers
        outputSubject.send(.didUpdatePerformers(performers))
    }
    
    func didRemovePerformer(performer: Group) {
        let performers = self.state.performers.filter { $0.id != performer.id }
        self.state.performers = performers
        outputSubject.send(.didUpdatePerformers(performers))
    }
    
    func didUpdateArtwork(thumbnail: UIImage?) {
        self.state.thumbnail = thumbnail
    }
    
    func didRegisterButtonTapped() {
        outputSubject.send(.updateSubmittableState(false))
        guard let title = state.title else { return }
        guard let groupId = state.groupId else { return }
        guard let liveStyle = state.liveStyle else { return }
        guard let price = state.price else { return }
        guard let livehouse = state.livehouse else { return }
        self.dependencyProvider.s3Client.uploadImage(image: state.thumbnail) { [unowned self] result in
            switch result {
            case .success(let imageUrl):
                let req = CreateLive.Request(
                    title: title, style: liveStyle, price: price, artworkURL: URL(string: imageUrl),
                    hostGroupId: groupId, liveHouse: livehouse,
                    openAt: state.openAt, startAt: state.startAt, endAt: state.endAt)
                apiClient.request(CreateLive.self, request: req) { [unowned self] result in
                    updateState(with: result)
                }
            case .failure(let error):
                outputSubject.send(.updateSubmittableState(true))
                outputSubject.send(.reportError(error))
            }
        }
    }
    
    private func updateState(with result: Result<Live, Error>) {
        outputSubject.send(.updateSubmittableState(true))
        switch result {
        case .success(let live):
            outputSubject.send(.didCreateLive(live))
        case .failure(let error):
            outputSubject.send(.reportError(error))
        }
    }

    func getMemberships() {
        let request = Empty()
        var uri = Endpoint.GetMemberships.URI()
        uri.artistId = self.dependencyProvider.user.id
        apiClient.request(GetMemberships.self, request: request, uri: uri) { [unowned self] result in
            switch result {
            case .success(let res):
                state.memberships = res
                outputSubject.send(.didGetMemberships(res))
            case .failure(let error):
                outputSubject.send(.reportError(error))
            }
        }
    }
}

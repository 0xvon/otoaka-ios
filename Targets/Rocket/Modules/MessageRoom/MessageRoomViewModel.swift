//
//  MessageRoomViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/06/20.
//

import Combine
import Endpoint
import Foundation
import UIKit

class MessageRoomViewModel {
    typealias Input = MessageRoom
    
    enum Output {
        case userTapped
        case didGetUserDetail(UserDetail)
        case sentMessage
        case openMessage
        case reportError(Error)
    }
    
    struct State {
        var room: MessageRoom
//        var userDetail: UserDetail? = nil
        var messages: [Message] = []
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var pagination = PaginationRequest<OpenRoomMessages>(apiClient: apiClient, uri: {
        var uri = OpenRoomMessages.URI()
        uri.roomId = state.room.id
        return uri
    }())
    private lazy var sendMessageAction = Action(SendMessage.self, httpClient: apiClient)
    private lazy var getUserDetailAction = Action(GetUserDetail.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider, input: Input
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State(room: input)
        
        subscribe()
        
        sendMessageAction.elements.map { _ in .sentMessage }.eraseToAnyPublisher()
            .merge(with: sendMessageAction.errors.map(Output.reportError)).eraseToAnyPublisher()
            .merge(with: getUserDetailAction.elements.map(Output.didGetUserDetail).eraseToAnyPublisher())
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
            
    }
    
    private func subscribe() {
        pagination.subscribe { [weak self] in self?.updateState(with: $0) }
    }
    
    private func updateState(with result: PaginationEvent<Page<Message>>) {
        switch result {
        case .initial(let res):
            state.messages = res.items.reversed()
            outputSubject.send(.openMessage)
        case .next(let res):
            state.messages = res.items.reversed() + state.messages
            outputSubject.send(.openMessage)
        case .error(let err):
            outputSubject.send(.reportError(err))
        }
    }
    
    func refresh() {
        pagination.refresh()
        getUserDetail()
    }
    
    func next() {
        pagination.next()
    }
    
    func getUserDetail() {
        var uri = GetUserDetail.URI()
        guard let partner = ([state.room.owner] + state.room.members).filter({ $0.id != dependencyProvider.user.id }).first else { return }
        uri.userId = partner.id
        getUserDetailAction.input((request: Empty(), uri: uri))
        
    }
    
    func sendMessage(
        text: String?, image: UIImage?
    ) {
        let uri = SendMessage.URI()
        if let image = image {
            dependencyProvider.s3Client.uploadImage(image: image) { [weak self] result in
                switch result {
                case .success(let imageUrl):
                    let request = SendMessage.Request(roomId: self!.state.room.id, text: text, imageUrl: imageUrl)
                    self?.sendMessageAction.input((request: request, uri: uri))
                case .failure(let err):
                    self?.outputSubject.send(.reportError(err))
                }
            }
        } else {
            let request = SendMessage.Request(roomId: state.room.id, text: text, imageUrl: nil)
            sendMessageAction.input((request: request, uri: uri))
        }
    }
}

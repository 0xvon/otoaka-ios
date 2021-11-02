//
//  OpenMessageViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/11/02.
//

import UIKit
import Endpoint
import Combine

class OpenMessageRoomViewModel {
    typealias Input = Void
    enum Output {
        case didCreateMessageRoom(MessageRoom)
        case reportError(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private lazy var createMessageRoomAction = Action(CreateMessageRoom.self, httpClient: apiClient)
    
    private let outputSubject = PassthroughSubject<Output, Never>()
    var cancellables: Set<AnyCancellable> = []
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        
        createMessageRoomAction.elements.map(Output.didCreateMessageRoom).eraseToAnyPublisher()
            .merge(with: createMessageRoomAction.errors.map(Output.reportError)).eraseToAnyPublisher()
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }
    
    func createMessageRoom(partner: User) {
        let request = CreateMessageRoom.Request(members: [partner.id], name: partner.name)
        let uri = CreateMessageRoom.URI()
        createMessageRoomAction.input((request: request, uri: uri))
    }
}

//
//  MessageListViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/05/10.
//

import Foundation
import Combine
import Endpoint

final class MessageListViewModel {
    enum Output {
        case reloadData
        case deletedRoom
        case isRefreshing(Bool)
        case reportError(Error)
    }
    
    struct State {
        var messageRooms: [MessageRoom] = []
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    private var cancellables: [AnyCancellable] = []
    private lazy var pagination = PaginationRequest<GetRooms>(apiClient: apiClient)
    private lazy var deleteRoomRequest = Action(DeleteMessageRoom.self, httpClient: apiClient)
    
    init(dependencyProvider: LoggedInDependencyProvider) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        subscribe()
        
        deleteRoomRequest.elements
            .map { _ in .deletedRoom }.eraseToAnyPublisher()
            .merge(with: deleteRoomRequest.errors.map(Output.reportError)).eraseToAnyPublisher()
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }
    
    private func subscribe() {
        pagination.subscribe { [weak self] in self?.updateState(with: $0) }
    }
    
    private func updateState(with result: PaginationEvent<Page<MessageRoom>>) {
        outputSubject.send(.isRefreshing(false))
        switch result {
        case .initial(let res):
            state.messageRooms = res.items
            self.outputSubject.send(.reloadData)
        case .next(let res):
            state.messageRooms += res.items
            self.outputSubject.send(.reloadData)
        case .error(let err):
            self.outputSubject.send(.reportError(err))
        }
    }
    
    func refresh() {
        pagination.refresh()
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.messageRooms.count else { return }
        pagination.next()
    }
    
    func deleteRoom(at index: Int) {
        let room = state.messageRooms[index]
        let request = DeleteMessageRoom.Request(roomId: room.id)
        deleteRoomRequest.input((request: request, uri: DeleteMessageRoom.URI()))
    }
}

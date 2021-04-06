//
//  UserNotificationViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/04/06.
//

import UIKit
import Endpoint
import Combine

class UserNotificationViewModel {
    typealias Input = Void
    
    struct State {
        var notifications: [UserNotification] = []
    }
    
    enum Output {
        case reloadData
        case read
        case selectCell(UserNotification)
        case didPushToPlayTrack(PlayTrackViewController.Input)
        case error(Error)
    }
    
    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    var cancellables: Set<AnyCancellable> = []

    private(set) var state: State
    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    
    private lazy var pagination = PaginationRequest<GetNotifications>(apiClient: self.apiClient)
    private lazy var readAction = Action(ReadNotification.self, httpClient: apiClient)
    private lazy var getFeedAction = Action(GetUserFeed.self, httpClient: apiClient)
    
    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        subscribe()
        
        let errors = Publishers.MergeMany(
            readAction.errors,
            getFeedAction.errors
        )
        
        Publishers.MergeMany(
            readAction.elements.map { _ in .read } .eraseToAnyPublisher(),
            getFeedAction.elements.map { feed in .didPushToPlayTrack(.userFeed(feed)) }.eraseToAnyPublisher(),
            errors.map(Output.error).eraseToAnyPublisher()
        )
        .sink(receiveValue: outputSubject.send)
        .store(in: &cancellables)
    }
    
    func subscribe() {
        pagination.subscribe { [weak self] in
            self?.updateState(with: $0)
        }
    }
    
    private func updateState(with result: PaginationEvent<Page<UserNotification>>) {
        switch result {
        case .initial(let res):
            self.state.notifications = res.items
            self.outputSubject.send(.reloadData)
        case .next(let res):
            self.state.notifications += res.items
            self.outputSubject.send(.reloadData)
        case .error(let err):
            self.outputSubject.send(.error(err))
        }
    }
    
    func refresh() {
        pagination.refresh()
    }
    
    func willDisplay(rowAt indexPath: IndexPath) {
        guard indexPath.row + 25 > state.notifications.count else { return }
        pagination.next()
    }
    
    func read(cellIndex: Int) {
        let notification = state.notifications[cellIndex]
        if !notification.isRead {
            let request = ReadNotification.Request(notificationId: notification.id)
            let uri = ReadNotification.URI()
            readAction.input((request: request, uri: uri))
        }
        outputSubject.send(.selectCell(notification))
        state.notifications[cellIndex].isRead = true
        outputSubject.send(.reloadData)
    }
    
    func getUserFeed(feedId: UserFeed.ID) {
        let request = Empty()
        var uri = GetUserFeed.URI()
        uri.feedId = feedId
        getFeedAction.input((request: request, uri: uri))
    }
}


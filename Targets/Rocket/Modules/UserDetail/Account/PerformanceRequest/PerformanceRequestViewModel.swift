//
//  PerformanceRequestViewModel.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/11/25.
//

import Endpoint
import UIKit
import Combine

class PerformanceRequestViewModel {
    struct State {
        var requests: [PerformanceRequest] = []
    }
    
    enum Output {
        case reloadTableView
        case didReplyRequest
        case reportError(Error)
    }

    let dependencyProvider: LoggedInDependencyProvider
    var apiClient: APIClient { dependencyProvider.apiClient }
    private(set) var state: State

    private let outputSubject = PassthroughSubject<Output, Never>()
    var output: AnyPublisher<Output, Never> { outputSubject.eraseToAnyPublisher() }
    var cancellables: Set<AnyCancellable> = []
    
    private lazy var getPerformanceRequestsPaginationRequest: PaginationRequest<GetPerformanceRequests> = PaginationRequest<GetPerformanceRequests>(apiClient: self.apiClient)
    private lazy var replyPerformanceRequestAction = Action(ReplyPerformanceRequest.self, httpClient: self.apiClient)

    init(
        dependencyProvider: LoggedInDependencyProvider
    ) {
        self.dependencyProvider = dependencyProvider
        self.state = State()
        
        getPerformanceRequestsPaginationRequest.subscribe { [unowned self] result in
            switch result {
            case .initial(let res):
                state.requests = res.items
                outputSubject.send(.reloadTableView)
            case .next(let res):
                state.requests += res.items
                outputSubject.send(.reloadTableView)
            case .error(let err):
                outputSubject.send(.reportError(err))
            }
        }
        
        replyPerformanceRequestAction.elements
            .map { _ in .didReplyRequest }.eraseToAnyPublisher()
            .merge(with: replyPerformanceRequestAction.errors.map(Output.reportError).eraseToAnyPublisher())
            .sink(receiveValue: outputSubject.send)
            .store(in: &cancellables)
    }

    func getRequests() {
        getPerformanceRequestsPaginationRequest.next()
    }
    
    func refreshRequests() {
        getPerformanceRequestsPaginationRequest.refresh()
    }

    func replyRequest(requestId: PerformanceRequest.ID, accept: Bool, cellIndex: Int) {
        self.state.requests.remove(at: cellIndex)
        let req = ReplyPerformanceRequest.Request(
            requestId: requestId, reply: accept ? .accept : .deny)
        replyPerformanceRequestAction.input((request: req, uri: ReplyPerformanceRequest.URI()))
    }
}

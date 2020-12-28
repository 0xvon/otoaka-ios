//
//  Pagenation.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/12.
//

import Endpoint

class PaginationRequest<E: EndpointProtocol> where E.URI: PaginationQuery, E.Request == Empty {
    private var uri: E.URI
    private var state: State
    private var apiClient: APIClient
    private var subscribers: [(Event) -> Void] = []
    
    enum State {
        case isInitial
        case isLoading
        case isFinished
    }
    
    enum Event {
        case initial(E.Response)
        case next(E.Response)
        case error(Error)
    }
    
    init(apiClient: APIClient, uri: E.URI = E.URI()) {
        self.apiClient = apiClient
        self.uri = uri
        self.state = .isInitial
        
        self.initialize()
    }
    
    func subscribe(_ subscriber: @escaping (Event) -> Void) {
        subscribers.append(subscriber)
    }
    
    private func notify(_ response: Event) {
        subscribers.forEach { $0(response) }
    }
    
    private func initialize() {
        
        self.uri.page = 1
        self.uri.per = per
    }
    
    @available(*, deprecated)
    func next(isNext: Bool) {
        execute(isNext: isNext)
    }

    func refresh() {
        execute(isNext: false)
    }
    func next() {
        execute(isNext: false)
    }

    private func execute(isNext: Bool) {
        if !isNext && self.state != .isLoading {
            self.state = .isInitial
            initialize()
        }
        
        switch self.state {
        case .isInitial:
            self.state = .isLoading
            apiClient.request(E.self, request: Empty(), uri: self.uri) { result in
                self.state = .isFinished
                switch result {
                case .success(let res):
                    self.notify(.initial(res))
                case .failure(let err):
                    self.notify(.error(err))
                }
                
            }
        case .isFinished:
            self.uri.page += 1
            self.state = .isLoading
            apiClient.request(E.self, request: Empty(), uri: self.uri) { result in
                self.state = .isFinished
                switch result {
                case .success(let res):
                    self.notify(.next(res))
                case .failure(let err):
                    self.notify(.error(err))
                }
            }
        default:
            break
        }
    }
}

//
//  Pagenation.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/12.
//

import Endpoint

class PaginationRequest<E: EndpointProtocol> {
    private var uri: PaginationQuery
    private var event: Event
    private var apiClient: APIClient
    private var subscribers: [(Result<E.Response, Error>) -> Void] = []
    
    enum Event {
        case isInitial
        case isLoading
        case isFinished
    }
    
    init(apiClient: APIClient) {
        self.apiClient = apiClient
        self.uri = E.URI() as! PaginationQuery
        self.event = .isInitial
        
        self.initialize()
    }
    
    func subscribe(_ subscriber: @escaping (Result<E.Response, Error>) -> Void) {
        subscribers.append(subscriber)
    }
    
    func notify(_ response: Result<E.Response, Error>) {
        subscribers.forEach { $0(response) }
    }
    
    private func initialize() {
        
        self.uri.page = 1
        self.uri.per = per
    }
    
    func next(isNext: Bool = true) {
        if !isNext && self.event != .isLoading {
            self.event = .isInitial
            initialize()
        }
        
        switch self.event {
        case .isInitial:
            self.event = .isLoading
            apiClient.request(E.self, request: Empty() as! E.Request, uri: self.uri as! E.URI) { result in
                self.event = .isFinished
                self.notify(result)
            }
        case .isFinished:
            self.uri.per += 1
            self.event = .isLoading
            apiClient.request(E.self, request: Empty() as! E.Request, uri: self.uri as! E.URI) { result in
                self.event = .isFinished
                self.notify(result)
            }
        default:
            break
        }
    }
}

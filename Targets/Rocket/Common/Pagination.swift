//
//  Pagenation.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2020/12/12.
//

import Endpoint

enum PaginationEvent<Response> {
    case initial(Response)
    case next(Response)
    case error(Error)
}

protocol PageResponse {
    var metadata: PageMetadata { get }
}

extension Page: PageResponse {}

class PaginationRequest<E: EndpointProtocol> where E.URI: PaginationQuery, E.Request == Empty,
                                                   E.Response: PageResponse {
    private var uri: E.URI
    private var apiClient: APIClient
    private var subscribers: [(Event) -> Void] = []
    
    private(set) var isInitial = true
    private(set) var isLoading = false
    private(set) var isFinished = false
    
    typealias Event = PaginationEvent<E.Response>
    
    init(apiClient: APIClient, uri: E.URI = E.URI()) {
        self.apiClient = apiClient
        self.uri = uri
        
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

    func refresh() {
        self.initialize()
        isInitial = true
        isFinished = false
        next()
    }

    func next() {
        guard !isLoading && !isFinished else {
            return
        }
        isLoading = true
        apiClient.request(E.self, uri: uri) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let response):
                if self.isInitial {
                    self.isInitial = false
                    self.notify(.initial(response))
                } else {
                    self.notify(.next(response))
                }
                self.isLoading = false
                let metadata = response.metadata
                guard (metadata.page + 1) * metadata.per < metadata.total else {
                    self.isFinished = true
                    return
                }
                self.uri.page = metadata.page + 1
            case .failure(let error):
                self.notify(.error(error))
            }
        }
    }
}

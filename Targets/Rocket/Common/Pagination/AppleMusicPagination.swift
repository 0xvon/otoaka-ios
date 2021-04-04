//
//  AppleMusicPagination.swift
//  Rocket
//
//  Created by Masato TSUTSUMI on 2021/03/24.
//

import Endpoint
import InternalDomain
import Combine

protocol AppleMusicPageResponse {
    associatedtype Item: Codable
    var meta: Meta { get }
    var results: Results<Item> { get }
}

enum AppleMusicPaginationEvent<Response> {
    case initial(Response)
    case next(Response)
    case error(Error)
}

extension AppleMusicPage: AppleMusicPageResponse {}

class AppleMusicPaginationRequest<E: EndpointProtocol> where E.URI: AppleMusicPaginationQuery, E.Request == Endpoint.Empty, E.Response: AppleMusicPageResponse {
    private var uri: E.URI
    private var apiClient: APIClient
    private lazy var requestAction = Action(E.self, httpClient: self.apiClient)
    private var subscribers: [(Event) -> Void] = []
    private var cancellables: Set<AnyCancellable> = []
    
    fileprivate struct State {
        var isInitial = true
        var isLoading = false
        var isFinished = false
    }

    fileprivate let state = CurrentValueSubject<State, Never>(State())

    typealias Event = AppleMusicPaginationEvent<E.Response>
    
    init(apiClient: APIClient, uri: E.URI = E.URI()) {
        self.apiClient = apiClient
        self.uri = uri
        
        self.initialize()
        
        requestAction.elements
            .map { self.state.value.isInitial ? .initial($0) : .next($0) }.eraseToAnyPublisher()
            .merge(with: requestAction.errors.map { .error($0) }).eraseToAnyPublisher()
            .sink(receiveValue: notify)
            .store(in: &cancellables)
        
        requestAction.elements
            .sink(receiveValue: { [unowned self] response in
                state.value.isLoading = false
                guard per == response.results.songs?.data.count else {
                    self.state.value.isFinished = true
                    return
                }
                self.uri.offset += per
            })
            .store(in: &cancellables)
    }
    
    func subscribe(_ subscriber: @escaping (Event) -> Void) {
        subscribers.append(subscriber)
    }
    
    private func notify(_ response: Event) {
        state.value.isInitial = false
        subscribers.forEach { $0(response) }
    }
    
    private func initialize() {
        self.uri.offset = 1
        self.uri.limit = per
    }

    func refresh() {
        self.initialize()
        state.value.isInitial = true
        state.value.isFinished = false
        next()
    }

    func next() {
        guard !state.value.isLoading && !state.value.isFinished else {
            return
        }
        state.value.isLoading = true
        requestAction.input((request: Empty(), uri: uri))
    }
}

import Combine
import Foundation

extension AppleMusicPaginationRequest {
    private final class ItemsInner<Downstream: Subscriber>: Combine.Subscription where
    Downstream.Input == [E.Response.Item],
        Downstream.Failure == Never
    {
        private var downstream: Downstream?
        private let pagination: AppleMusicPaginationRequest
        private var currentDemand: Subscribers.Demand = .none
        
        init(downstream: Downstream, pagination: AppleMusicPaginationRequest) {
            self.downstream = downstream
            self.pagination = pagination
            
            var items = [E.Response.Item]()
            pagination.subscribe { [weak self] event in
                guard let self = self else { return }
                guard self.currentDemand > 0 else { return }
                switch event {
                case .initial(let response):
                    items = response.results.songs?.data ?? []
                    self.currentDemand += self.downstream?.receive(items) ?? .none
                    self.currentDemand -= 1
                case .next(let response):
                    items += response.results.songs?.data ?? []
                    self.currentDemand += self.downstream?.receive(items) ?? .none
                    self.currentDemand -= 1
                case .error: break
                }
            }
        }

        func request(_ demand: Subscribers.Demand) {
            currentDemand += demand
        }

        func cancel() {
            downstream = nil
        }
    }

    struct ItemsPublisher: Combine.Publisher {
        typealias Output = [E.Response.Item]
        typealias Failure = Never

        let pagination: AppleMusicPaginationRequest
        func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subscriber.receive(subscription: ItemsInner(downstream: subscriber, pagination: pagination))
        }
    }
    func items() -> ItemsPublisher {
        return ItemsPublisher(pagination: self)
    }

    private final class ErrorsInner<Downstream: Subscriber>: Combine.Subscription where
        Downstream.Input == Error,
        Downstream.Failure == Never
    {
        private var downstream: Downstream?
        private let pagination: AppleMusicPaginationRequest
        private var currentDemand: Subscribers.Demand = .none

        init(downstream: Downstream, pagination: AppleMusicPaginationRequest) {
            self.downstream = downstream
            self.pagination = pagination

            pagination.subscribe { [weak self] event in
                guard let self = self else { return }
                guard self.currentDemand > 0 else { return }
                switch event {
                case .initial, .next: break
                case .error(let error):
                    self.currentDemand += self.downstream?.receive(error) ?? .none
                    self.currentDemand -= 1
                }
            }
        }

        func request(_ demand: Subscribers.Demand) {
            currentDemand += demand
        }

        func cancel() {
            downstream = nil
        }
    }

    struct ErrorsPublisher: Combine.Publisher {
        typealias Output = Error
        typealias Failure = Never

        let pagination: AppleMusicPaginationRequest
        func receive<S>(subscriber: S) where S : Subscriber, Self.Failure == S.Failure, Self.Output == S.Input {
            subscriber.receive(subscription: ErrorsInner(downstream: subscriber, pagination: pagination))
        }
    }

    func errors() -> ErrorsPublisher {
        return ErrorsPublisher(pagination: self)
    }

    var isRefreshing: AnyPublisher<Bool, Never> {
        state.map { $0.isLoading && $0.isInitial }.eraseToAnyPublisher()
    }
}
